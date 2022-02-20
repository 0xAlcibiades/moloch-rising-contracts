// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../Board.sol";
import "../Avatar.sol";
import "../Loot.sol";
import "ds-test/test.sol";
import "solmate/tokens/ERC721.sol";
import "./Utilities.sol";

contract ERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract BoardTest is DSTest, ERC721Recipient, TestUtility {
    Avatar avatar;
    Loot loot;
    Board board;

    function setUp() public {
        loot = new Loot();
        board = new Board();
        avatar = new Avatar(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4,
            0.0001 ether
        );
        hevm.startPrank(0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5);
        LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB).transfer(
                address(avatar),
                9 ether
            );
        hevm.stopPrank();
        board.updateAvatar(address(avatar));
        board.updateLoot(address(loot));
        avatar.addBoard(address(board));
        loot.addBoard(address(board));
    }

    function testStart() public {
        avatar.mint{value: 0.001 ether}(address(this), "Uriel");
        (uint64 game1Id, Board.Game memory game1) = board.start{
            value: 0.001 ether
        }(0);
        assert(game1Id == 1);
    }

    function testComplete() public {
        avatar.mint{value: 0.001 ether}(address(this), "Uriel");
        avatar.mint{value: 0.001 ether}(address(this), "Alcibiades");
        (uint64 game1Id, Board.Game memory game1) = board.start{
            value: 0.001 ether
        }(1);
        game1.victory = true;
        board.complete(game1Id, game1);
    }
}
