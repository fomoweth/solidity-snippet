// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MessageHashUtils as OzMessageHashUtils} from "@openzeppelin/utils/cryptography/MessageHashUtils.sol";
import {MessageHashUtils} from "src/libraries/MessageHashUtils.sol";

contract MessageHashUtilsTest is Test {
	function test_fuzz_toEthSignedMessageHash(bytes32 messageHash) public pure {
		assertEq(
			MessageHashUtils.toEthSignedMessageHash(messageHash),
			OzMessageHashUtils.toEthSignedMessageHash(messageHash)
		);
	}

	function test_fuzz_toEthSignedMessageHash(bytes memory message) public pure {
		assertEq(MessageHashUtils.toEthSignedMessageHash(message), OzMessageHashUtils.toEthSignedMessageHash(message));
	}

	function test_fuzz_toDataWithIntendedValidatorHash(address validator, bytes memory data) public pure {
		assertEq(
			MessageHashUtils.toDataWithIntendedValidatorHash(validator, data),
			OzMessageHashUtils.toDataWithIntendedValidatorHash(validator, data)
		);
	}

	function test_fuzz_toDataWithIntendedValidatorHash(address validator, bytes32 messageHash) public pure {
		assertEq(
			MessageHashUtils.toDataWithIntendedValidatorHash(validator, messageHash),
			OzMessageHashUtils.toDataWithIntendedValidatorHash(validator, messageHash)
		);
	}

	function test_fuzz_toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) public pure {
		assertEq(
			MessageHashUtils.toTypedDataHash(domainSeparator, structHash),
			OzMessageHashUtils.toTypedDataHash(domainSeparator, structHash)
		);
	}
}
