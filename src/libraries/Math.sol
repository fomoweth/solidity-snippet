// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Math
/// @notice Arithmetic library with operations for fixed-point numbers
/// @dev Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol
/// @dev Reference: https://github.com/Vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol
/// @dev Reference: https://github.com/panoptic-labs/panoptic-v1-core/blob/v1.0.x/contracts/libraries/Math.sol
/// @author fomoweth
library Math {
	/// @notice Thrown when the operation failed due to a division by zero
	error DivisionByZero();

	/// @notice Thrown when the operation failed due to an overflow
	error Overflow();

	uint256 internal constant Q64 = 0x10000000000000000;
	uint256 internal constant Q96 = 0x1000000000000000000000000;
	uint256 internal constant Q128 = 0x100000000000000000000000000000000;
	uint256 internal constant Q160 = 0x0010000000000000000000000000000000000000000;
	uint256 internal constant Q192 = 0x1000000000000000000000000000000000000000000000000;

	/// @notice Returns `x + y`, without checking for overflow
	function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
		unchecked {
			z = x + y;
		}
	}

	/// @notice Returns `x + y`, without checking for overflow
	function add(int256 x, int256 y) internal pure returns (int256 z) {
		unchecked {
			z = x + y;
		}
	}

	/// @notice Returns `x - y`, without checking for underflow
	function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
		unchecked {
			z = x - y;
		}
	}

	/// @notice Returns `x - y`, without checking for underflow
	function sub(int256 x, int256 y) internal pure returns (int256 z) {
		unchecked {
			z = x - y;
		}
	}

	/// @notice Returns `x * y`, without checking for overflow
	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		unchecked {
			z = x * y;
		}
	}

	/// @notice Returns `x * y`, without checking for overflow
	function mul(int256 x, int256 y) internal pure returns (int256 z) {
		unchecked {
			z = x * y;
		}
	}

	/// @notice Returns `x / y`, returning 0 if `y` is zero
	function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := div(x, y)
		}
	}

	/// @notice Returns `x / y`, returning 0 if `y` is zero
	function div(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := sdiv(x, y)
		}
	}

	/// @notice Returns `x % y`, returning 0 if `y` is zero
	function mod(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := mod(x, y)
		}
	}

	/// @notice Returns `x % y`, returning 0 if `y` is zero
	function mod(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := smod(x, y)
		}
	}

	/// @notice Returns `min(2 ^ 256 - 1, x + y)`
	function saturatingAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := or(sub(0, lt(add(x, y), x)), add(x, y))
		}
	}

	/// @notice Returns `max(0, x - y)`
	function saturatingSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := mul(gt(x, y), sub(x, y))
		}
	}

	/// @notice Returns `min(2 ^ 256 - 1, x * y)`
	function saturatingMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := or(sub(or(iszero(x), eq(div(mul(x, y), x), y)), 1), mul(x, y))
		}
	}

	/// @notice Returns `ceil(x / y)`, reverting if `y` is zero
	function ceilDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(y) {
				mstore(0x00, 0x23d359a3) // DivisionByZero()
				revert(0x1c, 0x04)
			}
			z := add(div(x, y), iszero(iszero(mod(x, y))))
		}
	}

	/// @notice Returns `floor(x * y / d)` with full precision, reverting if result overflows a uint256 or `d` is zero
	function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(d) {
				mstore(0x00, 0x23d359a3) // DivisionByZero()
				revert(0x1c, 0x04)
			}

			let mm := mulmod(x, y, not(0))
			let p0 := mul(x, y)
			let p1 := sub(sub(mm, p0), lt(mm, p0))

			if iszero(lt(p1, d)) {
				mstore(0x00, 0x35278d12) // Overflow()
				revert(0x1c, 0x04)
			}

			switch iszero(p1)
			case 0 {
				let r := mulmod(x, y, d)
				p1 := sub(p1, gt(r, p0))
				p0 := sub(p0, r)
				let t := and(d, sub(0, d))
				d := div(d, t)
				let inv := xor(2, mul(3, d))
				inv := mul(inv, sub(2, mul(d, inv)))
				inv := mul(inv, sub(2, mul(d, inv)))
				inv := mul(inv, sub(2, mul(d, inv)))
				inv := mul(inv, sub(2, mul(d, inv)))
				inv := mul(inv, sub(2, mul(d, inv)))
				inv := mul(inv, sub(2, mul(d, inv)))
				z := mul(or(mul(p1, add(div(sub(0, t), t), 1)), div(p0, t)), inv)
			}
			default {
				z := div(p0, d)
			}
		}
	}

	/// @notice Returns `ceil(x * y / d)` with full precision, reverting if result overflows a uint256 or `d` is zero
	function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
		z = mulDiv(x, y, d);
		assembly ("memory-safe") {
			if mulmod(x, y, d) {
				z := add(z, 1)
				if iszero(z) {
					mstore(0x00, 0x35278d12) // Overflow()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	/// @notice Returns `floor(x * y / 2^64)` with full precision, reverting if result overflows a uint256
	function mulDiv64(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			let mm := mulmod(x, y, not(0))
			let p0 := mul(x, y)
			let p1 := sub(sub(mm, p0), lt(mm, p0))

			if iszero(gt(Q64, p1)) {
				mstore(0x00, 0x35278d12) // Overflow()
				revert(0x1c, 0x04)
			}

			switch iszero(p1)
			case 0 {
				let r := mulmod(x, y, Q64)
				p1 := sub(p1, gt(r, p0))
				p0 := sub(p0, r)
				z := or(mul(p1, Q192), shr(64, p0))
			}
			default {
				z := shr(64, p0)
			}
		}
	}

	/// @notice Returns `ceil(x * y / 2^64)` with full precision, reverting if result overflows a uint256
	function mulDiv64Up(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = mulDiv64(x, y);
		assembly ("memory-safe") {
			if mulmod(x, y, Q64) {
				z := add(z, 1)
				if iszero(z) {
					mstore(0x00, 0x35278d12) // Overflow()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	/// @notice Returns `floor(x * y / 2^96)` with full precision, reverting if result overflows a uint256
	function mulDiv96(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			let mm := mulmod(x, y, not(0))
			let p0 := mul(x, y)
			let p1 := sub(sub(mm, p0), lt(mm, p0))

			if iszero(gt(Q96, p1)) {
				mstore(0x00, 0x35278d12) // Overflow()
				revert(0x1c, 0x04)
			}

			switch iszero(p1)
			case 0 {
				let r := mulmod(x, y, Q96)
				p1 := sub(p1, gt(r, p0))
				p0 := sub(p0, r)
				z := or(mul(p1, Q160), shr(96, p0))
			}
			default {
				z := shr(96, p0)
			}
		}
	}

	/// @notice Returns `ceil(x * y / 2^96)` with full precision, reverting if result overflows a uint256
	function mulDiv96Up(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = mulDiv96(x, y);
		assembly ("memory-safe") {
			if mulmod(x, y, Q96) {
				z := add(z, 1)
				if iszero(z) {
					mstore(0x00, 0x35278d12) // Overflow()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	/// @notice Returns `floor(x * y / 2^128)` with full precision, reverting if result overflows a uint256
	function mulDiv128(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			let mm := mulmod(x, y, not(0))
			let p0 := mul(x, y)
			let p1 := sub(sub(mm, p0), lt(mm, p0))

			if iszero(gt(Q128, p1)) {
				mstore(0x00, 0x35278d12) // Overflow()
				revert(0x1c, 0x04)
			}

			switch iszero(p1)
			case 0 {
				let r := mulmod(x, y, Q128)
				p1 := sub(p1, gt(r, p0))
				p0 := sub(p0, r)
				z := or(mul(p1, Q128), shr(128, p0))
			}
			default {
				z := shr(128, p0)
			}
		}
	}

	/// @notice Returns `ceil(x * y / 2^128)` with full precision, reverting if result overflows a uint256
	function mulDiv128Up(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = mulDiv128(x, y);
		assembly ("memory-safe") {
			if mulmod(x, y, Q128) {
				z := add(z, 1)
				if iszero(z) {
					mstore(0x00, 0x35278d12) // Overflow()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	/// @notice Returns `floor(x * y / 2^192)` with full precision, reverting if result overflows a uint256
	function mulDiv192(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			let mm := mulmod(x, y, not(0))
			let p0 := mul(x, y)
			let p1 := sub(sub(mm, p0), lt(mm, p0))

			if iszero(gt(Q192, p1)) {
				mstore(0x00, 0x35278d12) // Overflow()
				revert(0x1c, 0x04)
			}

			switch iszero(p1)
			case 0 {
				let r := mulmod(x, y, Q192)
				p1 := sub(p1, gt(r, p0))
				p0 := sub(p0, r)
				z := or(mul(p1, Q64), shr(192, p0))
			}
			default {
				z := shr(192, p0)
			}
		}
	}

	/// @notice Returns `ceil(x * y / 2^192)` with full precision, reverting if result overflows a uint256
	function mulDiv192Up(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = mulDiv192(x, y);
		assembly ("memory-safe") {
			if mulmod(x, y, Q192) {
				z := add(z, 1)
				if iszero(z) {
					mstore(0x00, 0x35278d12) // Overflow()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	/// @notice Returns `floor(x * y >> n)` with full precision, reverting if result overflows a uint256
	function mulShr(uint256 x, uint256 y, uint8 n) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := mul(x, y)
			// prettier-ignore
			for {} 1 {} {
				if iszero(or(iszero(x), eq(div(z, x), y))) {
					let k := and(n, 0xff)
					let mm := mulmod(x, y, not(0))
					let p1 := sub(mm, add(z, lt(mm, z)))
					if iszero(shr(k, p1)) {
						z := add(shl(sub(256, k), p1), shr(k, z))
						break
					}
					mstore(0x00, 0x35278d12) // Overflow()
					revert(0x1c, 0x04)
				}
				z := shr(and(n, 0xff), z)
				break
			}
		}
	}

	/// @notice Returns `ceil(x * y >> n)` with full precision, reverting if result overflows a uint256
	function mulShrUp(uint256 x, uint256 y, uint8 n) internal pure returns (uint256 z) {
		z = mulShr(x, y, n);
		assembly ("memory-safe") {
			if mulmod(x, y, shl(n, 1)) {
				z := add(z, 1)
				if iszero(z) {
					mstore(0x00, 0x35278d12) // Overflow()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	/// @notice Returns the log2 of `x`, returning 0 if `x` is zero
	function log2(uint256 x) internal pure returns (uint256 z) {
		// prettier-ignore
		assembly ("memory-safe") {
            z := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            z := or(z, shl(6, lt(0xffffffffffffffff, shr(z, x))))
            z := or(z, shl(5, lt(0xffffffff, shr(z, x))))
            z := or(z, shl(4, lt(0xffff, shr(z, x))))
            z := or(z, shl(3, lt(0xff, shr(z, x))))
            z := or(z, byte(and(0x1f, shr(shr(z, x), 0x8421084210842108cc6318c6db6d54be)),
                0x0706060506020504060203020504030106050205030304010505030400000000))
        }
	}

	/// @notice Returns the log2 of `x`, rounded up, returning 0 if `x` is zero
	function log2Up(uint256 x) internal pure returns (uint256 z) {
		z = log2(x);
		assembly ("memory-safe") {
			z := add(z, lt(shl(z, 1), x))
		}
	}

	/// @notice Returns the log10 of `x`, returning 0 if `x` is zero
	function log10(uint256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(lt(x, 100000000000000000000000000000000000000)) {
				x := div(x, 100000000000000000000000000000000000000)
				z := 38
			}
			if iszero(lt(x, 100000000000000000000)) {
				x := div(x, 100000000000000000000)
				z := add(z, 20)
			}
			if iszero(lt(x, 10000000000)) {
				x := div(x, 10000000000)
				z := add(z, 10)
			}
			if iszero(lt(x, 100000)) {
				x := div(x, 100000)
				z := add(z, 5)
			}
			z := add(z, add(gt(x, 9), add(gt(x, 99), add(gt(x, 999), gt(x, 9999)))))
		}
	}

	/// @notice Returns the log10 of `x`, rounded up, returning 0 if `x` is zero
	function log10Up(uint256 x) internal pure returns (uint256 z) {
		z = log10(x);
		assembly ("memory-safe") {
			z := add(z, lt(exp(10, z), x))
		}
	}

	/// @notice Returns the log256 of `x`, returning 0 if `x` is zero
	function log256(uint256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
			z := or(z, shl(6, lt(0xffffffffffffffff, shr(z, x))))
			z := or(z, shl(5, lt(0xffffffff, shr(z, x))))
			z := or(z, shl(4, lt(0xffff, shr(z, x))))
			z := or(shr(3, z), lt(0xff, shr(z, x)))
		}
	}

	/// @notice Returns the log256 of `x`, rounded up, returning 0 if `x` is zero
	function log256Up(uint256 x) internal pure returns (uint256 z) {
		z = log256(x);
		assembly ("memory-safe") {
			z := add(z, lt(shl(shl(3, z), 1), x))
		}
	}

	/// @notice Exponentiate `x` to `y` by squaring, denominated in base `b`, reverting if the computation overflows
	function rpow(uint256 x, uint256 y, uint256 b) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := mul(b, iszero(y))
			if x {
				z := xor(b, mul(xor(b, x), and(y, 1)))
				let half := shr(1, b)
				for {
					y := shr(1, y)
				} y {
					y := shr(1, y)
				} {
					let xx := mul(x, x)
					let xxRound := add(xx, half)
					if or(lt(xxRound, xx), shr(128, x)) {
						mstore(0x00, 0x35278d12) // Overflow()
						revert(0x1c, 0x04)
					}
					x := div(xxRound, b)
					if and(y, 1) {
						let zx := mul(z, x)
						let zxRound := add(zx, half)
						if or(xor(div(zx, x), z), lt(zxRound, zx)) {
							if x {
								mstore(0x00, 0x35278d12) // Overflow()
								revert(0x1c, 0x04)
							}
						}
						z := div(zxRound, b)
					}
				}
			}
		}
	}

	/// @notice Returns the square root of `x`, rounded down
	function sqrt(uint256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := 181
			let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
			r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
			r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
			r := or(r, shl(4, lt(0xffffff, shr(r, x))))
			z := shl(shr(1, r), z)
			z := shr(18, mul(z, add(shr(r, x), 65536)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := sub(z, lt(div(x, z), z))
		}
	}

	/// @notice Returns the square root of `x`, rounded up
	function sqrtUp(uint256 x) internal pure returns (uint256 z) {
		z = sqrt(x);
		assembly ("memory-safe") {
			z := add(z, lt(mul(z, z), x))
		}
	}

	/// @notice Returns if `x` is an even number
	function isEven(uint256 x) internal pure returns (bool z) {
		assembly ("memory-safe") {
			z := iszero(and(x, 1))
		}
	}

	/// @notice Returns the absolute value of `x`
	function abs(int256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := sar(255, x)
			z := xor(z, add(z, x))
		}
	}

	/// @notice Returns the average of `x` and `y`, rounded towards zero
	function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := add(and(x, y), shr(1, xor(x, y)))
		}
	}

	/// @notice Returns the average of `x` and `y`, rounded towards negative infinity
	function avg(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := add(add(sar(1, x), sar(1, y)), and(and(x, y), 1))
		}
	}

	/// @notice Returns `x`, bounded to `lower` and `upper`
	function clamp(uint256 x, uint256 lower, uint256 upper) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, lower), gt(lower, x)))
			z := xor(z, mul(xor(z, upper), lt(upper, z)))
		}
	}

	/// @notice Returns `x`, bounded to `lower` and `upper`
	function clamp(int256 x, int256 lower, int256 upper) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, lower), sgt(lower, x)))
			z := xor(z, mul(xor(z, upper), slt(upper, z)))
		}
	}

	/// @notice Returns the absolute distance between `x` and `y`
	function dist(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := add(xor(sub(0, gt(x, y)), sub(y, x)), gt(x, y))
		}
	}

	/// @notice Returns the absolute distance between `x` and `y`
	function dist(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := add(xor(sub(0, sgt(x, y)), sub(y, x)), sgt(x, y))
		}
	}

	/// @notice Returns the maximum of `x` and `y`
	function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), gt(y, x)))
		}
	}

	/// @notice Returns the maximum of `x` and `y`
	function max(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), sgt(y, x)))
		}
	}

	/// @notice Returns the minimum of `x` and `y`
	function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), lt(y, x)))
		}
	}

	/// @notice Returns the minimum of `x` and `y`
	function min(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), slt(y, x)))
		}
	}

	/// @notice Returns `x != 0 ? x : y`, without branching
	function coalesce(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := or(x, mul(y, iszero(x)))
		}
	}

	/// @notice Returns `x != 0 ? x : y`, without branching
	function coalesce(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := or(x, mul(y, iszero(x)))
		}
	}

	/// @notice Returns `x != bytes32(0) ? x : y`, without branching
	function coalesce(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
		assembly ("memory-safe") {
			z := or(x, mul(y, iszero(x)))
		}
	}

	/// @notice Returns `x != address(0) ? x : y`, without branching
	function coalesce(address x, address y) internal pure returns (address z) {
		assembly ("memory-safe") {
			z := or(x, mul(y, iszero(shl(96, x))))
		}
	}

	/// @notice Returns `condition ? x : y`, without branching
	function ternary(bool condition, uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), iszero(condition)))
		}
	}

	/// @notice Returns `condition ? x : y`, without branching
	function ternary(bool condition, int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), iszero(condition)))
		}
	}

	/// @notice Returns `condition ? x : y`, without branching
	function ternary(bool condition, bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), iszero(condition)))
		}
	}

	/// @notice Returns `condition ? x : y`, without branching
	function ternary(bool condition, address x, address y) internal pure returns (address z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), iszero(condition)))
		}
	}
}
