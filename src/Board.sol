// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.10;

import "./Avatar.sol";

// TODO(Avatar experience mechanic)
// TODO(Loot drop mechanic)
// TODO(Verify zkSNARK)
contract Board {
    address public immutable feeRecipient =
        0x36273803306a3C22bc848f8Db761e974697ece0d;

    struct Game {
        bool started;
        bool completed;
        bool victory;
    }

    uint256 seed;

    uint64 _nextPlayId = 0;
    mapping(uint64 => Game) gameInfo;

    constructor(uint256 _seed) {
        // This is the seed used to produce numbers
        seed = _seed;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        revert("Incorrect function paid");
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        revert("Incorrect function paid");
    }

    function start(uint256 avatarId)
        public
        payable
        returns (uint64 playId, uint256 gameSeed)
    {
        require(msg.value == 1 ether, "Playing requires 1 Matic");
        bool sent = payable(feeRecipient).send(msg.value);
        require(sent, "Failed to send Matic");
        // Start should take a player and then lock the player in the game until completion
        playId = _nextPlayId;
        _nextPlayId += 1;
        // TODO(correct seed from vrf)
        gameSeed = seed;
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
