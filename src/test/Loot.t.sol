// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../Loot.sol";
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

contract LootTest is DSTest, ERC721Recipient {
    Loot avatar;

    function setUp() public {
        // TODO(Deploy and integrate loot here)
        avatar = new Loot();
    }

    function testMint() public {
        avatar.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        avatar.mint(address(this), Slot.Armor, Grade.Uncommon, Name.LabCoat);
        avatar.mint(
            address(this),
            Slot.Implant,
            Grade.Legendary,
            Name.CognitiveEnhancer
        );
    }
}
