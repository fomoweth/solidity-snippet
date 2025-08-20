// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/proxy/transparent/ProxyAdmin.sol";
import {Static} from "./Static.sol";

library ProxyUtils {
	bytes32 internal constant ERC1967_ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

	bytes32 internal constant ERC1967_IMPLEMENTATION_SLOT =
		0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	function deploy(address initialOwner, address implementation, bytes memory data) internal returns (address proxy) {
		return deploy(initialOwner, implementation, data, uint256(0));
	}

	function deploy(
		address initialOwner,
		address implementation,
		bytes memory data,
		uint256 value
	) internal returns (address proxy) {
		return address(new TransparentUpgradeableProxy{value: value}(implementation, initialOwner, data));
	}

	function deploy(
		address initialOwner,
		address implementation,
		bytes memory data,
		bytes32 salt
	) internal returns (address proxy) {
		return deploy(initialOwner, implementation, data, salt, uint256(0));
	}

	function deploy(
		address initialOwner,
		address implementation,
		bytes memory data,
		bytes32 salt,
		uint256 value
	) internal returns (address proxy) {
		return address(new TransparentUpgradeableProxy{salt: salt, value: value}(implementation, initialOwner, data));
	}

	function upgrade(address proxy, address implementation) internal {
		upgrade(proxy, implementation, "", uint256(0));
	}

	function upgrade(address proxy, address implementation, bytes memory data) internal {
		upgrade(proxy, implementation, data, uint256(0));
	}

	function upgrade(address proxy, address implementation, bytes memory data, uint256 value) internal {
		ProxyAdmin admin = getProxyAdmin(proxy);
		Static.VM.prank(admin.owner());
		admin.upgradeAndCall{value: value}(ITransparentUpgradeableProxy(proxy), implementation, data);
	}

	function getImplementation(address proxy) internal view returns (address implementation) {
		return address(uint160(uint256(Static.VM.load(proxy, ERC1967_IMPLEMENTATION_SLOT))));
	}

	function getProxyAdmin(address proxy) internal view returns (ProxyAdmin admin) {
		return ProxyAdmin(address(uint160(uint256(Static.VM.load(proxy, ERC1967_ADMIN_SLOT)))));
	}

	function computeProxyAdminAddress(address proxy) internal pure returns (address) {
		return Static.VM.computeCreateAddress(proxy, 1);
	}

	function computeProxyAddress(address deployer) internal view returns (address proxy) {
		return Static.VM.computeCreateAddress(deployer, Static.VM.getNonce(deployer));
	}

	function computeProxyAddress(address deployer, uint256 nonce) internal pure returns (address proxy) {
		return Static.VM.computeCreateAddress(deployer, nonce);
	}

	function computeProxyAddress(
		address deployer,
		address initialOwner,
		address implementation,
		bytes memory data,
		bytes32 salt
	) internal pure returns (address proxy) {
		bytes memory bytecode = type(TransparentUpgradeableProxy).creationCode;
		bytes memory args = abi.encode(implementation, initialOwner, data);
		bytes memory initCode = bytes.concat(bytecode, args);
		return Static.VM.computeCreate2Address(salt, keccak256(initCode), deployer);
	}
}
