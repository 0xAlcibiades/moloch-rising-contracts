// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../Loot.sol";
import "ds-test/test.sol";
import "solmate/tokens/ERC721.sol";
import "./Utilities.sol";
import "../Board.sol";

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

contract LootTest is DSTest, ERC721Recipient, TestUtility {
    Loot loot;
    Board board;

    function setUp() public {
        // TODO(Deploy and integrate loot here)
        loot = new Loot();
        board = new Board(123456);
        loot.addBoard(address(board));
    }

    function testMint() public {
        hevm.startPrank(address(board));
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        loot.mint(address(this), Slot.Armor, Grade.Uncommon, Name.LabCoat);
        loot.mint(
            address(this),
            Slot.Implant,
            Grade.Legendary,
            Name.PainSuppressor
        );
        hevm.stopPrank();
    }

    // TODO(Add assertions about binary content)
    function testContractURI() public {
        loot.contractURI();
    }

    function testTokenURI() public {
        hevm.startPrank(address(board));
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        hevm.stopPrank();
        loot.tokenURI(1);
    }
}
