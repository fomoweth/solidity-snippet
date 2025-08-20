// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Brutalizer
/// @dev Implementation from https://github.com/Vectorized/solady/blob/main/test/utils/Brutalizer.sol
abstract contract Brutalizer {
	error InsufficientMemoryAllocation();
	error MemoryPointerOverflowed();
	error ZeroNotRightPadded();
	error ZeroSlotIsNotZero();

	/// @dev Multiplier for a mulmod Lehmer pseudorandom number generator
	/// Prime, and a primitive root of `LPRNG_MODULO`
	uint256 private constant LPRNG_MULTIPLIER = 0x100000000000000000000000000000051;

	/// @dev Modulo for a mulmod Lehmer pseudorandom number generator (prime)
	uint256 private constant LPRNG_MODULO = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff43;

	/// @dev Fills the memory with junk, for more robust testing of inline assembly which reads/write to the memory
	modifier brutalizerMemory() {
		brutalizeMemory();
		_;
		checkMemory();
	}

	/// @dev Fills the scratch space with junk, for more robust testing of inline assembly which reads/write to the memory
	modifier brutalizerScratchSpace() {
		brutalizeScratchSpace();
		_;
		checkMemory();
	}

	/// @dev Fills the lower memory with junk, for more robust testing of inline assembly which reads/write to the memory
	modifier brutalizerLowerMemory() {
		brutalizeLowerMemory();
		_;
		checkMemory();
	}

	/// @dev Wraps a functions such that allocated memory will be freed at the end of its scope.
	modifier tempMemory() {
		uint256 ptr = freeMemoryPointer();
		_;
		setFreeMemoryPointer(ptr);
	}

	/// @dev Fills the memory with junk, for more robust testing of inline assembly which reads/write to the memory
	function brutalizeMemory() internal view {
		// To prevent a solidity 0.8.13 bug
		// See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
		// Basically, we need to access a solidity variable from the assembly to tell the compiler that this assembly block is not in isolation
		uint256 zero;
		assembly ("memory-safe") {
			let offset := mload(0x40) // Start the offset at the free memory pointer
			calldatacopy(add(offset, 0x20), zero, calldatasize())
			mstore(offset, add(caller(), gas()))

			// Fill the 64 bytes of scratch space with garbage
			let r := keccak256(offset, add(calldatasize(), 0x40))
			mstore(zero, r)
			mstore(0x20, keccak256(zero, 0x40))
			r := mulmod(mload(0x10), LPRNG_MULTIPLIER, LPRNG_MODULO)

			let cSize := add(codesize(), iszero(codesize()))
			if iszero(lt(cSize, 0x20)) {
				cSize := sub(cSize, and(mload(0x02), 0x1f))
			}
			let start := mod(mload(0x10), cSize)
			let size := mul(sub(cSize, start), gt(cSize, start))
			let times := div(0x7ffff, cSize)
			if iszero(lt(times, 0x80)) {
				times := 0x80
			}

			// Occasionally offset the offset by a pseudorandom large amount
			// Can't be too large, or we will easily get out-of-gas errors
			offset := add(offset, mul(iszero(and(r, 0xf00000000)), and(shr(0x40, r), 0xfffff)))

			// Fill the free memory with garbage
			// prettier-ignore
			for { let w := not(0x00) } 0x01 {} {
                mstore(offset, mload(0x00))
                mstore(add(offset, 0x20), mload(0x20))
                offset := add(offset, 0x40)
                // We use codecopy instead of the identity precompile to avoid polluting the `forge test -vvvv` output with tons of junk
                codecopy(offset, start, size)
                codecopy(add(offset, size), 0x00, start)
                offset := add(offset, cSize)
                times := add(times, w) // sub(times, 1)
                if iszero(times) { break }
            }

			// With a 1/16 chance, copy the contract's code to the scratch space
			if iszero(and(0xf00, r)) {
				codecopy(0x00, mod(shr(0x80, r), add(codesize(), codesize())), 0x40)
				mstore8(and(r, 0x3f), iszero(and(0x100000, r)))
			}
		}
	}

	/// @dev Fills the scratch space with junk, for more robust testing of inline assembly which reads/write to the memory
	function brutalizeScratchSpace() internal view {
		// To prevent a solidity 0.8.13 bug
		// See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
		// Basically, we need to access a solidity variable from the assembly to tell the compiler that this assembly block is not in isolation
		uint256 zero;
		assembly ("memory-safe") {
			let offset := mload(0x40) // Start the offset at the free memory pointer
			calldatacopy(add(offset, 0x20), zero, calldatasize())
			mstore(offset, add(caller(), gas()))

			// Fill the 64 bytes of scratch space with garbage
			let r := keccak256(offset, add(calldatasize(), 0x40))
			mstore(zero, r)
			mstore(0x20, keccak256(zero, 0x40))
			r := mulmod(mload(0x10), LPRNG_MULTIPLIER, LPRNG_MODULO)
			if iszero(and(0xf00, r)) {
				codecopy(0x00, mod(shr(0x80, r), add(codesize(), codesize())), 0x40)
				mstore8(and(r, 0x3f), iszero(and(0x100000, r)))
			}
		}
	}

	/// @dev Fills the lower memory with junk, for more robust testing of inline assembly which reads/write to the memory
	/// For efficiency, this only fills a small portion of the free memory
	function brutalizeLowerMemory() internal view {
		// To prevent a solidity 0.8.13 bug
		// See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
		// Basically, we need to access a solidity variable from the assembly to tell the compiler that this assembly block is not in isolation
		uint256 zero;
		assembly ("memory-safe") {
			let offset := mload(0x40) // Start the offset at the free memory pointer
			calldatacopy(add(offset, 0x20), zero, calldatasize())
			mstore(offset, add(caller(), gas()))

			// Fill the 64 bytes of scratch space with garbage
			let r := keccak256(offset, add(calldatasize(), 0x40))
			mstore(zero, r)
			mstore(0x20, keccak256(zero, 0x40))
			r := mulmod(mload(0x10), LPRNG_MULTIPLIER, LPRNG_MODULO)

			// prettier-ignore
			for {} 0x01 {} {
				if iszero(and(0x7000, r)) {
					let x := keccak256(zero, 0x40)
					mstore(offset, x)
					mstore(add(0x20, offset), x)
					mstore(add(0x40, offset), x)
					mstore(add(0x60, offset), x)
					mstore(add(0x80, offset), x)
					mstore(add(0xa0, offset), x)
					mstore(add(0xc0, offset), x)
					mstore(add(0xe0, offset), x)
					mstore(add(0x100, offset), x)
					mstore(add(0x120, offset), x)
					mstore(add(0x140, offset), x)
					mstore(add(0x160, offset), x)
					mstore(add(0x180, offset), x)
					mstore(add(0x1a0, offset), x)
					mstore(add(0x1c0, offset), x)
					mstore(add(0x1e0, offset), x)
					mstore(add(0x200, offset), x)
					mstore(add(0x220, offset), x)
					mstore(add(0x240, offset), x)
					mstore(add(0x260, offset), x)
					break
				}
				codecopy(offset, byte(0x00, r), codesize())
				break
			}

			if iszero(and(0x300, r)) {
				codecopy(0x00, mod(shr(0x80, r), add(codesize(), codesize())), 0x40)
				mstore8(and(r, 0x3f), iszero(and(0x100000, r)))
			}
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalized(address value) internal pure returns (address result) {
		uint256 r = uint256(uint160(value));
		r = (_brutalizerRandomness(r) << 160) ^ r;
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint8(uint8 value) internal pure returns (uint8 result) {
		uint256 r = (_brutalizerRandomness(value) << 8) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes1(bytes1 value) internal pure returns (bytes1 result) {
		bytes32 r = _brutalizedBytesN(value, 8);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint16(uint16 value) internal pure returns (uint16 result) {
		uint256 r = (_brutalizerRandomness(value) << 16) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes2(bytes2 value) internal pure returns (bytes2 result) {
		bytes32 r = _brutalizedBytesN(value, 16);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint24(uint24 value) internal pure returns (uint24 result) {
		uint256 r = (_brutalizerRandomness(value) << 24) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes3(bytes3 value) internal pure returns (bytes3 result) {
		bytes32 r = _brutalizedBytesN(value, 24);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint32(uint32 value) internal pure returns (uint32 result) {
		uint256 r = (_brutalizerRandomness(value) << 32) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes4(bytes4 value) internal pure returns (bytes4 result) {
		bytes32 r = _brutalizedBytesN(value, 32);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint40(uint40 value) internal pure returns (uint40 result) {
		uint256 r = (_brutalizerRandomness(value) << 40) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes5(bytes5 value) internal pure returns (bytes5 result) {
		bytes32 r = _brutalizedBytesN(value, 40);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint48(uint48 value) internal pure returns (uint48 result) {
		uint256 r = (_brutalizerRandomness(value) << 48) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes6(bytes6 value) internal pure returns (bytes6 result) {
		bytes32 r = _brutalizedBytesN(value, 48);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint56(uint56 value) internal pure returns (uint56 result) {
		uint256 r = (_brutalizerRandomness(value) << 56) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes7(bytes7 value) internal pure returns (bytes7 result) {
		bytes32 r = _brutalizedBytesN(value, 56);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint64(uint64 value) internal pure returns (uint64 result) {
		uint256 r = (_brutalizerRandomness(value) << 64) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes8(bytes8 value) internal pure returns (bytes8 result) {
		bytes32 r = _brutalizedBytesN(value, 64);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint72(uint72 value) internal pure returns (uint72 result) {
		uint256 r = (_brutalizerRandomness(value) << 72) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes9(bytes9 value) internal pure returns (bytes9 result) {
		bytes32 r = _brutalizedBytesN(value, 72);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint80(uint80 value) internal pure returns (uint80 result) {
		uint256 r = (_brutalizerRandomness(value) << 80) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes10(bytes10 value) internal pure returns (bytes10 result) {
		bytes32 r = _brutalizedBytesN(value, 80);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint88(uint88 value) internal pure returns (uint88 result) {
		uint256 r = (_brutalizerRandomness(value) << 88) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes11(bytes11 value) internal pure returns (bytes11 result) {
		bytes32 r = _brutalizedBytesN(value, 88);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint96(uint96 value) internal pure returns (uint96 result) {
		uint256 r = (_brutalizerRandomness(value) << 96) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes12(bytes12 value) internal pure returns (bytes12 result) {
		bytes32 r = _brutalizedBytesN(value, 96);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint104(uint104 value) internal pure returns (uint104 result) {
		uint256 r = (_brutalizerRandomness(value) << 104) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes13(bytes13 value) internal pure returns (bytes13 result) {
		bytes32 r = _brutalizedBytesN(value, 104);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint112(uint112 value) internal pure returns (uint112 result) {
		uint256 r = (_brutalizerRandomness(value) << 112) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes14(bytes14 value) internal pure returns (bytes14 result) {
		bytes32 r = _brutalizedBytesN(value, 112);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint120(uint120 value) internal pure returns (uint120 result) {
		uint256 r = (_brutalizerRandomness(value) << 120) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes15(bytes15 value) internal pure returns (bytes15 result) {
		bytes32 r = _brutalizedBytesN(value, 120);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint128(uint128 value) internal pure returns (uint128 result) {
		uint256 r = (_brutalizerRandomness(value) << 128) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes16(bytes16 value) internal pure returns (bytes16 result) {
		bytes32 r = _brutalizedBytesN(value, 128);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint136(uint136 value) internal pure returns (uint136 result) {
		uint256 r = (_brutalizerRandomness(value) << 136) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes17(bytes17 value) internal pure returns (bytes17 result) {
		bytes32 r = _brutalizedBytesN(value, 136);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint144(uint144 value) internal pure returns (uint144 result) {
		uint256 r = (_brutalizerRandomness(value) << 144) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes18(bytes18 value) internal pure returns (bytes18 result) {
		bytes32 r = _brutalizedBytesN(value, 144);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint152(uint152 value) internal pure returns (uint152 result) {
		uint256 r = (_brutalizerRandomness(value) << 152) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes19(bytes19 value) internal pure returns (bytes19 result) {
		bytes32 r = _brutalizedBytesN(value, 152);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint160(uint160 value) internal pure returns (uint160 result) {
		uint256 r = (_brutalizerRandomness(value) << 160) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes20(bytes20 value) internal pure returns (bytes20 result) {
		bytes32 r = _brutalizedBytesN(value, 160);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint168(uint168 value) internal pure returns (uint168 result) {
		uint256 r = (_brutalizerRandomness(value) << 168) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes21(bytes21 value) internal pure returns (bytes21 result) {
		bytes32 r = _brutalizedBytesN(value, 168);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint176(uint176 value) internal pure returns (uint176 result) {
		uint256 r = (_brutalizerRandomness(value) << 176) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes22(bytes22 value) internal pure returns (bytes22 result) {
		bytes32 r = _brutalizedBytesN(value, 176);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint184(uint184 value) internal pure returns (uint184 result) {
		uint256 r = (_brutalizerRandomness(value) << 184) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes23(bytes23 value) internal pure returns (bytes23 result) {
		bytes32 r = _brutalizedBytesN(value, 184);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint192(uint192 value) internal pure returns (uint192 result) {
		uint256 r = (_brutalizerRandomness(value) << 192) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes24(bytes24 value) internal pure returns (bytes24 result) {
		bytes32 r = _brutalizedBytesN(value, 192);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint200(uint200 value) internal pure returns (uint200 result) {
		uint256 r = (_brutalizerRandomness(value) << 200) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes25(bytes25 value) internal pure returns (bytes25 result) {
		bytes32 r = _brutalizedBytesN(value, 200);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint208(uint208 value) internal pure returns (uint208 result) {
		uint256 r = (_brutalizerRandomness(value) << 208) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes26(bytes26 value) internal pure returns (bytes26 result) {
		bytes32 r = _brutalizedBytesN(value, 208);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint216(uint216 value) internal pure returns (uint216 result) {
		uint256 r = (_brutalizerRandomness(value) << 216) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes27(bytes27 value) internal pure returns (bytes27 result) {
		bytes32 r = _brutalizedBytesN(value, 216);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint224(uint224 value) internal pure returns (uint224 result) {
		uint256 r = (_brutalizerRandomness(value) << 224) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes28(bytes28 value) internal pure returns (bytes28 result) {
		bytes32 r = _brutalizedBytesN(value, 224);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint232(uint232 value) internal pure returns (uint232 result) {
		uint256 r = (_brutalizerRandomness(value) << 232) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes29(bytes29 value) internal pure returns (bytes29 result) {
		bytes32 r = _brutalizedBytesN(value, 232);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint240(uint240 value) internal pure returns (uint240 result) {
		uint256 r = (_brutalizerRandomness(value) << 240) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes30(bytes30 value) internal pure returns (bytes30 result) {
		bytes32 r = _brutalizedBytesN(value, 240);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalizedUint248(uint248 value) internal pure returns (uint248 result) {
		uint256 r = (_brutalizerRandomness(value) << 248) ^ uint256(value);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the lower bits dirtied
	function brutalizedBytes31(bytes31 value) internal pure returns (bytes31 result) {
		bytes32 r = _brutalizedBytesN(value, 248);
		assembly ("memory-safe") {
			result := r
		}
	}

	/// @dev Returns the result with the upper bits dirtied
	function brutalized(bool value) internal pure returns (bool result) {
		assembly ("memory-safe") {
			result := mload(0x40)
			calldatacopy(result, 0x00, calldatasize())
			mstore(0x20, keccak256(result, calldatasize()))
			mstore(0x10, xor(value, mload(0x10)))
			let r := keccak256(0x00, 0x88)
			mstore(0x10, r)
			result := mul(iszero(iszero(value)), r)
			if iszero(and(0x01, shr(0x80, mulmod(r, LPRNG_MULTIPLIER, LPRNG_MODULO)))) {
				result := iszero(iszero(result))
			}
		}
	}

	/// @dev Returns a brutalizer randomness
	function _brutalizedBytesN(bytes32 x, uint256 s) private pure returns (bytes32 result) {
		return bytes32(uint256((_brutalizerRandomness(uint256(x)) >> s) ^ uint256(x)));
	}

	/// @dev Returns a brutalizer randomness
	function _brutalizerRandomness(uint256 seed) private pure returns (uint256 result) {
		assembly ("memory-safe") {
			result := mload(0x40)
			calldatacopy(result, 0x00, calldatasize())
			mstore(0x20, keccak256(result, calldatasize()))
			mstore(0x10, xor(seed, mload(0x10)))
			result := keccak256(0x00, 0x88)
			mstore(0x10, result)
			if iszero(and(0x07, shr(0x80, mulmod(result, LPRNG_MULTIPLIER, LPRNG_MODULO)))) {
				result := 0x00
			}
		}
	}

	/// @dev Returns the free memory pointer
	function freeMemoryPointer() internal pure returns (uint256 result) {
		assembly ("memory-safe") {
			result := mload(0x40)
		}
	}

	/// @dev Sets the free memory pointer
	function setFreeMemoryPointer(uint256 m) internal pure {
		assembly ("memory-safe") {
			mstore(0x40, m)
		}
	}

	/// @dev Increments the free memory pointer by a world
	function incrementFreeMemoryPointer() internal pure {
		uint256 word = 0x20;
		assembly ("memory-safe") {
			mstore(0x40, add(mload(0x40), word))
		}
	}

	/// @dev Misaligns the free memory pointer (the free memory pointer has a 1/32 chance to be aligned)
	function misalignFreeMemoryPointer() internal pure {
		uint256 twoWords = 0x40;
		assembly ("memory-safe") {
			let ptr := mload(twoWords)
			ptr := add(ptr, mul(and(keccak256(0x00, twoWords), 0x1f), iszero(and(ptr, 0x1f))))
			mstore(twoWords, ptr)
		}
	}

	/// @dev Check if the free memory pointer and the zero slot are not contaminated
	function checkMemory() internal pure {
		bool zeroSlotIsNotZero;
		bool pointerOverflowed;
		assembly ("memory-safe") {
			// Write ones to the free memory, to make subsequent checks fail if insufficient memory is allocated
			mstore(mload(0x40), not(0x00))
			// Test at a lower, but reasonable limit for more safety room
			if gt(mload(0x40), 0xffffffff) {
				pointerOverflowed := 0x01
			}
			// Check the value of the zero slot
			zeroSlotIsNotZero := mload(0x60)
		}

		if (pointerOverflowed) revert MemoryPointerOverflowed();
		if (zeroSlotIsNotZero) revert ZeroSlotIsNotZero();
	}

	/// @dev Check if `input`:
	/// - has sufficient memory allocated
	/// - is zero right padded (because some front ends like Etherscan has issues with decoding non-zero-right-padded strings)
	function checkMemory(bytes memory input) internal pure {
		bool zeroNotRightPadded;
		bool insufficientMemory;
		assembly ("memory-safe") {
			// Write ones to the free memory, to make subsequent checks fail if insufficient memory is allocated
			mstore(mload(0x40), not(0x00))
			let length := mload(input)
			let lastWord := mload(add(add(input, 0x20), and(length, not(0x1f))))
			let remainder := and(length, 0x1f)
			if remainder {
				if shl(mul(0x08, remainder), lastWord) {
					zeroNotRightPadded := 0x01
				}
			}
			// Check if the memory allocated is sufficient
			if length {
				if gt(add(add(input, 0x20), length), mload(0x40)) {
					insufficientMemory := 0x01
				}
			}
		}

		if (zeroNotRightPadded) revert ZeroNotRightPadded();
		if (insufficientMemory) revert InsufficientMemoryAllocation();
		checkMemory();
	}

	/// @dev For checking the memory allocation for string `input`
	function checkMemory(string memory input) internal pure {
		checkMemory(bytes(input));
	}

	/// @dev Check if `input` has sufficient memory allocated
	function checkMemory(uint256[] memory input) internal pure {
		bool insufficientMemory;
		assembly ("memory-safe") {
			// Write ones to the free memory, to make subsequent checks fail if insufficient memory is allocated
			mstore(mload(0x40), not(0x00))
			// Check if the memory allocated is sufficient
			insufficientMemory := gt(add(add(input, 0x20), shl(0x05, mload(input))), mload(0x40))
		}

		if (insufficientMemory) revert InsufficientMemoryAllocation();
		checkMemory();
	}

	/// @dev Check if `input` has sufficient memory allocated
	function checkMemory(bytes32[] memory input) internal pure {
		uint256[] memory casted;
		assembly ("memory-safe") {
			casted := input
		}
		checkMemory(casted);
	}

	/// @dev Check if `input` has sufficient memory allocated
	function checkMemory(address[] memory input) internal pure {
		uint256[] memory casted;
		assembly ("memory-safe") {
			casted := input
		}
		checkMemory(casted);
	}

	/// @dev Check if `input` has sufficient memory allocated
	function checkMemory(bool[] memory input) internal pure {
		uint256[] memory casted;
		assembly ("memory-safe") {
			casted := input
		}
		checkMemory(casted);
	}

	/// @dev Truncates the bytes to `n` bytes
	function truncateBytes(bytes memory input, uint256 n) internal pure returns (bytes memory output) {
		assembly ("memory-safe") {
			if gt(mload(input), n) {
				mstore(input, n)
			}
			output := input
		}
	}

	/// @dev Returns if the `target` has code
	function hasCode(address target) internal view returns (bool result) {
		assembly ("memory-safe") {
			result := iszero(iszero(extcodesize(target)))
		}
	}
}
