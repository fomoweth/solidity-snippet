// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC7914} from "src/interfaces/tokenization/IERC7914.sol";
import {ERC7914} from "src/tokenization/ERC7914.sol";
import {BaseTest} from "test/shared/env/BaseTest.sol";

contract ERC7914Test is BaseTest {
	ERC7914 internal erc7914;

	address internal alice;
	address internal bob;

	function setUp() public virtual {
		erc7914 = new ERC7914();
		alice = makeAddr("alice");
		bob = makeAddr("bob");
	}

	function test_approveNative_revertsWithIncorrectSender() public {
		vm.expectRevert(IERC7914.IncorrectSender.selector);
		erc7914.approveNative(alice, 1 ether);
	}

	function test_approveNative() public {
		vm.expectEmit(true, true, false, true);
		emit IERC7914.ApproveNative(address(erc7914), alice, 1 ether);

		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNative(alice, 1 ether));
		assertEq(erc7914.nativeAllowance(alice), 1 ether);
	}

	function test_approveNativeTransient_revertsWithIncorrectSender() public {
		vm.expectRevert(IERC7914.IncorrectSender.selector);
		erc7914.approveNativeTransient(alice, 1 ether);
	}

	function test_approveNativeTransient() public {
		vm.expectEmit(true, true, false, true);
		emit IERC7914.ApproveNativeTransient(address(erc7914), alice, 1 ether);

		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNativeTransient(alice, 1 ether));
		assertEq(erc7914.transientNativeAllowance(alice), 1 ether);
	}

	function test_transferFromNative_revertsWithIncorrectSender() public {
		vm.expectRevert(IERC7914.IncorrectSender.selector);
		vm.prank(alice);
		erc7914.transferFromNative(alice, bob, 1 ether);
	}

	function test_transferFromNative_revertsWithAllowanceExceeded() public {
		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNative(alice, 1 ether));

		vm.prank(alice);
		vm.expectRevert(IERC7914.AllowanceExceeded.selector);
		erc7914.transferFromNative(address(erc7914), bob, 2 ether);
	}

	function test_transferFromNative_zeroAmount_returnsTrue() public {
		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNative(alice, 1 ether));

		vm.prank(alice);
		assertTrue(erc7914.transferFromNative(address(erc7914), bob, uint256(0)));
	}

	function test_transferFromNative() public {
		vm.deal(address(erc7914), 1 ether);
		uint256 balance = address(erc7914).balance;
		uint256 initialBalance = bob.balance;

		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNative(alice, 1 ether));

		vm.expectEmit(true, true, false, true);
		emit IERC7914.NativeAllowanceUpdated(alice, uint256(0));

		vm.expectEmit(true, true, false, true);
		emit IERC7914.TransferFromNative(address(erc7914), bob, 1 ether);

		vm.prank(alice);
		assertTrue(erc7914.transferFromNative(address(erc7914), bob, 1 ether));

		assertEq(erc7914.nativeAllowance(alice), uint256(0));
		assertEq(address(erc7914).balance, balance - 1 ether);
		assertEq(bob.balance, initialBalance + 1 ether);
	}

	function test_fuzz_transferFromNative(uint256 balance, uint256 approveAmount, uint256 transferAmount) public {
		vm.deal(address(erc7914), balance);
		uint256 initialBalance = bob.balance;

		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNative(alice, approveAmount));
		assertEq(erc7914.nativeAllowance(alice), approveAmount);

		if (transferAmount > approveAmount) {
			vm.expectRevert(IERC7914.AllowanceExceeded.selector);
		} else if (transferAmount > balance) {
			vm.expectRevert(IERC7914.TransferNativeFailed.selector);
		}

		vm.prank(alice);
		bool success = erc7914.transferFromNative(address(erc7914), bob, transferAmount);

		if (success) {
			if (approveAmount != type(uint256).max) {
				assertEq(erc7914.nativeAllowance(alice), approveAmount - transferAmount);
			} else {
				assertEq(erc7914.nativeAllowance(alice), approveAmount);
			}
			assertEq(bob.balance, initialBalance + transferAmount);
			assertEq(address(erc7914).balance, balance - transferAmount);
		} else {
			assertEq(erc7914.nativeAllowance(alice), approveAmount);
			assertEq(bob.balance, initialBalance);
			assertEq(address(erc7914).balance, balance);
		}
	}

	function test_transferFromNativeTransient_revertsWithIncorrectSender() public {
		vm.prank(alice);
		vm.expectRevert(IERC7914.IncorrectSender.selector);
		erc7914.transferFromNativeTransient(alice, bob, 1 ether);
	}

	function test_transferFromNativeTransient_revertsWithAllowanceExceeded() public {
		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNativeTransient(alice, 1 ether));

		vm.prank(alice);
		vm.expectRevert(IERC7914.AllowanceExceeded.selector);
		erc7914.transferFromNativeTransient(address(erc7914), bob, 2 ether);
	}

	function test_transferFromNativeTransient_zeroAmount_returnsTrue() public {
		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNativeTransient(alice, 1 ether));

		vm.prank(alice);
		assertTrue(erc7914.transferFromNativeTransient(address(erc7914), bob, uint256(0)));
	}

	function test_transferFromNativeTransient() public {
		vm.deal(address(erc7914), 1 ether);
		uint256 balance = address(erc7914).balance;
		uint256 initialBalance = bob.balance;

		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNativeTransient(alice, 1 ether));

		vm.expectEmit(true, true, false, true);
		emit IERC7914.TransferFromNativeTransient(address(erc7914), bob, 1 ether);

		vm.prank(alice);
		assertTrue(erc7914.transferFromNativeTransient(address(erc7914), bob, 1 ether));

		assertEq(erc7914.transientNativeAllowance(alice), uint256(0));
		assertEq(address(erc7914).balance, balance - 1 ether);
		assertEq(bob.balance, initialBalance + 1 ether);
	}

	function test_fuzz_transferFromNativeTransient(uint256 balance, uint256 approveAmount, uint256 transferAmount) public {
		vm.deal(address(erc7914), balance);
		uint256 initialBalance = bob.balance;

		vm.prank(address(erc7914));
		assertTrue(erc7914.approveNativeTransient(alice, approveAmount));
		assertEq(erc7914.transientNativeAllowance(alice), approveAmount);

		if (transferAmount > approveAmount) {
			vm.expectRevert(IERC7914.AllowanceExceeded.selector);
		} else if (transferAmount > balance) {
			vm.expectRevert(IERC7914.TransferNativeFailed.selector);
		}

		vm.prank(alice);
		bool success = erc7914.transferFromNativeTransient(address(erc7914), bob, transferAmount);

		if (success) {
			if (approveAmount < type(uint256).max) {
				assertEq(erc7914.transientNativeAllowance(alice), approveAmount - transferAmount);
			} else {
				assertEq(erc7914.transientNativeAllowance(alice), approveAmount);
			}
			assertEq(address(erc7914).balance, balance - transferAmount);
			assertEq(bob.balance, initialBalance + transferAmount);
		} else {
			assertEq(erc7914.transientNativeAllowance(alice), approveAmount);
			assertEq(address(erc7914).balance, balance);
			assertEq(bob.balance, initialBalance);
		}
	}
}
