// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../Loot.sol";
import "../Avatar.sol";
import "ds-test/test.sol";
import "solmate/tokens/ERC721.sol";
import "chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "../Board.sol";
import "./Utilities.sol";

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

contract AvatarTest is DSTest, ERC721Recipient, TestUtility {
    Avatar avatar;
    Loot loot;
    Board board;

    function setUp() public {
        loot = new Loot();
        board = new Board();
        avatar = new Avatar(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4,
            0.0001 ether
        );
        avatar.updateLoot(address(loot));
        avatar.addBoard(address(board));
        loot.addBoard(address(board));
        hevm.startPrank(0xf395C4B180a5a08c91376fa2A503A3e3ec652Ef5);
        LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB).transfer(
                address(avatar),
                9 ether
            );
        hevm.stopPrank();
    }

    function testMint() public {
        avatar.mint{value: 0.001 ether}(address(this), "Uriel");
        avatar.mint{value: 0.001 ether}(address(this), "Baal");
    }

    function testEquip() public {
        avatar.mint{value: 0.001 ether}(address(this), "Uriel");
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
        loot.setApprovalForAll(address(avatar), true);
        avatar.equip(1, 0);
        avatar.equip(2, 0);
        avatar.equip(3, 0);
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
        avatar.equip(4, 0);
        avatar.equip(5, 0);
        avatar.equip(6, 0);
    }

    function testFailEquip() public {
        loot.setApprovalForAll(address(avatar), true);
        avatar.mint{value: 5 ether}(address(this), "Uriel");
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        avatar.equip(0, 0);
    }

    function testFailUnequip() public {
        loot.setApprovalForAll(address(avatar), true);
        avatar.mint{value: 5 ether}(address(this), "Uriel");
        avatar.unequip(0, 0);
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        avatar.unequip(1, 0);
    }

    function testUnequip() public {
        loot.setApprovalForAll(address(avatar), true);
        avatar.mint{value: 0.001 ether}(address(this), "Uriel");
        hevm.startPrank(address(board));
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        hevm.stopPrank();
        avatar.equip(1, 0);
        avatar.unequip(1, 0);
    }

    // TODO(Add assertions about binary content)
    function testContractURI() public {
        avatar.contractURI();
    }

    function testTokenURI() public {
        avatar.mint{value: 0.001 ether}(address(this), "Uriel");
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
        loot.setApprovalForAll(address(avatar), true);
        avatar.equip(1, 0);
        avatar.equip(2, 0);
        avatar.equip(3, 0);
        avatar.tokenURI(0);
    }

    function testIncreaseExperience() public {
        avatar.mint{value: 0.001 ether}(address(this), "Uriel");
        hevm.startPrank(address(board));
        avatar.increaseExperience(100, 0);
        hevm.stopPrank();
    }

    function testFailIncreaseExperience() public {
        hevm.startPrank(address(board));
        avatar.increaseExperience(100, 0);
        hevm.stopPrank();
    }
}
