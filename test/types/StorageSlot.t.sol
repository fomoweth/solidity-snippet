// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {StorageSlot, AddressSlot, BooleanSlot, Bytes32Slot, Uint256Slot, Int256Slot, BytesSlot, StringSlot} from "src/types/StorageSlot.sol";
import {Static} from "test/shared/utils/Static.sol";

contract StorageSlotTest is Test {
	using StorageSlot for uint256;

	AddressSlot internal immutable ADDRESS_SLOT = erc7201Slot("ADDRESS_SLOT").asAddressSlot();

	BooleanSlot internal immutable BOOLEAN_SLOT = erc7201Slot("BOOLEAN_SLOT").asBooleanSlot();

	Bytes32Slot internal immutable BYTES32_SLOT = erc7201Slot("BYTES32_SLOT").asBytes32Slot();

	Uint256Slot internal immutable UINT256_SLOT = erc7201Slot("UINT256_SLOT").asUint256Slot();

	Int256Slot internal immutable INT256_SLOT = erc7201Slot("INT256_SLOT").asInt256Slot();

	BytesSlot internal immutable BYTES_SLOT = erc7201Slot("BYTES_SLOT").asBytesSlot();

	StringSlot internal immutable STRING_SLOT = erc7201Slot("STRING_SLOT").asStringSlot();

	function test_storage_slot_address() public {
		testStorageSlot(address(0xdeadbeef));
		testStorageSlot(address(0x0000000000000000000000000000000000000000));
		testStorageSlot(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
	}

	function test_storage_slot_boolean() public {
		testStorageSlot(true);
		testStorageSlot(false);
		testStorageSlot(false);
		testStorageSlot(true);
		testStorageSlot(false);
	}

	function test_storage_slot_bytes32() public {
		testStorageSlot(bytes32("BYTES32_SLOT"));
		testStorageSlot(bytes32(""));
		testStorageSlot(bytes32("BYTES32"));
		testStorageSlot(bytes32(""));
		testStorageSlot(bytes32("SLOT"));
		testStorageSlot(bytes32(""));
	}

	function test_storage_slot_uint256() public {
		testStorageSlot(type(uint256).max);
		testStorageSlot(type(uint256).min);
		testStorageSlot(type(uint160).max);
		testStorageSlot(type(uint160).min);
		testStorageSlot(type(uint128).max);
		testStorageSlot(type(uint128).min);
	}

	function test_storage_slot_int256() public {
		testStorageSlot(type(int256).min);
		testStorageSlot(int256(0));
		testStorageSlot(type(int256).max);
		testStorageSlot(int256(0));
		testStorageSlot(type(int160).min);
		testStorageSlot(type(int160).max);
		testStorageSlot(type(int128).min);
		testStorageSlot(type(int128).max);
		testStorageSlot(int256(0));
	}

	function test_storage_slot_bytes() public {
		testStorageSlot(Static.TRANSPARENT_PROXY_BYTECODE);
		testStorageSlot(Static.PROXY_ADMIN_BYTECODE);
		testStorageSlot(Static.PERMIT2_BYTECODE);
	}

	function test_storage_slot_string() public {
		testStorageSlot(string("STORAGE_SLOT"));
		testStorageSlot(string(""));
		testStorageSlot(string("STORAGE"));
		testStorageSlot(string(""));
		testStorageSlot(string("SLOT"));
		testStorageSlot(string(""));
	}

	function test_transient_slot_address() public {
		testTransientSlot(address(0xdeadbeef));
		testTransientSlot(address(0x0000000000000000000000000000000000000000));
		testTransientSlot(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
	}

	function test_transient_slot_boolean() public {
		testTransientSlot(true);
		testTransientSlot(false);
		testTransientSlot(false);
		testTransientSlot(true);
		testTransientSlot(false);
	}

	function test_transient_slot_bytes32() public {
		testTransientSlot(bytes32("BYTES32_SLOT"));
		testTransientSlot(bytes32(""));
		testTransientSlot(bytes32("BYTES32"));
		testTransientSlot(bytes32(""));
		testTransientSlot(bytes32("SLOT"));
		testTransientSlot(bytes32(""));
	}

	function test_transient_slot_uint256() public {
		testTransientSlot(type(uint256).max);
		testTransientSlot(type(uint256).min);
		testTransientSlot(type(uint160).max);
		testTransientSlot(type(uint160).min);
		testTransientSlot(type(uint128).max);
		testTransientSlot(type(uint128).min);
	}

	function test_transient_slot_int256() public {
		testTransientSlot(type(int256).min);
		testTransientSlot(int256(0));
		testTransientSlot(type(int256).max);
		testTransientSlot(int256(0));
		testTransientSlot(type(int160).min);
		testTransientSlot(type(int160).max);
		testTransientSlot(type(int128).min);
		testTransientSlot(type(int128).max);
		testTransientSlot(int256(0));
	}

	function test_transient_slot_bytes() public {
		testTransientSlot(Static.TRANSPARENT_PROXY_BYTECODE);
		testTransientSlot(Static.PROXY_ADMIN_BYTECODE);
		testTransientSlot(Static.PERMIT2_BYTECODE);
	}

	function test_transient_slot_string() public {
		testTransientSlot(string("TRANSIENT_SLOT"));
		testTransientSlot(string(""));
		testTransientSlot(string("TRANSIENT"));
		testTransientSlot(string(""));
		testTransientSlot(string("SLOT"));
		testTransientSlot(string(""));
	}

	function test_fuzz_storage_slot_address(address x) public {
		vm.assume(x != address(0));
		assertEq(ADDRESS_SLOT.sload(), address(0));
		testStorageSlot(x);
	}

	function test_fuzz_storage_slot_boolean(bool x) public {
		vm.assume(x);
		assertFalse(BOOLEAN_SLOT.sload());
		testStorageSlot(x);
	}

	function test_fuzz_storage_slot_bytes32(bytes32 x) public {
		vm.assume(x != bytes32(0));
		assertEq(BYTES32_SLOT.sload(), bytes32(0));
		testStorageSlot(x);
	}

	function test_fuzz_storage_slot_uint256(uint256 x) public {
		vm.assume(x != uint256(0));
		assertEq(UINT256_SLOT.sload(), uint256(0));
		testStorageSlot(x);
	}

	function test_fuzz_storage_slot_int256(int256 x) public {
		vm.assume(x != int256(0));
		assertEq(INT256_SLOT.sload(), int256(0));
		testStorageSlot(x);
	}

	function test_fuzz_storage_slot_bytes(bytes memory x) public {
		vm.assume(x.length != uint256(0));
		assertEq(BYTES_SLOT.slength(), uint256(0));
		testStorageSlot(x);
	}

	function test_fuzz_storage_slot_string(string memory x) public {
		vm.assume(bytes(x).length != uint256(0));
		assertEq(STRING_SLOT.slength(), uint256(0));
		testStorageSlot(x);
	}

	function test_fuzz_transient_slot_address(address x) public {
		vm.assume(x != address(0));
		assertEq(ADDRESS_SLOT.tload(), address(0));
		testTransientSlot(x);
	}

	function test_fuzz_transient_slot_boolean(bool x) public {
		assertFalse(BOOLEAN_SLOT.tload());
		testTransientSlot(x);
	}

	function test_fuzz_transient_slot_bytes32(bytes32 x) public {
		vm.assume(x != bytes32(0));
		assertEq(BYTES32_SLOT.tload(), bytes32(0));
		testTransientSlot(x);
	}

	function test_fuzz_transient_slot_uint256(uint256 x) public {
		vm.assume(x != uint256(0));
		assertEq(UINT256_SLOT.tload(), uint256(0));
		testTransientSlot(x);
	}

	function test_fuzz_transient_slot_int256(int256 x) public {
		vm.assume(x != int256(0));
		assertEq(INT256_SLOT.tload(), int256(0));
		testTransientSlot(x);
	}

	function test_fuzz_transient_slot_bytes(bytes memory x) public {
		vm.assume(x.length != uint256(0));
		assertEq(BYTES_SLOT.tlength(), uint256(0));
		testTransientSlot(x);
	}

	function test_fuzz_transient_slot_string(string memory x) public {
		vm.assume(bytes(x).length != uint256(0));
		assertEq(STRING_SLOT.tlength(), uint256(0));
		testTransientSlot(x);
	}

	function testStorageSlot(address x) internal {
		ADDRESS_SLOT.sstore(x);
		assertEq(ADDRESS_SLOT.sload(), x);
	}

	function testTransientSlot(address x) internal {
		ADDRESS_SLOT.tstore(x);
		assertEq(ADDRESS_SLOT.tload(), x);
	}

	function testStorageSlot(bool x) internal {
		BOOLEAN_SLOT.sstore(x);
		assertEq(BOOLEAN_SLOT.sload(), x);
	}

	function testTransientSlot(bool x) internal {
		BOOLEAN_SLOT.tstore(x);
		assertEq(BOOLEAN_SLOT.tload(), x);
	}

	function testStorageSlot(bytes32 x) internal {
		BYTES32_SLOT.sstore(x);
		assertEq(BYTES32_SLOT.sload(), x);
	}

	function testTransientSlot(bytes32 x) internal {
		BYTES32_SLOT.tstore(x);
		assertEq(BYTES32_SLOT.tload(), x);
	}

	function testStorageSlot(uint256 x) internal {
		UINT256_SLOT.sstore(x);
		assertEq(UINT256_SLOT.sload(), x);
	}

	function testTransientSlot(uint256 x) internal {
		UINT256_SLOT.tstore(x);
		assertEq(UINT256_SLOT.tload(), x);
	}

	function testStorageSlot(int256 x) internal {
		INT256_SLOT.sstore(x);
		assertEq(INT256_SLOT.sload(), x);
	}

	function testTransientSlot(int256 x) internal {
		INT256_SLOT.tstore(x);
		assertEq(INT256_SLOT.tload(), x);
	}

	function testStorageSlot(bytes memory x) internal {
		BYTES_SLOT.sstore(x);
		assertEq(BYTES_SLOT.slength(), x.length);
		assertEq(BYTES_SLOT.sload(), x);
	}

	function testTransientSlot(bytes memory x) internal {
		BYTES_SLOT.tstore(x);
		assertEq(BYTES_SLOT.tlength(), x.length);
		assertEq(BYTES_SLOT.tload(), x);
	}

	function testStorageSlot(string memory x) internal {
		STRING_SLOT.sstore(x);
		assertEq(STRING_SLOT.slength(), bytes(x).length);
		assertEq(STRING_SLOT.sload(), x);
	}

	function testTransientSlot(string memory x) internal {
		STRING_SLOT.tstore(x);
		assertEq(STRING_SLOT.tlength(), bytes(x).length);
		assertEq(STRING_SLOT.tload(), x);
	}

	function erc7201Slot(string memory namespace) internal pure returns (uint256 slot) {
		assembly ("memory-safe") {
			mstore(0x00, sub(keccak256(add(namespace, 0x20), mload(namespace)), 0x01))
			slot := and(keccak256(0x00, 0x20), not(0xff))
		}
	}
}
