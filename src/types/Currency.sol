// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

type Currency is address;

using {eq as ==, neq as !=, gt as >, gte as >=, lt as <, lte as <=} for Currency global;
using CurrencyLibrary for Currency global;

function eq(Currency x, Currency y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := eq(x, y)
	}
}

function neq(Currency x, Currency y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := iszero(eq(x, y))
	}
}

function gt(Currency x, Currency y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := gt(x, y)
	}
}

function gte(Currency x, Currency y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := iszero(lt(x, y))
	}
}

function lt(Currency x, Currency y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := lt(x, y)
	}
}

function lte(Currency x, Currency y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := iszero(gt(x, y))
	}
}

/// @title CurrencyLibrary
/// @notice Utility library for ERC-20 interactions with the {Currency} type
/// @dev Modified from https://github.com/Uniswap/v4-core/blob/main/src/types/Currency.sol
/// @dev Reference: https://github.com/Vectorized/solady/blob/main/src/utils/SafeTransferLib.sol
library CurrencyLibrary {
	error InvalidCurrency();

	error AmountOverflow();

	error ApprovalFailed();

	error LockdownFailed();

	error PermitFailed();

	error TransferFailed();

	error TransferNativeFailed();

	error TransferFromFailed();

	error TransferFromNativeFailed();

	error DecimalsQueryFailed();

	error NonceQueryFailed();

	error TotalSupplyQueryFailed();

	bytes32 private constant DAI_DOMAIN_SEPARATOR = 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

	address private constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

	address internal constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	Currency internal constant NATIVE = Currency.wrap(NATIVE_ADDRESS);

	Currency internal constant ZERO = Currency.wrap(address(0));

	function approve(Currency currency, address spender, uint256 value) internal {
		approve(currency, spender, value, false);
	}

	function approve(Currency currency, address spender, uint256 value, bool usePermit2) internal {
		assembly ("memory-safe") {
			if extcodesize(currency) {
				switch usePermit2
				case 0x00 {
					mstore(0x00, 0x095ea7b3000000000000000000000000) // approve(address,uint256)
					mstore(0x14, spender)
					mstore(0x34, value)

					if iszero(
						and(
							or(eq(mload(0x00), 0x01), iszero(returndatasize())),
							call(gas(), currency, 0x00, 0x10, 0x44, 0x00, 0x20)
						)
					) {
						mstore(0x34, 0x00)
						pop(call(gas(), currency, 0x00, 0x10, 0x44, codesize(), 0x00))
						mstore(0x34, value)

						if iszero(
							and(
								or(eq(mload(0x00), 0x01), iszero(returndatasize())),
								call(gas(), currency, 0x00, 0x10, 0x44, 0x00, 0x20)
							)
						) {
							mstore(0x00, 0x8164f842) // ApprovalFailed()
							revert(0x1c, 0x04)
						}
					}

					mstore(0x34, 0x00)
				}
				default {
					let ptr := mload(0x40)

					switch value
					case 0x00 {
						mstore(ptr, 0xcc53287f) // lockdown((address,address)[])
						mstore(add(ptr, 0x20), 0x20)
						mstore(add(ptr, 0x40), 0x01)
						mstore(add(ptr, 0x60), currency)
						mstore(add(ptr, 0x80), spender)
					}
					default {
						mstore(ptr, 0x87517c45) // approve(address,address,uint160,uint48)
						mstore(add(ptr, 0x20), currency)
						mstore(add(ptr, 0x40), spender)
						mstore(add(ptr, 0x60), and(value, 0xffffffffffffffffffffffffffffffffffffffff))
						mstore(add(ptr, 0x80), and(shr(0xa0, value), 0xffffffffffff))
					}

					if iszero(call(gas(), PERMIT2, 0x00, add(ptr, 0x1c), 0x84, codesize(), 0x00)) {
						mstore(0x00, 0x8164f8423e3492b4) // ApprovalFailed() or LockdownFailed()
						revert(add(0x18, shl(0x02, iszero(value))), 0x04)
					}
				}
			}
		}
	}

	function transfer(Currency currency, address recipient, uint256 value) internal {
		assembly ("memory-safe") {
			switch iszero(extcodesize(currency))
			case 0x00 {
				mstore(0x00, 0xa9059cbb000000000000000000000000) // transfer(address,uint256)
				mstore(0x14, recipient)
				mstore(0x34, value)

				if iszero(
					and(
						or(eq(mload(0x00), 0x01), iszero(returndatasize())),
						call(gas(), currency, 0x00, 0x10, 0x44, 0x00, 0x20)
					)
				) {
					mstore(0x00, 0x90b8ec18) // TransferFailed()
					revert(0x1c, 0x04)
				}

				mstore(0x34, 0x00)
			}
			default {
				if iszero(call(gas(), recipient, value, codesize(), 0x00, codesize(), 0x00)) {
					mstore(0x00, 0xb06a467a) // TransferNativeFailed()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	function transferFrom(Currency currency, address sender, address recipient, uint256 value) internal {
		assembly ("memory-safe") {
			switch iszero(extcodesize(currency))
			case 0x00 {
				let ptr := mload(0x40)
				mstore(ptr, 0x23b872dd) // transferFrom(address,address,uint256)
				mstore(add(ptr, 0x20), sender)
				mstore(add(ptr, 0x40), recipient)
				mstore(add(ptr, 0x60), value)

				if iszero(
					and(
						or(eq(mload(0x00), 0x01), iszero(returndatasize())),
						call(gas(), currency, 0x00, add(ptr, 0x1c), 0x64, 0x00, 0x20)
					)
				) {
					if shr(0xa0, value) {
						mstore(0x00, 0x0590fb9f) // AmountOverflow()
						revert(0x1c, 0x04)
					}

					mstore(ptr, 0x36c78516) // transferFrom(address,address,uint160,address)
					mstore(add(ptr, 0x80), currency)

					if iszero(call(gas(), PERMIT2, 0x00, add(ptr, 0x1c), 0x84, codesize(), 0x00)) {
						mstore(0x00, 0x7939f424) // TransferFromFailed()
						revert(0x1c, 0x04)
					}
				}
			}
			default {
				if or(lt(callvalue(), value), or(iszero(eq(sender, caller())), iszero(eq(recipient, address())))) {
					mstore(0x00, 0xa20c5180) // TransferFromNativeFailed()
					revert(0x1c, 0x04)
				}
			}
		}
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
	) internal {
		assembly ("memory-safe") {
			if iszero(extcodesize(currency)) {
				mstore(0x00, 0xf5993428) // InvalidCurrency()
				revert(0x1c, 0x04)
			}

			let ptr := mload(0x40)
			let success

			mstore(0x00, 0x3644e515) // DOMAIN_SEPARATOR()

			if and(
				and(iszero(iszero(mload(0x00))), eq(returndatasize(), 0x20)),
				staticcall(5000, currency, 0x1c, 0x04, 0x00, 0x20)
			) {
				mstore(add(ptr, 0x20), owner)
				mstore(add(ptr, 0x40), spender)
				mstore(add(ptr, 0x80), deadline)

				switch eq(mload(0x00), DAI_DOMAIN_SEPARATOR)
				case 0x01 {
					mstore(ptr, 0x7ecebe00) // nonces(address)
					pop(staticcall(gas(), currency, add(ptr, 0x1c), 0x24, add(ptr, 0x60), 0x20))

					mstore(ptr, 0x8fcbaf0c) // permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32)
					mstore(add(ptr, 0xa0), iszero(iszero(value)))
					mstore(add(ptr, 0xc0), and(0xff, v))
					mstore(add(ptr, 0xe0), r)
					mstore(add(ptr, 0x100), s)
					success := call(gas(), currency, 0x00, add(ptr, 0x1c), 0x104, codesize(), 0x00)
				}
				default {
					mstore(ptr, 0xd505accf) // permit(address,address,uint256,uint256,uint8,bytes32,bytes32)
					mstore(add(ptr, 0x60), value)
					mstore(add(ptr, 0xa0), and(0xff, v))
					mstore(add(ptr, 0xc0), r)
					mstore(add(ptr, 0xe0), s)
					success := call(gas(), currency, 0x00, add(ptr, 0x1c), 0xe4, codesize(), 0x00)
				}
			}

			if iszero(success) {
				if shr(0xa0, value) {
					mstore(0x00, 0x0590fb9f) // AmountOverflow()
					revert(0x1c, 0x04)
				}

				mstore(ptr, 0x927da105) // allowance(address,address,address)
				mstore(add(ptr, 0x20), owner)
				mstore(add(ptr, 0x40), currency)
				mstore(add(ptr, 0x60), spender)

				if iszero(staticcall(gas(), PERMIT2, add(ptr, 0x1c), 0x64, add(ptr, 0x60), 0x60)) {
					mstore(0x00, 0xb78cb0dd) // PermitFailed()
					revert(0x1c, 0x04)
				}

				mstore(ptr, 0x2b67b570) // permit(address,((address,uint160,uint48,uint48),address,uint256),bytes)
				mstore(add(ptr, 0x60), value)
				mstore(add(ptr, 0x80), 0xffffffffffff)
				mstore(add(ptr, 0xc0), spender)
				mstore(add(ptr, 0xe0), deadline)
				mstore(add(ptr, 0x100), 0x100)
				mstore(add(ptr, 0x120), 0x41)
				mstore(add(ptr, 0x140), r)
				mstore(add(ptr, 0x160), s)
				mstore(add(ptr, 0x180), shl(0xf8, v))

				if iszero(call(gas(), PERMIT2, 0x00, add(ptr, 0x1c), 0x184, codesize(), 0x00)) {
					mstore(0x00, 0xb78cb0dd) // PermitFailed()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	function allowance(
		Currency currency,
		address owner,
		address spender,
		bool usePermit2
	) internal view returns (uint256 result) {
		assembly ("memory-safe") {
			switch iszero(extcodesize(currency))
			case 0x00 {
				switch usePermit2
				case 0x00 {
					mstore(0x00, 0xdd62ed3e000000000000000000000000) // allowance(address,address)
					mstore(0x14, owner)
					mstore(0x34, spender)

					result := mul(
						mload(0x20),
						and(gt(returndatasize(), 0x1f), staticcall(gas(), currency, 0x10, 0x44, 0x20, 0x20))
					)

					mstore(0x34, 0x00)
				}
				default {
					let ptr := mload(0x40)
					mstore(0x0c, 0x927da105000000000000000000000000) // allowance(address,address,address)
					mstore(0x2c, shl(0x60, owner))
					mstore(0x40, currency)
					mstore(0x60, spender)

					if iszero(and(gt(returndatasize(), 0x5f), staticcall(gas(), PERMIT2, 0x1c, 0x64, 0x00, 0x60))) {
						returndatacopy(ptr, 0x00, returndatasize())
						revert(ptr, returndatasize())
					}

					result := or(or(shl(0xd0, mload(0x40)), shl(0xa0, mload(0x20))), mload(0x00))

					mstore(0x40, ptr)
					mstore(0x60, 0x00)
				}
			}
			default {
				result := not(0x00)
			}
		}
	}

	function balanceOf(Currency currency, address account) internal view returns (uint256 result) {
		assembly ("memory-safe") {
			switch iszero(extcodesize(currency))
			case 0x00 {
				mstore(0x00, 0x70a08231000000000000000000000000) // balanceOf(address)
				mstore(0x14, account)

				result := mul(
					mload(0x20),
					and(gt(returndatasize(), 0x1f), staticcall(gas(), currency, 0x10, 0x24, 0x20, 0x20))
				)
			}
			default {
				result := balance(account)
			}
		}
	}

	function balanceOfSelf(Currency currency) internal view returns (uint256 result) {
		assembly ("memory-safe") {
			switch iszero(extcodesize(currency))
			case 0x00 {
				mstore(0x00, 0x70a08231000000000000000000000000) // balanceOf(address)
				mstore(0x14, address())

				result := mul(
					mload(0x20),
					and(gt(returndatasize(), 0x1f), staticcall(gas(), currency, 0x10, 0x24, 0x20, 0x20))
				)
			}
			default {
				result := selfbalance()
			}
		}
	}

	function nonces(Currency currency, address account) internal view returns (uint256 result) {
		assembly ("memory-safe") {
			if iszero(extcodesize(currency)) {
				mstore(0x00, 0xf5993428) // InvalidCurrency()
				revert(0x1c, 0x04)
			}

			mstore(0x00, 0x7ecebe00000000000000000000000000) // nonces(address)
			mstore(0x14, account)

			if iszero(and(gt(returndatasize(), 0x1f), staticcall(gas(), currency, 0x10, 0x24, 0x20, 0x20))) {
				mstore(0x00, 0xb6abcf59) // NonceQueryFailed()
				revert(0x1c, 0x04)
			}

			result := mload(0x20)
		}
	}

	function decimals(Currency currency) internal view returns (uint8 result) {
		assembly ("memory-safe") {
			switch iszero(extcodesize(currency))
			case 0x00 {
				mstore(0x00, 0x313ce567) // decimals()

				if iszero(and(gt(returndatasize(), 0x1f), staticcall(gas(), currency, 0x1c, 0x04, 0x00, 0x20))) {
					mstore(0x00, 0x1eecbb65) // DecimalsQueryFailed()
					revert(0x1c, 0x04)
				}

				result := mload(0x00)
			}
			default {
				result := 18
			}
		}
	}

	function totalSupply(Currency currency) internal view returns (uint256 result) {
		assembly ("memory-safe") {
			if iszero(extcodesize(currency)) {
				mstore(0x00, 0xf5993428) // InvalidCurrency()
				revert(0x1c, 0x04)
			}

			mstore(0x00, 0x18160ddd) // totalSupply()

			if iszero(and(gt(returndatasize(), 0x1f), staticcall(gas(), currency, 0x1c, 0x04, 0x00, 0x20))) {
				mstore(0x00, 0x54cd9435) // TotalSupplyQueryFailed()
				revert(0x1c, 0x04)
			}

			result := mload(0x00)
		}
	}

	function isNative(Currency currency) internal pure returns (bool result) {
		assembly ("memory-safe") {
			result := or(iszero(shl(0x60, currency)), eq(currency, NATIVE_ADDRESS))
		}
	}

	function isZero(Currency currency) internal pure returns (bool result) {
		assembly ("memory-safe") {
			result := iszero(shl(0x60, currency))
		}
	}

	function toAddress(Currency currency) internal pure returns (address) {
		return Currency.unwrap(currency);
	}

	function toId(Currency currency) internal pure returns (uint256 id) {
		assembly ("memory-safe") {
			id := shr(0x60, shl(0x60, currency))
		}
	}

	function fromId(uint256 id) internal pure returns (Currency currency) {
		assembly ("memory-safe") {
			currency := id
		}
	}
}
