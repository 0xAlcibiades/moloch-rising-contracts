// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../Loot.sol";
import "../Avatar.sol";
import "ds-test/test.sol";
import "solmate/tokens/ERC721.sol";
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
        board = new Board(123456);
        avatar = new Avatar();
        avatar.updateLoot(address(loot));
        avatar.addBoard(address(board));
    }

    function testMint() public {
        avatar.mint{value: 5 ether}(address(this), "Uriel");
        avatar.mint{value: 5 ether}(address(this), "Baal");
    }

    function testEquip() public {
        avatar.mint{value: 5 ether}(address(this), "Uriel");
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        loot.mint(address(this), Slot.Armor, Grade.Uncommon, Name.LabCoat);
        loot.mint(
            address(this),
            Slot.Implant,
            Grade.Legendary,
            Name.PainSuppressor
        );
        loot.setApprovalForAll(address(avatar), true);
        avatar.equip(1, 0);
        avatar.equip(2, 0);
        avatar.equip(3, 0);
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        loot.mint(address(this), Slot.Armor, Grade.Uncommon, Name.LabCoat);
        loot.mint(
            address(this),
            Slot.Implant,
            Grade.Legendary,
            Name.PainSuppressor
        );
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
        avatar.mint{value: 5 ether}(address(this), "Uriel");
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        avatar.equip(1, 0);
        avatar.unequip(1, 0);
    }

    // TODO(Add assertions about binary content)
    function testContractURI() public {
        avatar.contractURI();
    }

    function testTokenURI() public {
        avatar.mint{value: 5 ether}(address(this), "Uriel");
        loot.mint(address(this), Slot.Weapon, Grade.Epic, Name.PlasmaCutter);
        loot.mint(address(this), Slot.Armor, Grade.Uncommon, Name.LabCoat);
        loot.mint(
            address(this),
            Slot.Implant,
            Grade.Legendary,
            Name.PainSuppressor
        );
        loot.setApprovalForAll(address(avatar), true);
        avatar.equip(1, 0);
        avatar.equip(2, 0);
        avatar.equip(3, 0);
        avatar.tokenURI(0);
    }

    function testIncreaseExperience() public {
        avatar.mint{value: 5 ether}(address(this), "Uriel");
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
