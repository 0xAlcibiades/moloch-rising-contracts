// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

import "./Base64.sol";
import "solmate/tokens/ERC721.sol";
import "./Loot.sol";

contract Avatar is ERC721, ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    // TODO(Figure out an elegant way to combine these)
    struct AvatarDetails {
        uint64 hp;
        uint64 dp;
        uint64 ap;
        string armor;
        string weapon;
        string implant;
    }

    struct AvatarSheet {
        string name;
        // Experience counter
        uint64 experience;
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

    // TODO(Factor out to library)
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
    function contractURI() public view returns (string memory) {
        // TODO(add multisig here in fee_recipient)
        // TODO(update image to correct one in arweave)
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Moloch Rises Avatars", "description:": "Avatars for playing the Moloch Rises roguelite", "seller_fee_basis_points": ',
                        toString(250),
                        ', "external_link": "https://molochrises.com/", "image": "ar://rfE4aIDBs-O_rX-WgkA3ShQoop5thwHESqfJs8C4OIY", "fee_recipient": "0x36273803306a3c22bc848f8db761e974697ece0d"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // TODO(Replace character image)
        require(id < _next_id, "Avatar not yet minted");
        AvatarSheet memory avatarSheet = sheet[id];
        AvatarDetails memory avatarDetails;

        // Base details
        avatarDetails.hp = 5;
        avatarDetails.ap = 1;
        avatarDetails.dp = 1;
        avatarDetails.armor = "Worn Lab Coat";
        avatarDetails.weapon = "Used Plasma Cutter";
        avatarDetails.implant = "No Implant";

        // Account for experience
        if (avatarSheet.experience >= 100) {
            uint64 buff = avatarSheet.experience / 100;
            avatarDetails.hp += buff;
            avatarDetails.ap += buff;
            avatarDetails.dp += buff;
        }

        // Get Item info

        Loot iLoot = Loot(address(loot));

        if (avatarSheet.armor > 0) {
            avatarDetails.armor = iLoot.tokenName(avatarSheet.armor);
            avatarDetails.dp += uint64(iLoot.lootInfo(avatarSheet.armor).grade);
        }
        if (avatarSheet.weapon > 0) {
            avatarDetails.weapon = iLoot.tokenName(avatarSheet.weapon);
            avatarDetails.ap += uint64(
                iLoot.lootInfo(avatarSheet.weapon).grade
            );
        }
        if (avatarSheet.implant > 0) {
            avatarDetails.implant = iLoot.tokenName(avatarSheet.implant);
            avatarDetails.hp += uint64(
                iLoot.lootInfo(avatarSheet.implant).grade
            );
        }

        // Construct JSON

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        avatarSheet.name,
                        '", "description": "An avatar ready to fight moloch", "image": "ar://rfE4aIDBs-O_rX-WgkA3ShQoop5thwHESqfJs8C4OIY", "attributes": [{"trait_type": "HP", "value": "',
                        toString(avatarDetails.hp),
                        '"}, {"trait_type": "AP", "value": ',
                        toString(avatarDetails.ap),
                        ')}, {"trait_type": "AP", "value": ',
                        toString(avatarDetails.dp),
                        ')},{"trait_type": "Armor", "value": "',
                        avatarDetails.armor,
                        '")}, {"trait_type": "Weapon", "value": "',
                        avatarDetails.weapon,
                        '")}, {"trait_type": "Implant", "value": "',
                        avatarDetails.implant,
                        '")}, {"trait_type": "Experience", "value": ',
                        toString(avatarSheet.experience),
                        ")}]}"
                    )
                )
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
