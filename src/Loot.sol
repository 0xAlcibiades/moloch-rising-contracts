// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

import "solmate/tokens/ERC721.sol";

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
    LabCoat,
    PlasmaCutter,
    CognitiveEnhancer
}

struct LootInfo {
    Slot slot;
    Grade grade;
    Name name;
}

contract Loot is ERC721 {
    mapping(uint256 => LootInfo) _lootInfo;

    // ID 0 is reserved for "newbie loot"
    uint256 _next_id = 1;

    constructor() ERC721("Moloch Rising Loot", "MRL") {}

    function lootInfo(uint256 id) public view returns (LootInfo memory info) {
        info = _lootInfo[id];
    }

    /* solhint-disable quotes */
    function contractURI() public view returns (string memory) {
        // TODO(add multisig here in fee_recipient)
        // TODO(update image to correct one in arweave)
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Moloch Rises Loot", "description:": "Loot for playing the Moloch Rises roguelite", "seller_fee_basis_points": ',
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
        // TODO(Replace loot image)
        // TODO(Add item metadata)
        require(id < _next_id, "loot not yet minted");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        avatarSheet.name,
                        '", "description": "Loot for fighting moloch", "image": "ar://rfE4aIDBs-O_rX-WgkA3ShQoop5thwHESqfJs8C4OIY"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /* solhint-enable quotes */

    // TODO(Auth, only a board can mint loot, only an admin can allow a board)
    function mint(
        address to,
        Slot slot,
        Grade grade,
        Name name
    ) public virtual {
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
