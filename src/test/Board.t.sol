// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../Board.sol";
import "ds-test/test.sol";

contract BoardTest is DSTest {
    Board board;

    function setUp() public {
        uint256 gameSeed = 123456789;
        board = new Board(gameSeed);
    }

    function testStart() public {
        (uint64 game0, uint256 seed0) = board.start{value: 1 ether}(0);
        (uint64 game1, uint256 seed1) = board.start{value: 1 ether}(0);
        assert(game0 == 0);
        assert(game1 == 1);
    }

    function testComplete() public {
        board.start{value: 1 ether}(0);
        board.complete(0);
    }
}
