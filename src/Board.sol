// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.10;

import "./Loot.sol";
import "./Avatar.sol";
import "solmate/auth/authorities/MultiRolesAuthority.sol";

// TODO(Circom verifier inheritance for zkSnark)
contract Board is MultiRolesAuthority {
    address public immutable feeRecipient =
        0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5;

    address avatar;

    address loot;

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
        setRoleCapability(0, 0x87d0040c, true);
    }

    function updateAvatar(address avatarContract) public requiresAuth {
        avatar = avatarContract;
    }

    function updateLoot(address lootContract) public requiresAuth {
        loot = lootContract;
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

        // TODO(Add method to avatar to just get seed, for a huge gas savings (6 sload) - out of time)
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
        // 10% chance to destroy an item
        if (seed % 9 == 9) {
            // Chose item slot
            uint256 slot;
            slot = seed % 2;
            // TODO(Add method to avatar to just get seed, for a huge gas savings (6 sload) - out of time)
            (
                bool seeded,
                uint64 experience,
                string memory name,
                uint256 weapon,
                uint256 armor,
                uint256 implant,
                uint256 seed
            ) = IAvatar.sheet(avatarId);
            uint256 item;
            if (slot == 0) {
                item = weapon;
            } else if (slot == 1) {
                item = weapon;
            } else {
                item = implant;
            }
            if (item != 0) {
                // Loot was damaged beyond repair.
                IAvatar.unequip(item, avatarId, feeRecipient);
            }
        }
    }

    function accrueExperience(
        Avatar IAvatar,
        uint256 avatarId,
        uint256 seed
    ) internal {
        uint256 max = 400;
        // TODO(Add method to avatar to just get seed, for a huge gas savings (6 sload) - out of time)
        (
            bool seeded,
            uint64 experience,
            string memory name,
            uint256 weapon,
            uint256 armor,
            uint256 implant,
            uint256 seed
        ) = IAvatar.sheet(avatarId);
        if (experience < max) {
            max = max - uint256(experience);
            IAvatar.increaseExperience(uint64(seed % max), avatarId);
        }
    }

    function lootDrop(
        Avatar IAvatar,
        uint256 avatarId,
        uint256 seed
    ) internal {
        (, uint64 experience, , , , , ) = IAvatar.sheet(avatarId);
        uint256 slot;
        slot = seed % 2;
        if (experience < 350) {
            // Odds of loot drop
            // Common 15%
            // Uncommon 10%
            // Rare 5%
            // Epic 2%
            // Legendary 1%
            uint256 roll = seed % 99;
            if (roll >= 67 && roll < 82) {
                // drop common
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Common,
                    Name(slot)
                );
            } else if (roll >= 82 && roll < 92) {
                // drop uncommon
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Uncommon,
                    Name(slot)
                );
            } else if (roll >= 92 && roll < 97) {
                // drop rare
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Rare,
                    Name(slot)
                );
            } else if (roll >= 97 && roll < 99) {
                // drop epic
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Epic,
                    Name(slot)
                );
            } else if (roll == 99) {
                // drop legendary
                Loot(payable(loot)).mint(
                    address(this),
                    Slot(slot),
                    Grade.Legendary,
                    Name(slot)
                );
            }
        }
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
