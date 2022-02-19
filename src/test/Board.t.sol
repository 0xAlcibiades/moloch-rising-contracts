// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../Board.sol";
import "ds-test/test.sol";

contract BoardTest is DSTest {
    Board board;

    function setUp() public {
        uint256 gameSeed = 123456789;
        board = new Board(gameSeed);
    }

    function testStart() public {
        uint64 game0 = board.start{value: 1 ether}();
        uint64 game1 = board.start{value: 1 ether}();
        assert(game0 == 0);
        assert(game1 == 1);
    }

    function testComplete() public {
        board.start{value: 1 ether}();
        board.complete(0);
    }
}
