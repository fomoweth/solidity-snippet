// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC7914} from "src/interfaces/tokenization/IERC7914.sol";

/// @title ERC7914
/// @dev Modified from https://github.com/Uniswap/calibur/blob/main/src/ERC7914.sol
contract ERC7914 is IERC7914 {
	/// @notice Precomputed {ApproveNative} event signature for gas optimization
	/// @dev keccak256(bytes("ApproveNative(address,address,uint256)"))
	uint256 private constant APPROVE_NATIVE_EVENT_SIGNATURE =
		0x30346eac03b1c5913bb026e6d8d0f42783a0c706bb2a86916410dc385cc27236;

	/// @notice Precomputed {ApproveNativeTransient} event signature for gas optimization
	/// @dev keccak256(bytes("ApproveNativeTransient(address,address,uint256)"))
	uint256 private constant APPROVE_NATIVE_TRANSIENT_EVENT_SIGNATURE =
		0xf8c1385bb618a432aebbaae5bfab911559154982a64e1750b17b50f5782dc988;

	/// @notice Precomputed {NativeAllowanceUpdated} event signature for gas optimization
	/// @dev keccak256(bytes("NativeAllowanceUpdated(address,uint256)"))
	uint256 private constant NATIVE_ALLOWANCE_UPDATED_EVENT_SIGNATURE =
		0x85b16643b7d42712d1470a1ed9822d6e8cadad23eb1141cabefa28da0944c5b7;

	/// @notice Precomputed {TransferFromNative} event signature for gas optimization
	/// @dev keccak256(bytes("TransferFromNative(address,address,uint256)"))
	uint256 private constant TRANSFER_NATIVE_EVENT_SIGNATURE =
		0xed1cf8378e55f85e35be72eebdbef1b7347825916e51aa538d1855113f8c259d;

	/// @notice Precomputed {TransferFromNativeTransient} event signature for gas optimization
	/// @dev keccak256(bytes("TransferFromNativeTransient(address,address,uint256)"))
	uint256 private constant TRANSFER_NATIVE_TRANSIENT_EVENT_SIGNATURE =
		0x3f1beca043a9fe9118bbaeca0035e81e02d6d7cf184bf32fa9dfbd73fdd027c0;

	/// @notice Seed for computing allowance storage slots
	/// @dev uint32(bytes4(keccak256(bytes("ERC7914.storage.allowances"))))
	uint256 private constant ALLOWANCES_STORAGE_SLOT_SEED = 0x4e0318c1;

	/// @notice Seed for computing allowance transient storage slots
	/// @dev First 4 bytes of keccak256("ERC7914.transient.allowances") for collision resistance
	uint256 private constant ALLOWANCES_TRANSIENT_SLOT_SEED = 0x97bc48ae;

	/// @inheritdoc IERC7914
	function nativeAllowance(address spender) public view virtual returns (uint256 allowance) {
		assembly ("memory-safe") {
			// Compute native allowance storage slot using optimized packing:
			// Pack spender (shifted left 96 bits) with slot seed
			mstore(0x00, or(shl(0x60, spender), ALLOWANCES_STORAGE_SLOT_SEED))
			// Hash the 32-byte packed data
			allowance := sload(keccak256(0x00, 0x20))
		}
	}

	/// @inheritdoc IERC7914
	function transientNativeAllowance(address spender) public view virtual returns (uint256 allowance) {
		assembly ("memory-safe") {
			// Compute native allowance storage slot using optimized packing:
			// Pack spender (shifted left 96 bits) with slot seed
			// mstore(0x00, and(spender, 0xffffffffffffffffffffffffffffffffffffffff))
			mstore(0x00, or(shl(0x60, spender), ALLOWANCES_TRANSIENT_SLOT_SEED))
			// Hash the 32-byte packed data
			allowance := tload(keccak256(0x00, 0x20))
		}
	}

	/// @inheritdoc IERC7914
	function approveNative(address spender, uint256 value) public virtual returns (bool) {
		_approveNative(spender, value, false);
		return true;
	}

	/// @inheritdoc IERC7914
	function approveNativeTransient(address spender, uint256 value) public virtual returns (bool) {
		_approveNative(spender, value, true);
		return true;
	}

	/// @inheritdoc IERC7914
	function transferFromNative(address sender, address recipient, uint256 value) public virtual returns (bool) {
		_transferFromNative(sender, recipient, value, false);
		return true;
	}

	/// @inheritdoc IERC7914
	function transferFromNativeTransient(address sender, address recipient, uint256 value) public virtual returns (bool) {
		_transferFromNative(sender, recipient, value, true);
		return true;
	}

	function _approveNative(address spender, uint256 value, bool isTransient) internal virtual {
		assembly ("memory-safe") {
			if iszero(eq(caller(), address())) {
				mstore(0x00, 0x7d1c29f3) // IncorrectSender()
				revert(0x1c, 0x04)
			}

			spender := shr(0x60, shl(0x60, spender))
			mstore(0x20, value)

			switch isTransient
			case 0x00 {
				// Update allowance
				mstore(0x00, or(shl(0x60, spender), ALLOWANCES_STORAGE_SLOT_SEED))
				sstore(keccak256(0x00, 0x20), value)

				// Emit {ApproveNative} event
				log3(0x20, 0x20, APPROVE_NATIVE_EVENT_SIGNATURE, caller(), spender)
			}
			case 0x01 {
				// Update allowance
				mstore(0x00, or(shl(0x60, spender), ALLOWANCES_TRANSIENT_SLOT_SEED))
				tstore(keccak256(0x00, 0x20), value)

				// Emit {ApproveNativeTransient} event
				log3(0x20, 0x20, APPROVE_NATIVE_TRANSIENT_EVENT_SIGNATURE, caller(), spender)
			}
		}
	}

	/// @dev Internal function to validate and execute transfers
	/// @param sender The address to transfer from
	/// @param recipient The address to receive the funds
	/// @param value The amount to transfer
	/// @param isTransient Whether this is transient allowance or not
	function _transferFromNative(address sender, address recipient, uint256 value, bool isTransient) internal {
		if (value == 0) return;

		assembly ("memory-safe") {
			sender := shr(0x60, shl(0x60, sender))
			recipient := shr(0x60, shl(0x60, recipient))

			if iszero(eq(sender, address())) {
				mstore(0x00, 0x7d1c29f3) // IncorrectSender()
				revert(0x1c, 0x04)
			}

			let allowance
			let slot
			let topic

			switch isTransient
			case 0x00 {
				mstore(0x00, or(shl(0x60, caller()), ALLOWANCES_STORAGE_SLOT_SEED))
				slot := keccak256(0x00, 0x20)
				allowance := sload(slot)
				topic := TRANSFER_NATIVE_EVENT_SIGNATURE
			}
			case 0x01 {
				mstore(0x00, or(shl(0x60, caller()), ALLOWANCES_TRANSIENT_SLOT_SEED))
				slot := keccak256(0x00, 0x20)
				allowance := tload(slot)
				topic := TRANSFER_NATIVE_TRANSIENT_EVENT_SIGNATURE
			}

			// Update allowance
			if not(allowance) {
				// Check allowance
				if lt(allowance, value) {
					mstore(0x00, 0xc45cb513) // AllowanceExceeded()
					revert(0x1c, 0x04)
				}

				allowance := sub(allowance, value)

				switch isTransient
				case 0x00 {
					sstore(slot, allowance)

					// emit {NativeAllowanceUpdated} event
					mstore(0x00, allowance)
					log2(0x00, 0x20, NATIVE_ALLOWANCE_UPDATED_EVENT_SIGNATURE, caller())
				}
				case 0x01 {
					tstore(slot, allowance)
				}
			}

			// Execute transfer
			if iszero(call(gas(), recipient, value, 0x00, codesize(), 0x00, codesize())) {
				mstore(0x00, 0xb06a467a) // TransferNativeFailed()
				revert(0x1c, 0x04)
			}

			// Emit {TransferFromNative | TransferFromNativeTransient} event
			mstore(0x00, value)
			log3(0x00, 0x20, topic, sender, recipient)
		}
	}
}
