// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.10;

import "./Base64.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/auth/authorities/MultiRolesAuthority.sol";

// TODO(These enumerations need mappings to strings to correctly concatenate)
enum Slot {
    Weapon,
    Armor,
    Implant
}

enum Grade {
    Common,
    Uncommon,
    Rare,
    Epic,
    Legendary
}

enum Name {
    PlasmaCutter,
    LabCoat,
    PainSuppressor
}

struct LootInfo {
    Slot slot;
    Grade grade;
    Name name;
}

contract Loot is ERC721, MultiRolesAuthority {
    mapping(uint256 => LootInfo) _lootInfo;

    // ID 0 is reserved for "newbie loot"
    uint256 _next_id = 1;

    mapping(address => bool) boards;

    constructor()
        MultiRolesAuthority(msg.sender, Authority(address(0)))
        ERC721("Moloch Rises Loot", "MRL")
    {
        setRoleCapability(0, 0x100af824, true);
        setRoleCapability(0, 0x2affe684, true);
    }

    function addBoard(address boardContract) public requiresAuth {
        boards[boardContract] = true;
    }

    function removeBoard(address boardContract) public requiresAuth {
        boards[boardContract] = false;
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

    function lootInfo(uint256 id) public view returns (LootInfo memory info) {
        info = _lootInfo[id];
    }

    function tokenName(uint256 id) public view returns (string memory) {
        LootInfo memory info = _lootInfo[id];
        string memory grade = "";
        string memory itemName = "";

        // Grade mapping to strings
        if (info.grade == Grade.Common) {
            grade = "Common";
        } else if (info.grade == Grade.Uncommon) {
            grade = "Uncommon";
        } else if (info.grade == Grade.Rare) {
            grade = "Rare";
        } else if (info.grade == Grade.Epic) {
            grade = "Epic";
        } else if (info.grade == Grade.Legendary) {
            grade = "Legendary";
        }

        // Name mapping to strings
        if (info.name == Name.LabCoat) {
            itemName = "Lab Coat";
        } else if (info.name == Name.PlasmaCutter) {
            itemName = "Plasma Cutter";
        } else if (info.name == Name.PainSuppressor) {
            itemName = "Pain Suppressor";
        }

        return string(abi.encodePacked(grade, " ", itemName));
    }

    /* solhint-disable quotes */
    function contractURI() public pure returns (string memory) {
        // TODO(add multisig here in fee_recipient)
        // TODO(update image to correct one in arweave)
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Moloch Rises Loot", "description:": "Loot for playing the Moloch Rises roguelite.", "seller_fee_basis_points": ',
                        toString(250),
                        ', "external_link": "https://molochrises.com/", "image": "ipfs://bafkreihuy7ln4il3ou4ne5gtqnwwuqfb5enbuk5dzqpmcmisinikkdccc4", "fee_recipient": "0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5"}'
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
        // TODO(Replace loot image with proper item images)
        require(id < _next_id, "loot not yet minted");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        tokenName(id),
                        '", "description": "Loot for fighting moloch.", "image": "ipfs://bafkreihuy7ln4il3ou4ne5gtqnwwuqfb5enbuk5dzqpmcmisinikkdccc4Y"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /* solhint-enable quotes */

    function mint(
        address to,
        Slot slot,
        Grade grade,
        Name name
    ) public virtual {
        require(boards[msg.sender], "Only authz board can call.");
        // Get the next token id
        uint256 tokenId = _next_id;

        // Setup loot lootInfo
        LootInfo storage info = _lootInfo[tokenId];
        info.name = name;
        info.grade = grade;
        info.slot = slot;

        // Increment ID
        _next_id += 1;

        // Mint the NFT
        _safeMint(to, tokenId);
    }
}
