// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../Loot.sol";
import "ds-test/test.sol";
import "solmate/tokens/ERC721.sol";

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

contract LootTest is DSTest, ERC721Recipient {
    Loot loot;

    function setUp() public {
        // TODO(Deploy and integrate loot here)
        loot = new Loot();
    }

    function testMint() public {
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        loot.mint(address(this), Slot.Armor, Grade.Uncommon, Name.LabCoat);
        loot.mint(
            address(this),
            Slot.Implant,
            Grade.Legendary,
            Name.PainSuppressor
        );
    }

    // TODO(Add assertions about binary content)
    function testContractURI() public {
        loot.contractURI();
    }

    function testTokenURI() public {
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        loot.tokenURI(1);
    }
}
