// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.10;

import "./Base64.sol";
import "solmate/tokens/ERC721.sol";
import "./Loot.sol";
import "solmate/auth/authorities/MultiRolesAuthority.sol";
import "chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Avatar is
    MultiRolesAuthority,
    ERC721,
    ERC721TokenReceiver,
    VRFConsumerBase
{
    address public immutable feeRecipient =
        0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5;

    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(bytes32 => uint256) private _request_map;

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
        bool seeded;
        // Experience counter
        uint64 experience;
        string name;
        // Links to the loot NFT
        uint256 weapon;
        uint256 armor;
        uint256 implant;
        uint256 seed;
    }

    address public loot;
    mapping(address => bool) boards;

    uint256 _next_id = 0;

    // Mapping to get stats of
    mapping(uint256 => AvatarSheet) public sheet;

    // TODO(In an ideal world, the integrated contract addresses would all be precomputed using CREATE3 and not editable)
    constructor(
        address VrfCoordinator,
        address linkToken,
        bytes32 VrfkeyHash,
        uint256 VrfFee
    )
        VRFConsumerBase(VrfCoordinator, linkToken)
        MultiRolesAuthority(msg.sender, Authority(address(0)))
        ERC721("Moloch Rises Avatar", "MRA")
    {
        keyHash = VrfkeyHash;
        fee = VrfFee;
        setRoleCapability(0, 0x87d0040c, true);
        setRoleCapability(0, 0x100af824, true);
        setRoleCapability(0, 0x2affe684, true);
    }

    function updateLoot(address lootContract) public requiresAuth {
        loot = lootContract;
    }

    function addBoard(address boardContract) public requiresAuth {
        boards[boardContract] = true;
    }

    function removeBoard(address boardContract) public requiresAuth {
        boards[boardContract] = false;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        revert("Incorrect function paid");
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        revert("Incorrect function paid");
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

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        // Get tokenId from pending request
        uint256 tokenId = _request_map[requestId];
        sheet[tokenId].seed = randomness;
        sheet[tokenId].seeded = true;
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
                        ', "external_link": "https://molochrises.com/", "image": "ipfs://bafkreihlv2vnrwoirui6ox2rxwavk7ufpuukh5q2iyn37ofiiemv67kzwa", "fee_recipient": "0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5"}'
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
        // TODO(There are almost certainly gas optimizations to be had here)
        require(id < _next_id, "Avatar not yet minted");
        AvatarSheet memory avatarSheet = sheet[id];
        AvatarDetails memory avatarDetails = AvatarDetails(
            5,
            1,
            1,
            "Worn Lab Coat",
            "Used Plasma Cutter",
            "No Implant"
        );

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

        string memory encoded;
        {
            // Construct JSON
            bytes memory encoded1;
            {
                encoded1 = abi.encodePacked(
                    '{"name": "',
                    avatarSheet.name,
                    '", "description": "An avatar ready to fight moloch.", "image": "ipfs://bafkreib4ftqeobfmdy7kvurixv55m7nqtvwj3o2hw3clsyo3hjpxwo3sda", "attributes": [{"trait_type": "HP", "value": ',
                    toString(avatarDetails.hp),
                    '}, {"trait_type": "AP", "value": ',
                    toString(avatarDetails.ap),
                    "}, "
                );
            }
            bytes memory encoded2;
            {
                encoded2 = abi.encodePacked(
                    '{"trait_type": "DP", "value": ',
                    toString(avatarDetails.dp),
                    '},{"trait_type": "Armor", "value": "',
                    avatarDetails.armor,
                    '"}, {"trait_type": "Weapon", "value": "',
                    avatarDetails.weapon,
                    '"}, {"trait_type": "Implant", "value": "',
                    avatarDetails.implant,
                    '"}, {"trait_type": "Experience", "value": ',
                    toString(avatarSheet.experience),
                    "}]}"
                );
            }

            encoded = string(abi.encodePacked(encoded1, encoded2));
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(encoded))
                )
            );
    }

    /* solhint-enable quotes */

    function mint(address to, string memory newAvatarName)
        public
        payable
        virtual
    {
        // TODO(change back to 5 matic)
        require(msg.value == 0.001 ether, "Minting requires 5 Matic");
        bool sent = payable(feeRecipient).send(msg.value);
        require(sent, "Failed to send Matic");

        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with link"
        );

        // TODO(Does the character need a VRF seed)

        // Get the next token id
        uint256 tokenId = _next_id;

        // Set Avatar data
        AvatarSheet storage avatarSheet = sheet[tokenId];
        avatarSheet.name = newAvatarName;

        // Increment ID
        _next_id += 1;

        // Mint the NFT
        _safeMint(to, tokenId);

        bytes32 requestId = requestRandomness(keyHash, fee);
        _request_map[requestId] = tokenId;
    }

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

    function increaseExperience(uint64 amount, uint256 avatarId) public {
        require(avatarId < _next_id, "Avatar not yet minted");
        require(boards[msg.sender], "Only authz board can call.");
        sheet[avatarId].experience += amount;
    }
}
