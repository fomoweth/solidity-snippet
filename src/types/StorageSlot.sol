// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

type AddressSlot is uint256;
type BooleanSlot is uint256;
type Bytes32Slot is uint256;
type Uint256Slot is uint256;
type Int256Slot is uint256;
type BytesSlot is uint256;
type StringSlot is uint256;

using StorageSlot for AddressSlot global;
using StorageSlot for BooleanSlot global;
using StorageSlot for Bytes32Slot global;
using StorageSlot for Uint256Slot global;
using StorageSlot for Int256Slot global;
using StorageSlot for BytesSlot global;
using StorageSlot for StringSlot global;

/// @title StorageSlot
/// @notice Library for reading and writing values to specific storage and transient storage slots
library StorageSlot {
	error InvalidDataLength();

	uint256 internal constant LENGTH_MASK = 0xffffffff;

	/// @notice Converts an arbitrary slot into a AddressSlot for type-safe operations
	function asAddressSlot(uint256 slot) internal pure returns (AddressSlot result) {
		return AddressSlot.wrap(slot);
	}

	/// @notice Converts a AddressSlot type back to its underlying uint256 value
	function asUint256(AddressSlot slot) internal pure returns (uint256 result) {
		return AddressSlot.unwrap(slot);
	}

	/// @notice Converts a AddressSlot type back to its underlying bytes32 value
	function asBytes32(AddressSlot slot) internal pure returns (bytes32 result) {
		return bytes32(AddressSlot.unwrap(slot));
	}

	function sload(AddressSlot slot) internal view returns (address result) {
		assembly ("memory-safe") {
			result := sload(slot)
		}
	}

	function sstore(AddressSlot slot, address value) internal {
		assembly ("memory-safe") {
			sstore(slot, shr(0x60, shl(0x60, value)))
		}
	}

	function tload(AddressSlot slot) internal view returns (address result) {
		assembly ("memory-safe") {
			result := tload(slot)
		}
	}

	function tstore(AddressSlot slot, address value) internal {
		assembly ("memory-safe") {
			tstore(slot, shr(0x60, shl(0x60, value)))
		}
	}

	/// @notice Converts an arbitrary slot into a BooleanSlot for type-safe operations
	function asBooleanSlot(uint256 slot) internal pure returns (BooleanSlot result) {
		return BooleanSlot.wrap(slot);
	}

	/// @notice Converts a BooleanSlot type back to its underlying uint256 value
	function asUint256(BooleanSlot slot) internal pure returns (uint256 result) {
		return BooleanSlot.unwrap(slot);
	}

	/// @notice Converts a BooleanSlot type back to its underlying bytes32 value
	function asBytes32(BooleanSlot slot) internal pure returns (bytes32 result) {
		return bytes32(BooleanSlot.unwrap(slot));
	}

	function sload(BooleanSlot slot) internal view returns (bool result) {
		assembly ("memory-safe") {
			result := sload(slot)
		}
	}

	function sstore(BooleanSlot slot, bool value) internal {
		assembly ("memory-safe") {
			sstore(slot, iszero(iszero(value)))
		}
	}

	function tload(BooleanSlot slot) internal view returns (bool result) {
		assembly ("memory-safe") {
			result := tload(slot)
		}
	}

	function tstore(BooleanSlot slot, bool value) internal {
		assembly ("memory-safe") {
			tstore(slot, iszero(iszero(value)))
		}
	}

	/// @notice Converts an arbitrary slot into a Bytes32Slot for type-safe operations
	function asBytes32Slot(uint256 slot) internal pure returns (Bytes32Slot result) {
		return Bytes32Slot.wrap(slot);
	}

	/// @notice Converts a Bytes32Slot type back to its underlying uint256 value
	function asUint256(Bytes32Slot slot) internal pure returns (uint256 result) {
		return Bytes32Slot.unwrap(slot);
	}

	/// @notice Converts a Bytes32Slot type back to its underlying bytes32 value
	function asBytes32(Bytes32Slot slot) internal pure returns (bytes32 result) {
		return bytes32(Bytes32Slot.unwrap(slot));
	}

	function sload(Bytes32Slot slot) internal view returns (bytes32 result) {
		assembly ("memory-safe") {
			result := sload(slot)
		}
	}

	function sstore(Bytes32Slot slot, bytes32 value) internal {
		assembly ("memory-safe") {
			sstore(slot, value)
		}
	}

	function tload(Bytes32Slot slot) internal view returns (bytes32 result) {
		assembly ("memory-safe") {
			result := tload(slot)
		}
	}

	function tstore(Bytes32Slot slot, bytes32 value) internal {
		assembly ("memory-safe") {
			tstore(slot, value)
		}
	}

	/// @notice Converts an arbitrary slot into a Uint256Slot for type-safe operations
	function asUint256Slot(uint256 slot) internal pure returns (Uint256Slot result) {
		return Uint256Slot.wrap(slot);
	}

	/// @notice Converts a Uint256Slot type back to its underlying uint256 value
	function asUint256(Uint256Slot slot) internal pure returns (uint256 result) {
		return Uint256Slot.unwrap(slot);
	}

	/// @notice Converts a Uint256Slot type back to its underlying bytes32 value
	function asBytes32(Uint256Slot slot) internal pure returns (bytes32 result) {
		return bytes32(Uint256Slot.unwrap(slot));
	}

	function sload(Uint256Slot slot) internal view returns (uint256 result) {
		assembly ("memory-safe") {
			result := sload(slot)
		}
	}

	function sstore(Uint256Slot slot, uint256 value) internal {
		assembly ("memory-safe") {
			sstore(slot, value)
		}
	}

	function tload(Uint256Slot slot) internal view returns (uint256 result) {
		assembly ("memory-safe") {
			result := tload(slot)
		}
	}

	function tstore(Uint256Slot slot, uint256 value) internal {
		assembly ("memory-safe") {
			tstore(slot, value)
		}
	}

	/// @notice Converts an arbitrary slot into a Int256Slot for type-safe operations
	function asInt256Slot(uint256 slot) internal pure returns (Int256Slot result) {
		return Int256Slot.wrap(slot);
	}

	/// @notice Converts a Int256Slot type back to its underlying uint256 value
	function asUint256(Int256Slot slot) internal pure returns (uint256 result) {
		return Int256Slot.unwrap(slot);
	}

	/// @notice Converts a Int256Slot type back to its underlying bytes32 value
	function asBytes32(Int256Slot slot) internal pure returns (bytes32 result) {
		return bytes32(Int256Slot.unwrap(slot));
	}

	function sload(Int256Slot slot) internal view returns (int256 result) {
		assembly ("memory-safe") {
			result := sload(slot)
		}
	}

	function sstore(Int256Slot slot, int256 value) internal {
		assembly ("memory-safe") {
			sstore(slot, value)
		}
	}

	function tload(Int256Slot slot) internal view returns (int256 result) {
		assembly ("memory-safe") {
			result := tload(slot)
		}
	}

	function tstore(Int256Slot slot, int256 value) internal {
		assembly ("memory-safe") {
			tstore(slot, value)
		}
	}

	/// @notice Converts an arbitrary slot into a BytesSlot for type-safe operations
	function asBytesSlot(uint256 slot) internal pure returns (BytesSlot result) {
		return BytesSlot.wrap(slot);
	}

	/// @notice Converts a BytesSlot type back to its underlying uint256 value
	function asUint256(BytesSlot slot) internal pure returns (uint256 result) {
		return BytesSlot.unwrap(slot);
	}

	/// @notice Converts a BytesSlot type back to its underlying bytes32 value
	function asBytes32(BytesSlot slot) internal pure returns (bytes32 result) {
		return bytes32(BytesSlot.unwrap(slot));
	}

	function slength(BytesSlot slot) internal view returns (uint256 length) {
		assembly ("memory-safe") {
			length := shr(0xe0, sload(slot))
		}
	}

	function sload(BytesSlot slot) internal view returns (bytes memory result) {
		assembly ("memory-safe") {
			result := mload(0x40)
			mstore(result, 0x00)
			mstore(add(result, 0x1c), sload(slot))

			let length := mload(result)
			let offset := add(result, 0x20)
			let guard := add(offset, length)
			mstore(0x40, guard)

			if gt(length, 0x1c) {
				mstore(0x00, slot)
				slot := keccak256(0x00, 0x20)
				offset := add(offset, 0x1c)

				// prettier-ignore
				for {} 0x01 {} {
					mstore(offset, sload(slot))
					offset := add(offset, 0x20)
					if gt(offset, guard) { break }
					slot := add(slot, 0x01)
				}

				mstore(guard, 0x00)
			}
		}
	}

	function sstore(BytesSlot slot, bytes memory value) internal {
		assembly ("memory-safe") {
			let length := mload(value)
			if gt(length, LENGTH_MASK) {
				mstore(0x00, 0xdfe93090) // InvalidDataLength()
				revert(0x1c, 0x04)
			}

			let offset := add(value, 0x20)
			sstore(slot, mload(sub(offset, 0x04)))

			if gt(length, 0x1c) {
				mstore(0x00, slot)
				slot := keccak256(0x00, 0x20)

				let guard := sub(add(offset, length), 0x01)
				offset := add(offset, 0x1c)

				// prettier-ignore
				for {} 0x01 {} {
					sstore(slot, mload(offset))
					offset := add(offset, 0x20)
					if gt(offset, guard) { break }
					slot := add(slot, 0x01)
				}
			}
		}
	}

	function tlength(BytesSlot slot) internal view returns (uint256 length) {
		assembly ("memory-safe") {
			length := shr(0xe0, tload(slot))
		}
	}

	function tload(BytesSlot slot) internal view returns (bytes memory result) {
		assembly ("memory-safe") {
			result := mload(0x40)
			mstore(result, 0x00)
			mstore(add(result, 0x1c), tload(slot))

			let length := mload(result)
			let offset := add(result, 0x20)
			let guard := add(offset, length)
			mstore(0x40, guard)

			if gt(length, 0x1c) {
				mstore(0x00, slot)
				slot := keccak256(0x00, 0x20)
				offset := add(offset, 0x1c)

				// prettier-ignore
				for {} 0x01 {} {
					mstore(offset, tload(slot))
					offset := add(offset, 0x20)
					if gt(offset, guard) { break }
					slot := add(slot, 0x01)
				}

				mstore(guard, 0x00)
			}
		}
	}

	function tstore(BytesSlot slot, bytes memory value) internal {
		assembly ("memory-safe") {
			let length := mload(value)
			if gt(length, LENGTH_MASK) {
				mstore(0x00, 0xdfe93090) // InvalidDataLength()
				revert(0x1c, 0x04)
			}

			let offset := add(value, 0x20)
			tstore(slot, mload(sub(offset, 0x04)))

			if gt(length, 0x1c) {
				mstore(0x00, slot)
				slot := keccak256(0x00, 0x20)

				let guard := sub(add(offset, length), 0x01)
				offset := add(offset, 0x1c)

				// prettier-ignore
				for {} 0x01 {} {
					tstore(slot, mload(offset))
					offset := add(offset, 0x20)
					if gt(offset, guard) { break }
					slot := add(slot, 0x01)
				}
			}
		}
	}

	/// @notice Converts an arbitrary slot into a StringSlot for type-safe operations
	function asStringSlot(uint256 slot) internal pure returns (StringSlot result) {
		return StringSlot.wrap(slot);
	}

	/// @notice Converts a StringSlot type back to its underlying uint256 value
	function asUint256(StringSlot slot) internal pure returns (uint256 result) {
		return StringSlot.unwrap(slot);
	}

	/// @notice Converts a StringSlot type back to its underlying bytes32 value
	function asBytes32(StringSlot slot) internal pure returns (bytes32 result) {
		return bytes32(StringSlot.unwrap(slot));
	}

	function slength(StringSlot slot) internal view returns (uint256 length) {
		assembly ("memory-safe") {
			length := shr(0xe0, sload(slot))
		}
	}

	function sload(StringSlot slot) internal view returns (string memory result) {
		assembly ("memory-safe") {
			result := mload(0x40)
			mstore(result, 0x00)
			mstore(add(result, 0x1c), sload(slot))

			let length := mload(result)
			let offset := add(result, 0x20)
			let guard := add(offset, length)
			mstore(0x40, guard)

			if gt(length, 0x1c) {
				mstore(0x00, slot)
				slot := keccak256(0x00, 0x20)
				offset := add(offset, 0x1c)

				// prettier-ignore
				for {} 0x01 {} {
					mstore(offset, sload(slot))
					offset := add(offset, 0x20)
					if gt(offset, guard) { break }
					slot := add(slot, 0x01)
				}

				mstore(guard, 0x00)
			}
		}
	}

	function sstore(StringSlot slot, string memory value) internal {
		assembly ("memory-safe") {
			let length := mload(value)
			if gt(length, LENGTH_MASK) {
				mstore(0x00, 0xdfe93090) // InvalidDataLength()
				revert(0x1c, 0x04)
			}

			let offset := add(value, 0x20)
			sstore(slot, mload(sub(offset, 0x04)))

			if gt(length, 0x1c) {
				mstore(0x00, slot)
				slot := keccak256(0x00, 0x20)

				let guard := sub(add(offset, length), 0x01)
				offset := add(offset, 0x1c)

				// prettier-ignore
				for {} 0x01 {} {
					sstore(slot, mload(offset))
					offset := add(offset, 0x20)
					if gt(offset, guard) { break }
					slot := add(slot, 0x01)
				}
			}
		}
	}

	function tlength(StringSlot slot) internal view returns (uint256 length) {
		assembly ("memory-safe") {
			length := shr(0xe0, tload(slot))
		}
	}

	function tload(StringSlot slot) internal view returns (string memory result) {
		assembly ("memory-safe") {
			result := mload(0x40)
			mstore(result, 0x00)
			mstore(add(result, 0x1c), tload(slot))

			let length := mload(result)
			let offset := add(result, 0x20)
			let guard := add(offset, length)
			mstore(0x40, guard)

			if gt(length, 0x1c) {
				mstore(0x00, slot)
				slot := keccak256(0x00, 0x20)
				offset := add(offset, 0x1c)

				// prettier-ignore
				for {} 0x01 {} {
					mstore(offset, tload(slot))
					offset := add(offset, 0x20)
					if gt(offset, guard) { break }
					slot := add(slot, 0x01)
				}

				mstore(guard, 0x00)
			}
		}
	}

	function tstore(StringSlot slot, string memory value) internal {
		assembly ("memory-safe") {
			let length := mload(value)
			if gt(length, LENGTH_MASK) {
				mstore(0x00, 0xdfe93090) // InvalidDataLength()
				revert(0x1c, 0x04)
			}

			let offset := add(value, 0x20)
			tstore(slot, mload(sub(offset, 0x04)))

			if gt(length, 0x1c) {
				mstore(0x00, slot)
				slot := keccak256(0x00, 0x20)

				let guard := sub(add(offset, length), 0x01)
				offset := add(offset, 0x1c)

				// prettier-ignore
				for {} 0x01 {} {
					tstore(slot, mload(offset))
					offset := add(offset, 0x20)
					if gt(offset, guard) { break }
					slot := add(slot, 0x01)
				}
			}
		}
	}
}
