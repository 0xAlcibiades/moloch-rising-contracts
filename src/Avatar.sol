// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.10;

import "solmate/tokens/ERC721.sol";

contract Avatar is ERC721, ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
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

    constructor(address _loot) ERC721("ROMAvatar", "ROMA") {
        loot = _loot;
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(id < _next_id, "Avatar not yet minted");
        // TODO(Return image and metadata)
        string memory uri = "";
        return uri;
    }

    function mint(address to, string memory newAvatarName) public virtual {
        // TODO(Charge mint cost here)
        // Get the next token id
        uint256 tokenId = _next_id;
        // Mint the NFT
        _safeMint(to, tokenId);
        // Set Avatar data
        AvatarSheet storage avatarSheet = sheet[tokenId];
        avatarSheet.name = newAvatarName;
        // Increment ID
        _next_id += 1;
    }

    // TODO(Equipment/loot system)

    function equip(uint256 id) public {
        // TODO(Which kind of loot is this?)
    }
}
