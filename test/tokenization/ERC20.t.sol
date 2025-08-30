// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "src/interfaces/tokenization/IERC20.sol";
import {IERC20Permit} from "src/interfaces/tokenization/IERC20Permit.sol";
import {MockERC20} from "test/shared/mocks/MockERC20.sol";
import {PermitUtils} from "test/shared/utils/PermitUtils.sol";
import {BaseTest} from "test/shared/env/BaseTest.sol";

contract ERC20Test is BaseTest {
	address internal immutable alice = makeAddr("alice");
	address internal immutable bob = makeAddr("bob");

	VmSafe.Wallet internal signer;
	VmSafe.Wallet internal invalidSigner;

	MockERC20 internal token;

	function setUp() public {
		signer = vm.createWallet("signer");
		invalidSigner = vm.createWallet("invalidSigner");

		token = new MockERC20("Mock Token", "MTK", 18);
	}

	function test_metadata() public view {
		assertEq(token.name(), "Mock Token");
		assertEq(token.symbol(), "MTK");
		assertEq(token.decimals(), 18);
	}

	function test_DOMAIN_SEPARATOR() public view {
		assertEq(
			token.DOMAIN_SEPARATOR(),
			PermitUtils.hash(
				PermitUtils.Domain({
					name: "Mock Token",
					version: "1",
					chainId: block.chainid,
					verifyingContract: address(token)
				})
			)
		);
	}

	function test_approve_revertsWithInvalidSpender() public {
		vm.expectRevert(IERC20.InvalidSpender.selector);
		token.approve(address(0), uint256(0));
	}

	function test_approve() public {
		vm.expectEmit(true, true, true, true);
		emit IERC20.Approval(alice, bob, 1 ether);

		vm.prank(alice);
		assertTrue(token.approve(bob, 1 ether));
		assertEq(token.allowance(alice, bob), 1 ether);

		vm.expectEmit(true, true, true, true);
		emit IERC20.Approval(alice, bob, uint256(0));

		vm.prank(alice);
		assertTrue(token.approve(bob, uint256(0)));
		assertEq(token.allowance(alice, bob), uint256(0));
	}

	function test_fuzz_approve(address spender, uint256 value) public {
		vm.assume(spender != address(0) && value != uint256(0));
		assertEq(token.allowance(address(this), spender), uint256(0));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Approval(address(this), spender, value);

		assertTrue(token.approve(spender, value));
		assertEq(token.allowance(address(this), spender), value);

		vm.expectEmit(true, true, true, true);
		emit IERC20.Approval(address(this), spender, uint256(0));

		assertTrue(token.approve(spender, uint256(0)));
		assertEq(token.allowance(address(this), spender), uint256(0));
	}

	function test_mint_revertsWithInvalidRecipient() public {
		vm.expectRevert(IERC20.InvalidRecipient.selector);
		token.mint(address(0), uint256(0));
	}

	function test_mint_zeroAmount() public {
		token.mint(alice, uint256(0));
		assertEq(token.totalSupply(), uint256(0));
		assertEq(token.balanceOf(alice), uint256(0));
	}

	function test_mint() public {
		assertEq(token.totalSupply(), uint256(0));
		assertEq(token.balanceOf(alice), uint256(0));

		token.mint(alice, 1 ether);
		assertEq(token.totalSupply(), 1 ether);
		assertEq(token.balanceOf(alice), 1 ether);
	}

	function test_fuzz_mint(address account, uint256 value) public {
		vm.assume(account != address(0));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(address(0), account, value);

		token.mint(account, value);
		assertEq(token.totalSupply(), value);
		assertEq(token.balanceOf(account), value);
	}

	function test_burn_revertsWithInvalidSender() public {
		vm.expectRevert(IERC20.InvalidSender.selector);
		token.burn(address(0), uint256(0));
	}

	function test_burn_zeroAmount() public {
		token.mint(alice, 2 ether);
		assertEq(token.totalSupply(), 2 ether);
		assertEq(token.balanceOf(alice), 2 ether);

		token.burn(alice, uint256(0));
		assertEq(token.totalSupply(), 2 ether);
		assertEq(token.balanceOf(alice), 2 ether);
	}

	function test_burn() public {
		token.mint(alice, 2 ether);
		assertEq(token.totalSupply(), 2 ether);
		assertEq(token.balanceOf(alice), 2 ether);

		token.burn(alice, 1 ether);
		assertEq(token.totalSupply(), 1 ether);
		assertEq(token.balanceOf(alice), 1 ether);
	}

	function test_fuzz_burn(address account, uint256 value) public {
		vm.assume(account != address(0));

		token.mint(account, value);
		assertEq(token.totalSupply(), value);
		assertEq(token.balanceOf(account), value);

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(account, address(0), value);

		token.burn(account, value);
		assertEq(token.totalSupply(), uint256(0));
		assertEq(token.balanceOf(account), uint256(0));
	}

	function test_transfer_revertsWithInvalidRecipient() public {
		vm.expectRevert(IERC20.InvalidRecipient.selector);
		token.transfer(address(0), uint256(0));
	}

	function test_transfer() public {
		token.mint(alice, 1 ether);
		assertEq(token.balanceOf(alice), 1 ether);
		assertEq(token.balanceOf(bob), uint256(0));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(alice, bob, 1 ether);

		vm.prank(alice);
		assertTrue(token.transfer(bob, 1 ether));
		assertEq(token.balanceOf(alice), uint256(0));
		assertEq(token.balanceOf(bob), 1 ether);
	}

	function test_fuzz_transfer(address sender, address recipient, uint256 value) public {
		vm.assume(sender != address(0) && recipient != address(0) && sender != recipient);

		token.mint(sender, value);
		assertEq(token.balanceOf(sender), value);
		assertEq(token.balanceOf(recipient), uint256(0));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(sender, recipient, value);

		vm.prank(sender);
		assertTrue(token.transfer(recipient, value));
		assertEq(token.balanceOf(sender), uint256(0));
		assertEq(token.balanceOf(recipient), value);
	}

	function test_transferFrom_revertsWithInvalidSender() public {
		vm.expectRevert(IERC20.InvalidSender.selector);
		token.transferFrom(address(0), address(0), uint256(0));
	}

	function test_transferFrom_revertsWithInvalidRecipient() public {
		vm.expectRevert(IERC20.InvalidRecipient.selector);
		token.transferFrom(alice, address(0), uint256(0));
	}

	function test_transferFrom() public {
		token.mint(alice, 1 ether);
		assertEq(token.balanceOf(alice), 1 ether);
		assertEq(token.balanceOf(bob), uint256(0));

		vm.prank(alice);
		assertTrue(token.approve(address(this), 1 ether));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(alice, bob, 1 ether);

		assertTrue(token.transferFrom(alice, bob, 1 ether));
		assertEq(token.balanceOf(alice), uint256(0));
		assertEq(token.balanceOf(bob), 1 ether);
	}

	function test_fuzz_transferFrom(address sender, address recipient, uint256 value) public {
		vm.assume(sender != address(0) && recipient != address(0) && sender != recipient);

		token.mint(sender, value);
		assertEq(token.balanceOf(sender), value);
		assertEq(token.balanceOf(recipient), uint256(0));

		vm.prank(sender);
		assertTrue(token.approve(address(this), value));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(sender, recipient, value);

		assertTrue(token.transferFrom(sender, recipient, value));
		assertEq(token.balanceOf(sender), uint256(0));
		assertEq(token.balanceOf(recipient), value);
	}

	function test_permit_revertsWithInvalidSigner() public {
		PermitUtils.Permit memory params = PermitUtils.Permit({
			owner: signer.addr,
			spender: address(0xdeadbeef),
			value: 100 ether,
			nonce: token.nonces(signer.addr),
			deadline: block.timestamp
		});

		_testPermit(params, invalidSigner.privateKey);
	}

	function test_permit_revertsWithDeadlineExpired() public {
		PermitUtils.Permit memory params = PermitUtils.Permit({
			owner: signer.addr,
			spender: address(0xdeadbeef),
			value: 100 ether,
			nonce: token.nonces(signer.addr),
			deadline: block.timestamp - 1
		});

		_testPermit(params, signer.privateKey);
	}

	function test_permit_revertsWithInvalidApprover() internal {
		PermitUtils.Permit memory params = PermitUtils.Permit({
			owner: address(0),
			spender: address(0xdeadbeef),
			value: 100 ether,
			nonce: uint256(0),
			deadline: block.timestamp
		});

		_testPermit(params, signer.privateKey);
	}

	function test_permit_revertsWithInvalidSpender() public {
		PermitUtils.Permit memory params = PermitUtils.Permit({
			owner: signer.addr,
			spender: address(0),
			value: 100 ether,
			nonce: token.nonces(signer.addr),
			deadline: block.timestamp
		});

		_testPermit(params, signer.privateKey);
	}

	function test_permit() public {
		PermitUtils.Permit memory params = PermitUtils.Permit({
			owner: signer.addr,
			spender: address(0xdeadbeef),
			value: 100 ether,
			nonce: token.nonces(signer.addr),
			deadline: block.timestamp
		});

		_testPermit(params, signer.privateKey);

		assertEq(token.allowance(params.owner, params.spender), params.value);
		assertEq(token.nonces(params.owner), params.nonce + 1);
	}

	function test_fuzz_permit(address spender, uint256 value, uint256 deadline) public {
		vm.assume(spender != address(0) && signer.addr != spender);

		PermitUtils.Permit memory params = PermitUtils.Permit({
			owner: signer.addr,
			spender: spender,
			value: value,
			nonce: token.nonces(signer.addr),
			deadline: deadline < block.timestamp ? block.timestamp : deadline
		});

		(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(params, token.DOMAIN_SEPARATOR(), signer.privateKey);

		vm.expectEmit(true, true, true, true);
		emit IERC20.Approval(params.owner, params.spender, params.value);

		token.permit(params.owner, params.spender, params.value, params.deadline, v, r, s);
		assertEq(token.allowance(params.owner, params.spender), params.value);
		assertEq(token.nonces(params.owner), params.nonce + 1);
	}

	function _testPermit(PermitUtils.Permit memory params, uint256 privateKey) private {
		(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(params, token.DOMAIN_SEPARATOR(), privateKey);

		if (privateKey != signer.privateKey) {
			vm.expectRevert(IERC20Permit.InvalidSigner.selector);
		} else if (params.owner == address(0)) {
			vm.expectRevert(IERC20.InvalidApprover.selector);
		} else if (params.spender == address(0)) {
			vm.expectRevert(IERC20.InvalidSpender.selector);
		} else if (params.deadline != block.timestamp) {
			vm.expectRevert(IERC20Permit.DeadlineExpired.selector);
		} else {
			vm.expectEmit(true, true, true, true);
			emit IERC20.Approval(params.owner, params.spender, params.value);
		}

		token.permit(params.owner, params.spender, params.value, params.deadline, v, r, s);
	}
}
