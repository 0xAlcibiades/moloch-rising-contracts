// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

import "./Base64.sol";
import "./Loot.sol";
import "solmate/tokens/ERC721.sol";

contract Avatar is ERC721, ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    // TODO(Later, these characters can be deposited for a v1 character)
    struct AvatarSheet {
        string name;
        // Experience counter
        uint256 experience;
        // Links to the loot NFT
        uint256 weapon;
        uint256 armor;
        uint256 implant;
    }

    address public loot;

    uint256 _next_id = 0;

    // Mapping to get stats of
    mapping(uint256 => AvatarSheet) public sheet;

    constructor(address _loot) ERC721("Moloch Rising Avatar", "MRA") {
        loot = _loot;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /* solhint-disable quotes */
    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(id < _next_id, "Avatar not yet minted");
        AvatarSheet memory avatarSheet = sheet[id];
        string memory json = Base64.encode(
            bytes(
                string(abi.encodePacked('{"name": "', avatarSheet.name, '"}'))
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /* solhint-enable quotes */

    function mint(address to, string memory newAvatarName) public virtual {
        // TODO(Does the character need that VRF seed?)

        // Get the next token id
        uint256 tokenId = _next_id;

        // Set Avatar data
        AvatarSheet storage avatarSheet = sheet[tokenId];
        avatarSheet.name = newAvatarName;

        // Increment ID
        _next_id += 1;

        // TODO(Charge mint cost here?)

        // Mint the NFT
        _safeMint(to, tokenId);
    }

    // TODO(Equipment/loot system)

    // Will equip or re-equip a loot item to an avatar slot
    function equip(uint256 lootId, uint256 avatarId) public {
        require(lootId != 0, "Can't equip default gear");

        // Get info about loot item
        Loot iLoot = Loot(loot);

        // Equipper must be the owner of the item and the avatar
        require(msg.sender == iLoot.ownerOf(lootId), "Must own item to equip.");
        require(
            msg.sender == this.ownerOf(avatarId),
            "Must own avatar to equip."
        );

        // Copy loot info to local memory
        LootInfo memory info = iLoot.lootInfo(lootId);

        uint256 unequipped = 0;
        if (info.slot == Slot.Weapon) {
            unequipped = sheet[avatarId].weapon;
            sheet[avatarId].weapon = lootId;
        } else if (info.slot == Slot.Armor) {
            unequipped = sheet[avatarId].armor;
            sheet[avatarId].armor = lootId;
        } else if (info.slot == Slot.Implant) {
            unequipped = sheet[avatarId].implant;
            sheet[avatarId].implant = lootId;
        }

        // Transfer equipped item from sender to avatar
        iLoot.safeTransferFrom(msg.sender, address(this), lootId);

        // If the character already had equipment
        if (unequipped != 0) {
            // Send the unequipped item to the sender
            iLoot.safeTransferFrom(address(this), msg.sender, unequipped);
        }
    }

    function unequip(uint256 lootId, uint256 avatarId) public {
        require(lootId != 0, "Can't unequip default gear");
        require(
            msg.sender == this.ownerOf(avatarId),
            "Must own avatar to unequip."
        );

        // Get info about loot item
        Loot iLoot = Loot(loot);

        // Copy loot info to local memory
        LootInfo memory info = iLoot.lootInfo(lootId);

        uint256 unequipped = 0;
        if (info.slot == Slot.Weapon) {
            unequipped = sheet[avatarId].weapon;
            require(unequipped != 0, "Item not equipped");
            sheet[avatarId].weapon = 0;
        } else if (info.slot == Slot.Armor) {
            unequipped = sheet[avatarId].armor;
            require(unequipped != 0, "Item not equipped");
            sheet[avatarId].armor = 0;
        } else if (info.slot == Slot.Implant) {
            unequipped = sheet[avatarId].implant;
            require(unequipped != 0, "Item not equipped");
            sheet[avatarId].implant = 0;
        }

        // If the character already had equipment
        if (unequipped != 0) {
            // Send the unequipped item to the sender
            iLoot.safeTransferFrom(address(this), msg.sender, unequipped);
        }
    }
}
