// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

import "solmate/tokens/ERC721.sol";

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

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(id < _next_id, "Loot not yet minted");
        // TODO(Return image)
        string memory uri = "";
        return uri;
    }

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
