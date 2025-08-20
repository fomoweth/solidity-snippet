// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "src/interfaces/tokenization/IERC20.sol";
import {IERC20Permit} from "src/interfaces/tokenization/IERC20Permit.sol";
import {MockERC20} from "test/shared/mocks/MockERC20.sol";
import {PermitUtils} from "test/shared/utils/PermitUtils.sol";
import {Static} from "test/shared/utils/Static.sol";
import {BaseTest} from "test/shared/env/BaseTest.sol";

contract ERC20Test is BaseTest {
	VmSafe.Wallet internal signer;
	VmSafe.Wallet internal invalidSigner;

	MockERC20 internal token;

	function setUp() public virtual {
		signer = vm.createWallet("Signer");
		invalidSigner = vm.createWallet("InvalidSigner");

		token = new MockERC20("Mock Token", "MTK", 18);
	}

	function test_constructor() public view {
		assertEq(token.name(), "Mock Token");
		assertEq(token.symbol(), "MTK");
		assertEq(token.decimals(), 18);
	}

	function test_domainSeparator() public view {
		assertEq(
			token.DOMAIN_SEPARATOR(),
			PermitUtils.hash(
				PermitUtils.DomainField({
					name: "Mock Token",
					version: "1",
					chainId: block.chainid,
					verifyingContract: address(token)
				})
			)
		);
	}

	function test_fuzz_mint(address account, uint256 value) public {
		vm.assume(account != address(0));
		assertEq(token.totalSupply(), uint256(0));
		assertEq(token.balanceOf(account), uint256(0));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(address(0), account, value);

		token.mint(account, value);
		assertEq(token.totalSupply(), value);
		assertEq(token.balanceOf(account), value);
	}

	function test_mint_revertsWithInvalidReceiver() public {
		vm.expectRevert(IERC20.InvalidReceiver.selector);
		token.mint(address(0), uint256(0));
	}

	function test_fuzz_burn(address account, uint256 value) public {
		vm.assume(account != address(0) && value != uint256(0));

		token.mint(account, value);
		assertEq(token.totalSupply(), value);
		assertEq(token.balanceOf(account), value);

		token.burn(account, uint256(0));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(account, address(0), value);

		token.burn(account, value);
		assertEq(token.totalSupply(), uint256(0));
		assertEq(token.balanceOf(account), uint256(0));
	}

	function test_burn_revertsWithInvalidSender() public {
		vm.expectRevert(IERC20.InvalidSender.selector);
		token.burn(address(0), uint256(0));
	}

	function test_fuzz_transfer(address sender, address receiver, uint256 value) public {
		vm.assume(sender != address(0) && receiver != address(0) && sender != receiver);

		token.mint(sender, value);
		assertEq(token.balanceOf(sender), value);
		assertEq(token.balanceOf(receiver), uint256(0));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(sender, receiver, value);

		vm.prank(sender);
		assertTrue(token.transfer(receiver, value));
		assertEq(token.balanceOf(sender), 0);
		assertEq(token.balanceOf(receiver), value);
	}

	function test_transfer_revertsWithInvalidReceiver() public {
		vm.expectRevert(IERC20.InvalidReceiver.selector);
		token.transfer(address(0), uint256(0));
	}

	function test_fuzz_transferFrom(address sender, address receiver, uint256 value) public {
		vm.assume(sender != address(0) && receiver != address(0) && sender != receiver);

		token.mint(sender, value);
		assertEq(token.balanceOf(sender), value);
		assertEq(token.balanceOf(receiver), uint256(0));

		vm.prank(sender);
		assertTrue(token.approve(address(this), value));

		vm.expectEmit(true, true, true, true);
		emit IERC20.Transfer(sender, receiver, value);

		assertTrue(token.transferFrom(sender, receiver, value));
		assertEq(token.balanceOf(sender), uint256(0));
		assertEq(token.balanceOf(receiver), value);
	}

	function test_transferFrom_revertsWithInvalidSender() public {
		vm.expectRevert(IERC20.InvalidSender.selector);
		token.transferFrom(address(0), address(0), uint256(0));
	}

	function test_transferFrom_revertsWithInvalidReceiver() public {
		vm.expectRevert(IERC20.InvalidReceiver.selector);
		token.transferFrom(signer.addr, address(0), uint256(0));
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

	function test_approve_revertsWithInvalidSpender() public {
		vm.expectRevert(IERC20.InvalidSpender.selector);
		token.approve(address(0), uint256(0));
	}

	function test_fuzz_permit(address spender, uint256 value, uint256 deadline) public {
		vm.assume(spender != address(0) && signer.addr != spender);

		PermitUtils.PermitField memory params = PermitUtils.PermitField({
			owner: signer.addr,
			spender: spender,
			value: value,
			nonce: token.nonces(signer.addr),
			deadline: deadline < block.timestamp ? block.timestamp : deadline
		});

		(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(params, address(token), signer.privateKey);

		vm.expectEmit(true, true, true, true);
		emit IERC20.Approval(params.owner, params.spender, params.value);

		token.permit(params.owner, params.spender, params.value, params.deadline, v, r, s);
		assertEq(token.allowance(params.owner, params.spender), params.value);
		assertEq(token.nonces(params.owner), params.nonce + 1);
	}

	function test_permit_revertsWithDeadlineExpired() public {
		PermitUtils.PermitField memory params = PermitUtils.PermitField({
			owner: signer.addr,
			spender: address(0xdeadbeef),
			value: uint256(0),
			nonce: uint256(0),
			deadline: block.timestamp - 1
		});

		(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(params, address(token), signer.privateKey);

		vm.expectRevert(IERC20Permit.DeadlineExpired.selector);
		token.permit(params.owner, params.spender, params.value, params.deadline, v, r, s);
	}

	function test_permit_revertsWithInvalidSigner() public {
		PermitUtils.PermitField memory params = PermitUtils.PermitField({
			owner: signer.addr,
			spender: address(0xdeadbeef),
			value: 100 ether,
			nonce: token.nonces(signer.addr),
			deadline: block.timestamp
		});

		(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(params, address(token), invalidSigner.privateKey);

		vm.expectRevert(IERC20Permit.InvalidSigner.selector);
		token.permit(params.owner, params.spender, params.value, params.deadline, v, r, s);
	}

	function test_permit_revertsWithInvalidApprover() internal {
		PermitUtils.PermitField memory params = PermitUtils.PermitField({
			owner: address(0),
			spender: address(0),
			value: uint256(0),
			nonce: uint256(0),
			deadline: uint256(0)
		});

		(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(params, address(token), signer.privateKey);

		vm.expectRevert(IERC20.InvalidApprover.selector);
		token.permit(params.owner, params.spender, params.value, params.deadline, v, r, s);
	}

	function test_permit_revertsWithInvalidSpender() public {
		PermitUtils.PermitField memory params = PermitUtils.PermitField({
			owner: address(0),
			spender: address(0),
			value: uint256(0),
			nonce: uint256(0),
			deadline: uint256(0)
		});

		(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(params, address(token), signer.privateKey);

		vm.expectRevert(IERC20.InvalidSpender.selector);
		token.permit(signer.addr, params.spender, params.value, params.deadline, v, r, s);
	}
}
