// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../Avatar.sol";
import "ds-test/test.sol";
import "solmate/tokens/ERC721.sol";

contract ERC721Recipient is ERC721TokenReceiver {

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract AvatarTest is DSTest, ERC721Recipient {
    Avatar avatar;

    function setUp() public {
        // TODO(Deploy and integrate loot here)
        avatar = new Avatar(address(0));
    }

    function testMint() public {
        avatar.mint(address(this), "Uriel");
    }

}
