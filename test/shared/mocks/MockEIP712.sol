// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {EIP712} from "src/utils/EIP712.sol";

contract MockEIP712 is EIP712 {
	function DOMAIN_SEPARATOR() public view returns (bytes32 separator) {
		return _domainSeparator();
	}

	function domainNameAndVersion() public view returns (string memory name, string memory version) {
		return _domainNameAndVersion();
	}

	function _domainNameAndVersion() internal view virtual override returns (string memory name, string memory version) {
		name = "Mock EIP-712 Static";
		version = "1";
	}

	function hashTypedData(bytes32 structHash) external view returns (bytes32 digest) {
		return _hashTypedData(structHash);
	}

	function hashTypedDataSansChainId(bytes32 structHash) external view returns (bytes32 digest) {
		return _hashTypedDataSansChainId(structHash);
	}

	function hashTypedDataSansVerifyingContract(bytes32 structHash) external view returns (bytes32 digest) {
		return _hashTypedDataSansVerifyingContract(structHash);
	}

	function hashTypedDataSansVersion(bytes32 structHash) external view returns (bytes32 digest) {
		return _hashTypedDataSansVersion(structHash);
	}

	function hashTypedDataSansChainIdAndVerifyingContract(bytes32 structHash) external view returns (bytes32 digest) {
		return _hashTypedDataSansChainIdAndVerifyingContract(structHash);
	}

	function hashTypedDataSansNameAndVersion(bytes32 structHash) external view returns (bytes32 digest) {
		return _hashTypedDataSansNameAndVersion(structHash);
	}
}

contract MockEIP712Dynamic is MockEIP712 {
	string private _name;
	string private _version;

	constructor(string memory name, string memory version) {
		setDomainNameAndVersion(name, version);
	}

	function setDomainNameAndVersion(string memory name, string memory version) public {
		_name = name;
		_version = version;
	}

	function _domainNameAndVersion() internal view virtual override returns (string memory name, string memory version) {
		name = _name;
		version = _version;
	}

	function _domainNameAndVersionMayChange() internal pure virtual override returns (bool) {
		return true;
	}
}
