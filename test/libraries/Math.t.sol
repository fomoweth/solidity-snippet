// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Math as OzMath} from "@openzeppelin/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/utils/math/SignedMath.sol";
import {Math} from "src/libraries/Math.sol";

contract MathTest is Test {
	function test_fuzz_saturatingAdd(uint256 x, uint256 y) public pure {
		assertEq(Math.saturatingAdd(x, y), OzMath.saturatingAdd(x, y));
	}

	function test_fuzz_saturatingSub(uint256 x, uint256 y) public pure {
		assertEq(Math.saturatingSub(x, y), OzMath.saturatingSub(x, y));
	}

	function test_fuzz_saturatingMul(uint256 x, uint256 y) public pure {
		assertEq(Math.saturatingMul(x, y), OzMath.saturatingMul(x, y));
	}

	function test_fuzz_ceilDiv(uint256 x, uint256 y) public {
		if (y == 0) vm.expectRevert(Math.DivisionByZero.selector);
		assertEq(Math.ceilDiv(x, y), OzMath.ceilDiv(x, y));
	}

	function test_fuzz_mulDiv(uint256 x, uint256 y, uint256 d, uint8 r) public {
		OzMath.Rounding rd = asRounding(r);
		(uint256 p1, ) = OzMath.mul512(x, y);
		if (d == 0) {
			vm.expectRevert(Math.DivisionByZero.selector);
			unsignedRoundsUp(rd) ? Math.mulDivUp(x, y, d) : Math.mulDiv(x, y, d);
		} else if (p1 >= d) {
			vm.expectRevert(Math.Overflow.selector);
			unsignedRoundsUp(rd) ? Math.mulDivUp(x, y, d) : Math.mulDiv(x, y, d);
		} else {
			assertEq(unsignedRoundsUp(rd) ? Math.mulDivUp(x, y, d) : Math.mulDiv(x, y, d), OzMath.mulDiv(x, y, d, rd));
		}
	}

	function test_fuzz_mulDiv64(uint256 x, uint256 y, uint8 r) public {
		OzMath.Rounding rd = asRounding(r);
		(uint256 p1, ) = OzMath.mul512(x, y);
		if (p1 >= Math.Q64) {
			vm.expectRevert(Math.Overflow.selector);
			unsignedRoundsUp(rd) ? Math.mulDiv64Up(x, y) : Math.mulDiv64(x, y);
		} else {
			uint256 z = unsignedRoundsUp(rd) ? Math.mulDiv64Up(x, y) : Math.mulDiv64(x, y);
			assertEq(z, OzMath.mulDiv(x, y, Math.Q64, rd));
			assertEq(z, OzMath.mulShr(x, y, 64, rd));
		}
	}

	function test_fuzz_mulDiv96(uint256 x, uint256 y, uint8 r) public {
		OzMath.Rounding rd = asRounding(r);
		(uint256 p1, ) = OzMath.mul512(x, y);
		if (p1 >= Math.Q96) {
			vm.expectRevert(Math.Overflow.selector);
			unsignedRoundsUp(rd) ? Math.mulDiv96Up(x, y) : Math.mulDiv96(x, y);
		} else {
			uint256 z = unsignedRoundsUp(rd) ? Math.mulDiv96Up(x, y) : Math.mulDiv96(x, y);
			assertEq(z, OzMath.mulDiv(x, y, Math.Q96, rd));
			assertEq(z, OzMath.mulShr(x, y, 96, rd));
		}
	}

	function test_fuzz_mulDiv128(uint256 x, uint256 y, uint8 r) public {
		OzMath.Rounding rd = asRounding(r);
		(uint256 p1, ) = OzMath.mul512(x, y);
		if (p1 >= Math.Q128) {
			vm.expectRevert(Math.Overflow.selector);
			unsignedRoundsUp(rd) ? Math.mulDiv128Up(x, y) : Math.mulDiv128(x, y);
		} else {
			uint256 z = unsignedRoundsUp(rd) ? Math.mulDiv128Up(x, y) : Math.mulDiv128(x, y);
			assertEq(z, OzMath.mulDiv(x, y, Math.Q128, rd));
			assertEq(z, OzMath.mulShr(x, y, 128, rd));
		}
	}

	function test_fuzz_mulDiv192(uint256 x, uint256 y, uint8 r) public {
		OzMath.Rounding rd = asRounding(r);
		(uint256 p1, ) = OzMath.mul512(x, y);
		if (p1 >= Math.Q192) {
			vm.expectRevert(Math.Overflow.selector);
			unsignedRoundsUp(rd) ? Math.mulDiv192Up(x, y) : Math.mulDiv192(x, y);
		} else {
			uint256 z = unsignedRoundsUp(rd) ? Math.mulDiv192Up(x, y) : Math.mulDiv192(x, y);
			assertEq(z, OzMath.mulDiv(x, y, Math.Q192, rd));
			assertEq(z, OzMath.mulShr(x, y, 192, rd));
		}
	}

	function test_fuzz_mulShr(uint256 x, uint256 y, uint8 n, uint8 r) public {
		OzMath.Rounding rd = asRounding(r);
		(uint256 p1, ) = OzMath.mul512(x, y);
		if (p1 >= 1 << n) {
			vm.expectRevert(Math.Overflow.selector);
			unsignedRoundsUp(rd) ? Math.mulShrUp(x, y, n) : Math.mulShr(x, y, n);
		} else {
			assertEq(unsignedRoundsUp(rd) ? Math.mulShrUp(x, y, n) : Math.mulShr(x, y, n), OzMath.mulShr(x, y, n, rd));
		}
	}

	function test_fuzz_log2(uint256 x, uint8 r) public pure {
		OzMath.Rounding rd = asRounding(r);
		assertEq(unsignedRoundsUp(rd) ? Math.log2Up(x) : Math.log2(x), OzMath.log2(x, rd));
	}

	function test_fuzz_log10(uint256 x, uint8 r) public pure {
		OzMath.Rounding rd = asRounding(r);
		assertEq(unsignedRoundsUp(rd) ? Math.log10Up(x) : Math.log10(x), OzMath.log10(x, rd));
	}

	function test_fuzz_log256(uint256 x, uint8 r) public pure {
		OzMath.Rounding rd = asRounding(r);
		assertEq(unsignedRoundsUp(rd) ? Math.log256Up(x) : Math.log256(x), OzMath.log256(x, rd));
	}

	function test_fuzz_sqrt(uint256 x, uint8 r) public pure {
		OzMath.Rounding rd = asRounding(r);
		assertEq(unsignedRoundsUp(rd) ? Math.sqrtUp(x) : Math.sqrt(x), OzMath.sqrt(x, rd));
	}

	function test_fuzz_clz(uint256 x) public pure {
		assertEq(Math.clz(x), OzMath.clz(x));
	}

	function test_fuzz_isEven(uint256 x) public pure {
		assertEq(Math.isEven(x), x & 1 == 0);
	}

	function test_fuzz_abs(int256 x) public pure {
		assertEq(Math.abs(x), SignedMath.abs(x));
	}

	function test_fuzz_avg(uint256 x, uint256 y) public pure {
		assertEq(Math.avg(x, y), (x & y) + ((x ^ y) >> 1));
	}

	function test_fuzz_avg(int256 x, int256 y) public pure {
		assertEq(Math.avg(x, y), (x >> 1) + (y >> 1) + (x & y & 1));
	}

	function test_fuzz_clamp(uint256 x, uint256 lower, uint256 upper) public pure {
		uint256 z = x;
		if (z < lower) z = lower;
		if (z > upper) z = upper;
		assertEq(Math.clamp(x, lower, upper), z);
	}

	function test_fuzz_clamp(int256 x, int256 lower, int256 upper) public pure {
		int256 z = x;
		if (z < lower) z = lower;
		if (z > upper) z = upper;
		assertEq(Math.clamp(x, lower, upper), z);
	}

	function test_fuzz_dist(uint256 x, uint256 y) public pure {
		unchecked {
			assertEq(Math.dist(x, y), uint256(x > y ? x - y : y - x));
		}
	}

	function test_fuzz_dist(int256 x, int256 y) public pure {
		unchecked {
			assertEq(Math.dist(x, y), int256(x > y ? x - y : y - x));
		}
	}

	function test_fuzz_max(uint256 x, uint256 y) public pure {
		assertEq(Math.max(x, y), x > y ? x : y);
	}

	function test_fuzz_min(uint256 x, uint256 y) public pure {
		assertEq(Math.min(x, y), x < y ? x : y);
	}

	function test_fuzz_max(int256 x, int256 y) public pure {
		assertEq(Math.max(x, y), x > y ? x : y);
	}

	function test_fuzz_min(int256 x, int256 y) public pure {
		assertEq(Math.min(x, y), x < y ? x : y);
	}

	function test_fuzz_coalesce(uint256 x, uint256 y) public pure {
		assertEq(Math.coalesce(x, y), x != uint256(0) ? x : y);
	}

	function test_fuzz_coalesce(bytes32 x, bytes32 y) public pure {
		assertEq(Math.coalesce(x, y), x != bytes32(0) ? x : y);
	}

	function test_fuzz_coalesce(address x, address y) public pure {
		assertEq(Math.coalesce(x, y), x != address(0) ? x : y);
	}

	function test_fuzz_coalesce(int256 x, int256 y) public pure {
		assertEq(Math.coalesce(x, y), x != int256(0) ? x : y);
	}

	function test_fuzz_ternary(bool condition, uint256 x, uint256 y) public pure {
		assertEq(Math.ternary(condition, x, y), OzMath.ternary(condition, x, y));
	}

	function test_fuzz_ternary(bool condition, int256 x, int256 y) public pure {
		assertEq(Math.ternary(condition, x, y), SignedMath.ternary(condition, x, y));
	}

	function test_fuzz_ternary(bool condition, bytes32 x, bytes32 y) public pure {
		assertEq(Math.ternary(condition, x, y), bytes32(OzMath.ternary(condition, uint256(x), uint256(y))));
	}

	function test_fuzz_ternary(bool condition, address x, address y) public pure {
		assertEq(Math.ternary(condition, x, y), address(uint160(OzMath.ternary(condition, uint160(x), uint160(y)))));
	}

	function asRounding(uint8 r) internal pure returns (OzMath.Rounding z) {
		vm.assume(r <= uint8(type(OzMath.Rounding).max));
		return OzMath.Rounding(r);
	}

	function unsignedRoundsUp(OzMath.Rounding r) internal pure returns (bool z) {
		assembly ("memory-safe") {
			z := mod(r, 2)
		}
	}
}
