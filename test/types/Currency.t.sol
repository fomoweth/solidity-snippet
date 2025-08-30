// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IPermit2, IAllowanceTransfer} from "permit2/interfaces/IPermit2.sol";
import {Currency, CurrencyLibrary} from "src/types/Currency.sol";
import {MockERC20} from "test/shared/mocks/MockERC20.sol";
import {PermitUtils} from "test/shared/utils/PermitUtils.sol";

contract CurrencyTest is Test {
	bytes32 internal constant PERMIT2_DOMAIN_SEPARATOR =
		0x866a5aba21966af95d6c7ab78eb2b2fc913915c28be3b9aa07cc04ff903e3f28;

	bytes32 internal constant DAI_DOMAIN_SEPARATOR = 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

	bytes32 internal constant USDC_DOMAIN_SEPARATOR =
		0x06c37168a7db5138defc7866392bb87a741f9b3d104deb5094588ce041cae335;

	IPermit2 internal constant PERMIT2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

	Currency internal constant WETH = Currency.wrap(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	Currency internal constant WBTC = Currency.wrap(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
	Currency internal constant DAI = Currency.wrap(0x6B175474E89094C44Da98b954EedeAC495271d0F);
	Currency internal constant USDC = Currency.wrap(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	Currency internal constant USDT = Currency.wrap(0xdAC17F958D2ee523a2206206994597C13D831ec7);

	uint256 internal constant initialBalance = 1000 ether;

	address internal immutable alice = makeAddr("alice");
	address internal immutable bob = makeAddr("bob");

	VmSafe.Wallet internal signer;

	CurrencyHarness internal harness;
	MockERC20 internal token;

	Currency internal mock;
	Currency[] internal currencies;

	function setUp() public {
		vm.createSelectFork("ethereum", 23252517);
		signer = vm.createWallet("signer");

		harness = new CurrencyHarness();
		token = new MockERC20("Mock Token", "MTK", 18);

		currencies = new Currency[](6);
		currencies[0] = mock = Currency.wrap(address(token));
		currencies[1] = WETH;
		currencies[2] = WBTC;
		currencies[3] = DAI;
		currencies[4] = USDC;
		currencies[5] = USDT;

		token.mint(alice, initialBalance);
		token.mint(address(harness), initialBalance);

		deal(alice, initialBalance);
		deal(address(harness), initialBalance);

		deal(WETH.toAddress(), alice, initialBalance);
		deal(WETH.toAddress(), address(harness), initialBalance);

		deal(WBTC.toAddress(), alice, 100e8);
		deal(WBTC.toAddress(), address(harness), 100e8);

		deal(DAI.toAddress(), alice, 1000000 ether);
		deal(DAI.toAddress(), address(harness), 1000000 ether);

		deal(USDC.toAddress(), alice, 1000000e6);
		deal(USDC.toAddress(), address(harness), 1000000e6);

		deal(USDT.toAddress(), alice, 1000000e6);
		deal(USDT.toAddress(), address(harness), 1000000e6);
	}

	function test_fuzz_equals(Currency x, Currency y) public pure {
		assertEq(x == y, Currency.unwrap(x) == Currency.unwrap(y));
	}

	function test_fuzz_greaterThan(Currency x, Currency y) public pure {
		assertEq(x > y, Currency.unwrap(x) > Currency.unwrap(y));
	}

	function test_fuzz_greaterThanOrEqualTo(Currency x, Currency y) public pure {
		assertEq(x >= y, Currency.unwrap(x) >= Currency.unwrap(y));
	}

	function test_fuzz_lessThan(Currency x, Currency y) public pure {
		assertEq(x < y, Currency.unwrap(x) < Currency.unwrap(y));
	}

	function test_fuzz_lessThanOrEqualTo(Currency x, Currency y) public pure {
		assertEq(x <= y, Currency.unwrap(x) <= Currency.unwrap(y));
	}

	function test_isNative_native() public pure {
		assertTrue(CurrencyLibrary.NATIVE.isNative());
		assertTrue(CurrencyLibrary.ZERO.isNative());
	}

	function test_isNative_erc20() public view {
		assertFalse(mock.isNative());
		assertFalse(WETH.isNative());
		assertFalse(WBTC.isNative());
		assertFalse(DAI.isNative());
		assertFalse(USDC.isNative());
		assertFalse(USDT.isNative());
	}

	function test_isZero_native() public pure {
		assertFalse(CurrencyLibrary.NATIVE.isZero());
		assertTrue(CurrencyLibrary.ZERO.isZero());
	}

	function test_isZero_erc20() public view {
		assertFalse(mock.isZero());
		assertFalse(WETH.isZero());
		assertFalse(WBTC.isZero());
		assertFalse(DAI.isZero());
		assertFalse(USDC.isZero());
		assertFalse(USDT.isZero());
	}

	function test_fuzz_isZero(Currency c) public pure {
		assertEq(c.isZero(), (Currency.unwrap(c) == address(0)));
	}

	function test_toAddress_native() public pure {
		assertEq(CurrencyLibrary.NATIVE.toAddress(), CurrencyLibrary.NATIVE_ADDRESS);
		assertEq(CurrencyLibrary.ZERO.toAddress(), address(0));
	}

	function test_toAddress_erc20() public view {
		assertEq(mock.toAddress(), address(token));
	}

	function test_fuzz_toAddress(Currency c) public pure {
		assertEq(c.toAddress(), Currency.unwrap(c));
	}

	function test_toId_native() public pure {
		assertEq(CurrencyLibrary.NATIVE.toId(), uint256(uint160(CurrencyLibrary.NATIVE_ADDRESS)));
		assertEq(CurrencyLibrary.ZERO.toId(), uint256(0));
	}

	function test_toId_erc20() public view {
		assertEq(mock.toId(), uint160(address(token)));
	}

	function test_fuzz_toId_erc20(Currency c) public pure {
		assertEq(c.toId(), uint160(Currency.unwrap(c)));
	}

	function test_fromId_native() public pure {
		assertEq(CurrencyLibrary.fromId(uint256(uint160(CurrencyLibrary.NATIVE_ADDRESS))), CurrencyLibrary.NATIVE);
		assertEq(CurrencyLibrary.fromId(uint256(0)), CurrencyLibrary.ZERO);
	}

	function test_fuzz_fromId_erc20(uint256 id) public pure {
		assertEq(CurrencyLibrary.fromId(id), Currency.wrap(address(uint160(uint256(type(uint160).max) & id))));
	}

	function test_fuzz_fromId_toId_opposites(Currency c) public pure {
		assertEq(CurrencyLibrary.fromId(c.toId()), c);
	}

	function test_fuzz_toId_fromId_opposites(uint256 id) public pure {
		assertEq(CurrencyLibrary.fromId(id).toId(), id & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
	}

	function test_decimals_native() public view {
		assertEq(CurrencyLibrary.NATIVE.decimals(), 18);
		assertEq(CurrencyLibrary.ZERO.decimals(), 18);
	}

	function test_decimals_erc20() public view {
		assertEq(mock.decimals(), token.decimals());
		assertEq(WETH.decimals(), 18);
		assertEq(WBTC.decimals(), 8);
		assertEq(DAI.decimals(), 18);
		assertEq(USDC.decimals(), 6);
		assertEq(USDT.decimals(), 6);
	}

	function test_totalSupply_native() public {
		vm.expectRevert(CurrencyLibrary.InvalidCurrency.selector);
		CurrencyLibrary.NATIVE.totalSupply();

		vm.expectRevert(CurrencyLibrary.InvalidCurrency.selector);
		CurrencyLibrary.ZERO.totalSupply();
	}

	function test_totalSupply_erc20() public view {
		assertEq(mock.totalSupply(), token.totalSupply());
	}

	function test_allowance_native() public view {
		assertEq(harness.allowance(CurrencyLibrary.NATIVE, bob, false), type(uint256).max);
		assertEq(harness.allowance(CurrencyLibrary.NATIVE, bob, true), type(uint256).max);

		assertEq(harness.allowance(CurrencyLibrary.ZERO, bob, false), type(uint256).max);
		assertEq(harness.allowance(CurrencyLibrary.ZERO, bob, true), type(uint256).max);
	}

	function test_allowance_erc20() public {
		assertEq(harness.allowance(mock, bob, false), uint256(0));
		harness.approve(mock, bob, 1 ether, false);
		assertEq(harness.allowance(mock, bob, false), 1 ether);
		assertEq(token.allowance(address(harness), bob), 1 ether);
	}

	function test_balanceOf_native() public view {
		assertEq(CurrencyLibrary.NATIVE.balanceOf(address(this)), address(this).balance);
		assertEq(CurrencyLibrary.NATIVE.balanceOf(address(harness)), address(harness).balance);
		assertEq(CurrencyLibrary.NATIVE.balanceOf(bob), bob.balance);
	}

	function test_balanceOfSelf_native() public view {
		assertEq(CurrencyLibrary.NATIVE.balanceOfSelf(), address(this).balance);
		assertEq(harness.balanceOfSelf(CurrencyLibrary.NATIVE), address(harness).balance);
	}

	function test_balanceOf_erc20() public view {
		assertEq(mock.balanceOf(address(this)), token.balanceOf(address(this)));
		assertEq(mock.balanceOf(address(harness)), token.balanceOf(address(harness)));
		assertEq(mock.balanceOf(alice), token.balanceOf(alice));
		assertEq(mock.balanceOf(bob), token.balanceOf(bob));
	}

	function test_balanceOfSelf_erc20() public view {
		assertEq(mock.balanceOfSelf(), token.balanceOf(address(this)));
		assertEq(harness.balanceOfSelf(mock), token.balanceOf(address(harness)));
	}

	function test_approve_erc20() public {
		Currency currency = randomCurrency();
		assertEq(harness.allowance(currency, bob, false), uint256(0));
		testApprove(currency, type(uint256).max, uint256(0), false);
	}

	function test_approve_permit2_approve() public {
		Currency currency = randomCurrency();
		assertEq(harness.allowance(currency, bob, true), uint256(0));
		testApprove(currency, type(uint160).max, type(uint48).max, true);
	}

	function test_approve_permit2_lockdown() public {
		Currency currency = randomCurrency();
		uint256 allowed = packAllowance(type(uint160).max, block.timestamp);
		harness.approve(currency, bob, allowed, true);
		assertEq(harness.allowance(currency, bob, true), allowed);
		testApprove(currency, uint256(0), uint256(0), true);
	}

	function test_fuzz_approve_native(uint256 value, bool usePermit2) public {
		harness.approve(CurrencyLibrary.NATIVE, bob, value, usePermit2);
		harness.approve(CurrencyLibrary.ZERO, bob, value, usePermit2);
	}

	function test_fuzz_approve_erc20(uint256 value) public {
		Currency currency = randomCurrency();
		assertEq(harness.allowance(currency, bob, false), uint256(0));
		testApprove(currency, value, uint256(0), false);
	}

	function test_fuzz_approve(uint256 seed, uint256 value, uint24 delay, bool usePermit2) internal {
		Currency currency = randomCurrency(seed);
		assertEq(harness.allowance(currency, bob, usePermit2), uint256(0));
		testApprove(currency, value, block.timestamp + delay, usePermit2);
	}

	function test_permit_revertsWithInvalidCurrency() public {
		uint256 amount = 100 ether;
		uint256 deadline = block.timestamp + 5 minutes;

		(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(
			PermitUtils.Permit({
				owner: signer.addr,
				spender: bob,
				value: amount,
				nonce: uint256(0),
				deadline: deadline
			}),
			bytes32(0),
			signer.privateKey
		);

		vm.expectRevert(CurrencyLibrary.InvalidCurrency.selector);
		harness.permit(CurrencyLibrary.NATIVE, signer.addr, bob, amount, deadline, v, r, s);

		vm.expectRevert(CurrencyLibrary.InvalidCurrency.selector);
		harness.permit(CurrencyLibrary.ZERO, signer.addr, bob, amount, deadline, v, r, s);
	}

	function test_fuzz_permit_erc20(uint256 seed, uint256 value, uint24 delay, bool usePermit2) public {
		Currency currency = randomCurrency(seed);
		assertEq(currency.allowance(signer.addr, bob, usePermit2), uint256(0));
		testPermit(currency, value, block.timestamp + delay, usePermit2);
	}

	function test_transfer_native() public {
		testTransfer(CurrencyLibrary.NATIVE, initialBalance);
	}

	function test_transfer_zero() public {
		testTransfer(CurrencyLibrary.ZERO, initialBalance);
	}

	function test_transfer_erc20() public {
		Currency currency = randomCurrency();
		uint256 value = currency.balanceOf(alice);
		testTransfer(currency, value);
	}

	function test_fuzz_transfer_erc20(uint256 seed, uint256 value) public {
		testTransfer(randomCurrency(seed), value);
	}

	function test_transferFrom_native() public {
		testTransferFrom(CurrencyLibrary.NATIVE, initialBalance, false);
	}

	function test_transferFrom_zero() public {
		testTransferFrom(CurrencyLibrary.ZERO, initialBalance, false);
	}

	function test_transferFrom_native_revertsIfInvalidParametersGiven() public {
		vm.expectRevert(CurrencyLibrary.TransferFromNativeFailed.selector);
		harness.transferFrom{value: initialBalance}(CurrencyLibrary.NATIVE, alice, address(harness), initialBalance);

		vm.startPrank(alice);

		vm.expectRevert(CurrencyLibrary.TransferFromNativeFailed.selector);
		harness.transferFrom{value: initialBalance}(CurrencyLibrary.NATIVE, alice, address(this), initialBalance);

		vm.expectRevert(CurrencyLibrary.TransferFromNativeFailed.selector);
		harness.transferFrom{value: initialBalance - 1 ether}(
			CurrencyLibrary.NATIVE,
			alice,
			address(harness),
			initialBalance
		);

		vm.stopPrank();
	}

	function test_transferFrom_erc20() public {
		Currency currency = randomCurrency();
		uint256 value = currency.balanceOf(alice);
		testTransferFrom(currency, value, false);
	}

	function test_transferFrom_permit2() public {
		Currency currency = randomCurrency();
		uint256 value = currency.balanceOf(alice);
		testTransferFrom(currency, value, true);
	}

	function test_fuzz_transferFrom(uint256 seed, uint256 value, bool usePermit2) public {
		testTransferFrom(randomCurrency(seed), value, usePermit2);
	}

	function testApprove(Currency currency, uint256 value, uint256 expiry, bool usePermit2) internal {
		if (usePermit2) {
			value = uint160(_bound(value, type(uint160).min, type(uint160).max));
			expiry = uint48(_bound(expiry, uint48(block.timestamp), type(uint48).max));

			if (value != uint256(0)) {
				vm.expectEmit(true, true, true, true);
				emit IAllowanceTransfer.Approval(
					address(harness),
					currency.toAddress(),
					bob,
					uint160(value),
					uint48(expiry)
				);

				harness.approve(currency, bob, packAllowance(value, expiry), usePermit2);
			} else {
				vm.expectEmit(true, true, true, true);
				emit IAllowanceTransfer.Lockdown(address(harness), currency.toAddress(), bob);

				harness.approve(currency, bob, value, usePermit2);
			}

			uint256 allowed = currency.allowance(address(harness), bob, usePermit2);
			(uint160 amount, uint48 expiration, ) = unpackAllowance(allowed);
			assertEq(amount, value);
			assertEq(expiration, expiry);
		} else {
			vm.expectEmit(true, true, true, true);
			emit IERC20.Approval(address(harness), bob, value);

			harness.approve(currency, bob, value, usePermit2);
			assertEq(harness.allowance(currency, bob, usePermit2), value);
		}
	}

	function testPermit(Currency currency, uint256 value, uint256 deadline, bool usePermit2) internal {
		if (usePermit2) {
			IAllowanceTransfer.PermitDetails memory details = IAllowanceTransfer.PermitDetails({
				token: currency.toAddress(),
				amount: uint160(value),
				expiration: type(uint48).max,
				nonce: uint48(0)
			});

			(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(
				IAllowanceTransfer.PermitSingle({details: details, spender: bob, sigDeadline: deadline}),
				PERMIT2_DOMAIN_SEPARATOR,
				signer.privateKey
			);

			if (value > type(uint160).max) {
				vm.expectRevert(CurrencyLibrary.AmountOverflow.selector);

				harness.permit(currency, signer.addr, bob, value, deadline, v, r, s);
			} else {
				vm.expectEmit(true, true, true, true);

				emit IAllowanceTransfer.Permit(
					signer.addr,
					currency.toAddress(),
					bob,
					details.amount,
					details.expiration,
					details.nonce
				);

				harness.permit(currency, signer.addr, bob, value, deadline, v, r, s);

				uint256 allowed = currency.allowance(signer.addr, bob, usePermit2);
				(uint160 amount, uint48 expiration, uint48 nonce) = unpackAllowance(allowed);

				assertEq(amount, details.amount);
				assertEq(expiration, details.expiration);
				assertEq(nonce, details.nonce + 1);
			}
		} else {
			bytes32 separator;
			uint256 nonce;

			if (currency == DAI) {
				if (value != uint256(0)) value = type(uint256).max;
				separator = DAI_DOMAIN_SEPARATOR;
				nonce = DAI.nonces(signer.addr);
			} else if (currency == USDC) {
				separator = USDC_DOMAIN_SEPARATOR;
				nonce = USDC.nonces(signer.addr);
			} else if (currency == mock) {
				separator = token.DOMAIN_SEPARATOR();
				nonce = mock.nonces(signer.addr);
			}

			(uint8 v, bytes32 r, bytes32 s) = PermitUtils.signPermit(
				PermitUtils.Permit({owner: signer.addr, spender: bob, value: value, nonce: nonce, deadline: deadline}),
				separator,
				signer.privateKey
			);

			if (separator == bytes32(0)) {
				if (value > type(uint160).max) {
					vm.expectRevert(CurrencyLibrary.AmountOverflow.selector);
				} else {
					vm.expectRevert(CurrencyLibrary.PermitFailed.selector);
				}

				harness.permit(currency, signer.addr, bob, value, deadline, v, r, s);
			} else {
				vm.expectEmit(true, true, true, true);

				emit IERC20.Approval(signer.addr, bob, value);

				harness.permit(currency, signer.addr, bob, value, deadline, v, r, s);
				assertEq(currency.allowance(signer.addr, bob, usePermit2), value);
				assertEq(currency.nonces(signer.addr), nonce + 1);
			}
		}
	}

	function testTransfer(Currency currency, uint256 value) internal {
		uint256 senderBalance = harness.balanceOfSelf(currency);
		uint256 receiverBalance = currency.balanceOf(bob);

		if (value <= senderBalance) {
			if (!currency.isNative()) {
				vm.expectEmit(true, true, true, true);
				emit IERC20.Transfer(address(harness), bob, value);
			}

			senderBalance -= value;
			receiverBalance += value;
		} else {
			currency.isNative()
				? vm.expectRevert(CurrencyLibrary.TransferNativeFailed.selector)
				: vm.expectRevert(CurrencyLibrary.TransferFailed.selector);
		}

		harness.transfer(currency, bob, value);

		assertEq(harness.balanceOfSelf(currency), senderBalance);
		assertEq(currency.balanceOf(bob), receiverBalance);
	}

	function testTransferFrom(Currency currency, uint256 value, bool usePermit2) internal {
		vm.startPrank(alice);

		address receiver = currency.isNative() ? address(harness) : bob;
		uint256 senderBalance = currency.balanceOf(alice);
		uint256 receiverBalance = currency.balanceOf(receiver);

		if (currency.isNative()) {
			if (value <= senderBalance) {
				senderBalance -= value;
				receiverBalance += value;
				harness.transferFrom{value: value}(currency, alice, receiver, value);
			} else {
				value = senderBalance;
				vm.expectRevert(CurrencyLibrary.TransferFromNativeFailed.selector);
				harness.transferFrom{value: value - 10}(currency, alice, receiver, value);
			}
		} else {
			if (value <= senderBalance) {
				if (usePermit2) {
					currency.approve(address(PERMIT2), type(uint256).max, false);
					currency.approve(address(harness), packAllowance(type(uint160).max, type(uint48).max), true);
					if (value > type(uint160).max) vm.expectRevert(CurrencyLibrary.AmountOverflow.selector);
				} else {
					currency.approve(address(harness), type(uint256).max, false);
				}

				vm.expectEmit(true, true, true, true);
				emit IERC20.Transfer(alice, receiver, value);

				senderBalance -= value;
				receiverBalance += value;
			} else {
				if (value > type(uint160).max) {
					vm.expectRevert(CurrencyLibrary.AmountOverflow.selector);
				} else {
					vm.expectRevert(CurrencyLibrary.TransferFromFailed.selector);
				}
			}

			harness.transferFrom(currency, alice, receiver, value);
		}

		assertEq(currency.balanceOf(alice), senderBalance);
		assertEq(currency.balanceOf(receiver), receiverBalance);

		vm.stopPrank();
	}

	function randomCurrency() internal view returns (Currency) {
		return randomCurrency(vm.randomUint());
	}

	function randomCurrency(uint256 seed) internal view returns (Currency) {
		return currencies[seed % currencies.length];
	}

	function packAllowance(uint256 amount, uint256 expiration, uint256 nonce) internal pure returns (uint256) {
		return (nonce << 208) | (expiration << 160) | amount;
	}

	function packAllowance(uint256 amount, uint256 expiration) internal pure returns (uint256) {
		return packAllowance(amount, expiration, uint256(0));
	}

	function unpackAllowance(uint256 allowed) internal pure returns (uint160 amount, uint48 expiration, uint48 nonce) {
		amount = uint160(allowed);
		expiration = uint48(allowed >> 160);
		nonce = uint48(allowed >> 208);
	}

	function assertEq(Currency x, Currency y) internal pure {
		assertEq(Currency.unwrap(x), Currency.unwrap(y));
	}
}

contract CurrencyHarness {
	function approve(Currency currency, address spender, uint256 value, bool usePermit2) external {
		currency.approve(spender, value, usePermit2);
	}

	function transfer(Currency currency, address recipient, uint256 value) external payable {
		currency.transfer(recipient, value);
	}

	function transferFrom(Currency currency, address sender, address recipient, uint256 value) external payable {
		currency.transferFrom(sender, recipient, value);
	}

	function permit(
		Currency currency,
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable {
		currency.permit(owner, spender, value, deadline, v, r, s);
	}

	function allowance(Currency currency, address spender, bool usePermit2) external view returns (uint256) {
		return currency.allowance(address(this), spender, usePermit2);
	}

	function allowance(
		Currency currency,
		address owner,
		address spender,
		bool usePermit2
	) external view returns (uint256) {
		return currency.allowance(owner, spender, usePermit2);
	}

	function balanceOf(Currency currency, address owner) external view returns (uint256) {
		return currency.balanceOf(owner);
	}

	function balanceOfSelf(Currency currency) external view returns (uint256) {
		return currency.balanceOfSelf();
	}
}
