// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.10;

import "solmate/tokens/ERC721.sol";

// TODO(Auth, only a board can mint loot, only an admin can allow a board)
contract Loot is ERC721 {

    // ID 0 is reserved for "newbie loot"
    uint256 _next_id = 1;

    constructor() ERC721("ROML", "ROML") {}

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        require(id < _next_id, "Loot not yet minted");
        // TODO(Return image)
        string memory uri = "";
        return uri;
    }

    function mint(address to) public virtual {
        // TODO(Charge mint cost here)
        // Get the next token id
        uint256 tokenId = _next_id;
        // Mint the NFT
        _safeMint(to, tokenId);
        // Increment ID
        _next_id += 1;
    }
}