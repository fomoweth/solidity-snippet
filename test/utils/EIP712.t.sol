// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VmSafe} from "forge-std/Vm.sol";
import {MockEIP712, MockEIP712Dynamic} from "test/shared/mocks/MockEIP712.sol";
import {PermitUtils} from "test/shared/utils/PermitUtils.sol";
import {BaseTest} from "test/shared/env/BaseTest.sol";

contract EIP712Test is BaseTest {
	using PermitUtils for PermitUtils.DomainField;

	MockEIP712 internal mockStatic;
	MockEIP712Dynamic internal mockDynamic;

	VmSafe.Wallet internal cooper;
	VmSafe.Wallet internal murphy;

	function setUp() public virtual {
		mockStatic = new MockEIP712();
		mockDynamic = new MockEIP712Dynamic("Mock EIP-712 Dynamic", "1");

		cooper = vm.createWallet("cooper");
		murphy = vm.createWallet("murphy");
	}

	function test_eip712Domain() public view {
		_checkEip712Domain(mockStatic, "Mock EIP-712 Static", "1");
		_checkEip712Domain(mockDynamic, "Mock EIP-712 Dynamic", "1");
	}

	function test_cachedDomainSeparator() public view {
		_checkDomainSeparator(mockStatic);
		_checkDomainSeparator(mockDynamic);
	}

	function test_domainSeparator() public {
		_checkDomainSeparator(mockStatic);
		_checkDomainSeparator(mockDynamic);
		vm.chainId(1);
		_checkDomainSeparator(mockStatic);
		_checkDomainSeparator(mockDynamic);
		mockDynamic.setDomainNameAndVersion("Mock EIP-712", "2");
		_checkDomainSeparator(mockDynamic);
	}

	function test_domainSeparator_recompute() public {
		_checkDomainSeparator(mockStatic);
		_checkDomainSeparator(mockDynamic);
		vm.chainId(1);
		_checkDomainSeparator(mockStatic);
		_checkDomainSeparator(mockDynamic);
		mockDynamic.setDomainNameAndVersion("Mock EIP-712", "2");
		_checkDomainSeparator(mockDynamic);
	}

	function test_hashTypedData() public {
		_testHashTypedData(mockStatic);
		_testHashTypedData(mockDynamic);
		vm.chainId(1);
		_testHashTypedData(mockStatic);
		_testHashTypedData(mockDynamic);
	}

	function test_hashTypedDataSansChainId() public {
		_testHashTypedDataSansChainId(mockStatic);
		_testHashTypedDataSansChainId(mockDynamic);
	}

	function test_hashTypedDataSansVerifyingContract() public {
		_testHashTypedDataSansVerifyingContract(mockStatic);
		_testHashTypedDataSansVerifyingContract(mockDynamic);
	}

	function test_hashTypedDataSansVersion() public {
		_testHashTypedDataSansVersion(mockStatic);
		_testHashTypedDataSansVersion(mockDynamic);
	}

	function test_hashTypedDataSansChainIdAndVerifyingContract() public {
		_testHashTypedDataSansChainIdAndVerifyingContract(mockStatic);
		_testHashTypedDataSansChainIdAndVerifyingContract(mockDynamic);
	}

	function test_hashTypedDataSansNameAndVersion() public {
		_testHashTypedDataSansNameAndVersion(mockStatic);
		_testHashTypedDataSansNameAndVersion(mockDynamic);
	}

	function _testHashTypedData(MockEIP712 mock) internal virtual {
		bytes32 separator = mock.DOMAIN_SEPARATOR();
		bytes32 messageHash = _hashMessage("Gravity Equation", cooper.addr, separator, mock.hashTypedData);
		_checkSigner(murphy, messageHash);
	}

	function _testHashTypedDataSansChainId(MockEIP712 mock) internal virtual {
		PermitUtils.DomainField memory domain;
		(, domain.name, domain.version, , domain.verifyingContract, , ) = mock.eip712Domain();

		bytes32 separator = domain.hash();
		bytes32 messageHash = _hashMessage("Gravity Equation", cooper.addr, separator, mock.hashTypedDataSansChainId);
		_checkSigner(murphy, messageHash);
	}

	function _testHashTypedDataSansVerifyingContract(MockEIP712 mock) internal virtual {
		PermitUtils.DomainField memory domain;
		(, domain.name, domain.version, domain.chainId, , , ) = mock.eip712Domain();

		bytes32 separator = domain.hash();
		bytes32 messageHash = _hashMessage(
			"Gravity Equation",
			cooper.addr,
			separator,
			mock.hashTypedDataSansVerifyingContract
		);
		_checkSigner(murphy, messageHash);
	}

	function _testHashTypedDataSansVersion(MockEIP712 mock) internal virtual {
		PermitUtils.DomainField memory domain;
		(, domain.name, , domain.chainId, domain.verifyingContract, , ) = mock.eip712Domain();

		bytes32 separator = domain.hash();
		bytes32 messageHash = _hashMessage("Gravity Equation", cooper.addr, separator, mock.hashTypedDataSansVersion);
		_checkSigner(murphy, messageHash);
	}

	function _testHashTypedDataSansChainIdAndVerifyingContract(MockEIP712 mock) internal virtual {
		PermitUtils.DomainField memory domain;
		(domain.name, domain.version) = mock.domainNameAndVersion();

		bytes32 separator = domain.hash();
		bytes32 messageHash = _hashMessage(
			"Gravity Equation",
			cooper.addr,
			separator,
			mock.hashTypedDataSansChainIdAndVerifyingContract
		);
		_checkSigner(murphy, messageHash);
	}

	function _testHashTypedDataSansNameAndVersion(MockEIP712 mock) internal virtual {
		PermitUtils.DomainField memory domain;
		domain.chainId = block.chainid;
		domain.verifyingContract = address(mock);

		bytes32 separator = domain.hash();
		bytes32 messageHash = _hashMessage("Gravity Equation", cooper.addr, separator, mock.hashTypedDataSansNameAndVersion);
		_checkSigner(murphy, messageHash);
	}

	function _hashMessage(
		string memory message,
		address recipient,
		bytes32 separator,
		function(bytes32) external view returns (bytes32) hashTypedData
	) internal virtual returns (bytes32 messageHash) {
		bytes32 structHash = keccak256(abi.encode("Message(address recipient,string message)", recipient, message));
		assertEq(hashTypedData(structHash), messageHash = keccak256(abi.encodePacked("\x19\x01", separator, structHash)));
	}

	function _checkEip712Domain(MockEIP712 mock, string memory expectedName, string memory expectedVersion) internal view {
		(
			bytes1 fields,
			string memory name,
			string memory version,
			uint256 chainId,
			address verifyingContract,
			bytes32 salt,
			uint256[] memory extensions
		) = mock.eip712Domain();

		assertEq(fields, bytes1(0x0f));
		assertEq(name, expectedName);
		assertEq(version, expectedVersion);
		assertEq(chainId, block.chainid);
		assertEq(verifyingContract, address(mock));
		assertEq(salt, bytes32(0));
		assertEq(extensions, new uint256[](0));
	}

	function _checkDomainSeparator(MockEIP712 mock) internal view {
		PermitUtils.DomainField memory domain;
		(, domain.name, domain.version, domain.chainId, domain.verifyingContract, , ) = mock.eip712Domain();
		assertEq(mock.DOMAIN_SEPARATOR(), domain.hash());
	}

	function _checkSigner(VmSafe.Wallet memory signer, bytes32 messageHash) internal pure {
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(signer.privateKey, messageHash);
		assertEq(ecrecover(messageHash, v, r, s), signer.addr);
	}
}
