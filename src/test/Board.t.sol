// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../Board.sol";
import "ds-test/test.sol";

contract BoardTest is DSTest {
    Board board;

    function setUp() public {
        board = new Board();
    }

    function testPass() public {
        assert(true == true);
    }
}
