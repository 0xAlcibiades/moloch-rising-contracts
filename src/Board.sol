// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.10;

import "./Avatar.sol";
import "solmate/auth/authorities/MultiRolesAuthority.sol";

contract Board is MultiRolesAuthority {
    address public immutable feeRecipient =
        0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5;

    address avatar;

    struct Game {
        uint256 avatar;
        uint256 seed;
        bool started;
        bool completed;
        bool victory;
        bool resign;
    }

    // 0 is reserved here to indicate player not in a game
    uint64 _nextPlayId = 1;

    mapping(uint256 => uint64) public avatarGame;

    mapping(uint64 => Game) public gameInfo;

    constructor() MultiRolesAuthority(msg.sender, Authority(address(0))) {
        setRoleCapability(0, 0x4417cb58, true);
    }

    function updateAvatar(address avatarContract) public requiresAuth {
        avatar = avatarContract;
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
        returns (uint64 playId, Game memory gameInstance)
    {
        require(avatarGame[avatarId] == 0, "Player already in game");

        // Get avatar info
        Avatar IAvatar = Avatar(payable(avatar));

        require(
            msg.sender == IAvatar.ownerOf(avatarId),
            "Must own character to play"
        );

        // Coin operated game
        // TODO(Reset to 1 matic)
        require(msg.value == 0.001 ether, "Playing requires 1 Matic");
        bool sent = payable(feeRecipient).send(msg.value);
        require(sent, "Failed to send Matic");

        playId = _nextPlayId;

        avatarGame[avatarId] = playId;

        // TODO(Add method to avatar to just get seed, for a huge gas savings - out of time)
        (, , , , , , uint256 seed) = IAvatar.sheet(avatarId);

        gameInstance = Game(
            avatarId,
            uint256(keccak256(abi.encode(seed, playId))),
            true,
            false,
            false,
            false
        );

        gameInfo[playId] = gameInstance;

        _nextPlayId += 1;
    }

    function nftDamage(
        Avatar IAvatar,
        uint256 avatarId,
        uint256 seed
    ) internal {
        // TODO(One in 10 chance for each equipped item to be damaged)
    }

    function accrueExperience(
        Avatar IAvatar,
        uint256 avatarId,
        uint256 seed
    ) internal {
        // TODO(Experience should decrease relative to existing experience until 0)
    }

    function lootDrop(
        Avatar IAvatar,
        uint256 avatarId,
        uint256 seed
    ) internal {
        // TODO(A random loot drop to the player should occur)
    }

    function complete(uint64 gameId, Game memory gameData) public {
        require(gameId < _nextPlayId, "Game not found");

        // Get avatar info
        Avatar IAvatar = Avatar(payable(avatar));
        Game storage gameState = gameInfo[gameId];

        require(
            msg.sender == IAvatar.ownerOf(gameState.avatar),
            "Must own character to finish game"
        );

        // Update game state
        bool lost = true;
        if (gameData.resign) {
            // End without validating playthrough
            avatarGame[gameData.avatar] = 0;
            gameState.resign = true;
        } else {
            // TODO(Verify zkSNARK before just accepting this)
            lost = gameData.victory;
        }
        if (lost) {
            gameState.victory = false;
            nftDamage(IAvatar, gameState.avatar, gameState.seed);
        } else {
            accrueExperience(IAvatar, gameState.avatar, gameState.seed);
            lootDrop(IAvatar, gameState.avatar, gameState.seed);
            gameState.victory = true;
        }
        gameState.completed = true;
    }
}
