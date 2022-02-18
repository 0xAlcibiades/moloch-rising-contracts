// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

// TODO(Verify zkSNARK)
contract Board {
    struct Game {
        bool started;
        bool completed;
        bool victory;
    }

    uint256 seed;

    uint64 _nextPlayId = 0;
    mapping(uint64 => Game) gameInfo;

    constructor(uint256 _seed) {
        // TODO(Does this need to be per game via VRF?)
        // This is the seed used to produce numbers
        seed = _seed;
    }

    function start() public returns (uint64 playId) {
        // Start should take a player and then lock the player in the game until completion
        playId = _nextPlayId;
        _nextPlayId += 1;
        gameInfo[playId].started = true;
    }

    // This is where the challenge will lay.
    function complete(uint64 playId) public {
        // TODO(Verify zkSNARK)
        // If valid playthrough
        gameInfo[playId].completed = true;
        // If victory
        gameInfo[playId].victory = true;
    }
}
