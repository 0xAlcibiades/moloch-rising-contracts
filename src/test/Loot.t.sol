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
    Avatar avatar;

    function setUp() public {
        // TODO(Deploy and integrate loot here)
        avatar = new Avatar(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4,
            0.0001 ether
        );
        loot = new Loot();
        board = new Board();
        loot.addBoard(address(board));
        avatar.updateLoot(address(loot));
        avatar.addBoard(address(board));
        loot.addBoard(address(board));
        board.updateAvatar(address(avatar));
        hevm.startPrank(0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5);
        LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB).transfer(
                address(avatar),
                9 ether
            );
        hevm.stopPrank();
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
