// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Static} from "./Static.sol";

library Deployer {
	function deploy(bytes memory initCode) internal returns (address instance) {
		return deploy(initCode, uint256(0));
	}

	function deploy(bytes memory initCode, uint256 value) internal returns (address instance) {
		return deploy(initCode, value, bytes32(0), false);
	}

	function deploy(bytes memory initCode, bytes32 salt) internal returns (address instance) {
		return deploy(initCode, salt, uint256(0));
	}

	function deploy(bytes memory initCode, bytes32 salt, uint256 value) internal returns (address instance) {
		return deploy(initCode, value, salt, true);
	}

	function deploy(
		bytes memory initCode,
		uint256 value,
		bytes32 salt,
		bool isDeterministic
	) internal returns (address instance) {
		assembly ("memory-safe") {
			switch isDeterministic
			case 0x00 {
				instance := create(value, add(initCode, 0x20), mload(initCode))
			}
			case 0x01 {
				instance := create2(value, add(initCode, 0x20), mload(initCode), salt)
			}

			if iszero(shl(0x60, instance)) {
				let ptr := mload(0x40)
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}

	function computeAddress(bytes memory initCode, bytes32 salt, address deployer) internal pure returns (address instance) {
		return computeAddress(keccak256(initCode), salt, deployer);
	}

	function computeAddress(bytes32 initCodeHash, bytes32 salt, address deployer) internal pure returns (address instance) {
		return Static.VM.computeCreate2Address(salt, initCodeHash, deployer);
	}

	function computeAddress(address deployer) internal view returns (address instance) {
		return computeAddress(deployer, Static.VM.getNonce(deployer));
	}

	function computeAddress(address deployer, uint256 nonce) internal pure returns (address instance) {
		return Static.VM.computeCreateAddress(deployer, nonce);
	}
}
