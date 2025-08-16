// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Vm} from "forge-std/Vm.sol";
import {IPermit2} from "permit2/interfaces/IPermit2.sol";

library PermitUtils {
	enum PermitKind {
		EIP2621,
		Allowed
	}

	struct DomainField {
		string name;
		string version;
		uint256 chainId;
		address verifyingContract;
	}

	struct PermitField {
		PermitKind kind;
		address owner;
		address spender;
		uint256 value;
		uint256 nonce;
		uint256 deadline;
	}

	Vm internal constant VM = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

	string internal constant DOMAIN_NOTATION =
		"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
	bytes32 internal constant DOMAIN_TYPEHASH = keccak256(bytes(DOMAIN_NOTATION));

	string internal constant DOMAIN_SANS_CHAIN_ID_NOTATION =
		"EIP712Domain(string name,string version,address verifyingContract)";
	bytes32 internal constant DOMAIN_SANS_CHAIN_ID_TYPEHASH = keccak256(bytes(DOMAIN_SANS_CHAIN_ID_NOTATION));

	string internal constant DOMAIN_SANS_VERIFYING_CONTRACT_NOTATION =
		"EIP712Domain(string name,string version,uint256 chainId)";
	bytes32 internal constant DOMAIN_SANS_VERIFYING_CONTRACT_TYPEHASH =
		keccak256(bytes(DOMAIN_SANS_VERIFYING_CONTRACT_NOTATION));

	string internal constant DOMAIN_SANS_VERSION_NOTATION =
		"EIP712Domain(string name,uint256 chainId,address verifyingContract)";
	bytes32 internal constant DOMAIN_SANS_VERSION_TYPEHASH = keccak256(bytes(DOMAIN_SANS_VERSION_NOTATION));

	string internal constant DOMAIN_SANS_CHAIN_ID_AND_VERIFYING_CONTRACT_NOTATION =
		"EIP712Domain(string name,string version)";
	bytes32 internal constant DOMAIN_SANS_CHAIN_ID_AND_VERIFYING_CONTRACT_TYPEHASH =
		keccak256(bytes(DOMAIN_SANS_CHAIN_ID_AND_VERIFYING_CONTRACT_NOTATION));

	string internal constant DOMAIN_SANS_NAME_AND_VERSION_NOTATION =
		"EIP712Domain(uint256 chainId,address verifyingContract)";
	bytes32 internal constant DOMAIN_SANS_NAME_AND_VERSION_TYPEHASH =
		keccak256(bytes(DOMAIN_SANS_NAME_AND_VERSION_NOTATION));

	string internal constant PERMIT_EIP2621_NOTATION =
		"Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)";
	bytes32 internal constant PERMIT_EIP2621_TYPEHASH = keccak256(bytes(PERMIT_EIP2621_NOTATION));

	string internal constant PERMIT_ALLOWED_NOTATION =
		"Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)";
	bytes32 internal constant PERMIT_ALLOWED_TYPEHASH = keccak256(bytes(PERMIT_ALLOWED_NOTATION));

	string internal constant PERMIT_DETAILS_NOTATION =
		"PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)";
	bytes32 internal constant PERMIT_DETAILS_TYPEHASH = keccak256(bytes(PERMIT_DETAILS_NOTATION));

	string internal constant PERMIT_SINGLE_NOTATION =
		"PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)";
	bytes32 internal constant PERMIT_SINGLE_TYPEHASH = keccak256(bytes(PERMIT_SINGLE_NOTATION));

	string internal constant PERMIT_BATCH_NOTATION =
		"PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)";
	bytes32 internal constant PERMIT_BATCH_TYPEHASH = keccak256(bytes(PERMIT_BATCH_NOTATION));

	function signPermit(
		PermitField memory params,
		bytes32 separator,
		uint256 privateKey
	) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
		bytes32 structHash = hash(params);
		bytes32 messageHash = keccak256(abi.encodePacked("\x19\x01", separator, structHash));
		(v, r, s) = VM.sign(privateKey, messageHash);
	}

	function signPermit(
		IPermit2.PermitSingle memory params,
		bytes32 separator,
		uint256 privateKey
	) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
		bytes32 structHash = hash(params);
		bytes32 messageHash = keccak256(abi.encodePacked("\x19\x01", separator, structHash));
		(v, r, s) = VM.sign(privateKey, messageHash);
	}

	function signPermit(
		IPermit2.PermitBatch memory params,
		bytes32 separator,
		uint256 privateKey
	) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
		bytes32 structHash = hash(params);
		bytes32 messageHash = keccak256(abi.encodePacked("\x19\x01", separator, structHash));
		(v, r, s) = VM.sign(privateKey, messageHash);
	}

	function hash(DomainField memory params) internal pure returns (bytes32 digest) {
		return
			keccak256(
				params.chainId == 0 && params.verifyingContract == address(0)
					? abi.encode(
						DOMAIN_SANS_CHAIN_ID_AND_VERIFYING_CONTRACT_TYPEHASH,
						keccak256(bytes(params.name)),
						keccak256(bytes(params.version))
					)
					: params.chainId == 0
					? abi.encode(
						DOMAIN_SANS_CHAIN_ID_TYPEHASH,
						keccak256(bytes(params.name)),
						keccak256(bytes(params.version)),
						params.verifyingContract
					)
					: params.verifyingContract == address(0)
					? abi.encode(
						DOMAIN_SANS_VERIFYING_CONTRACT_TYPEHASH,
						keccak256(bytes(params.name)),
						keccak256(bytes(params.version)),
						params.chainId
					)
					: bytes(params.name).length == 0 && bytes(params.version).length == 0
					? abi.encode(DOMAIN_SANS_NAME_AND_VERSION_TYPEHASH, params.chainId, params.verifyingContract)
					: bytes(params.version).length == 0
					? abi.encode(
						DOMAIN_SANS_VERSION_TYPEHASH,
						keccak256(bytes(params.name)),
						params.chainId,
						params.verifyingContract
					)
					: abi.encode(
						DOMAIN_TYPEHASH,
						keccak256(bytes(params.name)),
						keccak256(bytes(params.version)),
						params.chainId,
						params.verifyingContract
					)
			);
	}

	function hash(PermitField memory params) internal pure returns (bytes32 digest) {
		return
			keccak256(
				params.kind == PermitKind.EIP2621
					? abi.encode(
						PERMIT_EIP2621_TYPEHASH,
						params.owner,
						params.spender,
						params.value,
						params.nonce,
						params.deadline
					)
					: abi.encode(
						PERMIT_ALLOWED_TYPEHASH,
						params.owner,
						params.spender,
						params.nonce,
						params.deadline,
						params.value != 0 ? true : false
					)
			);
	}

	function hash(IPermit2.PermitSingle memory params) internal pure returns (bytes32 digest) {
		return
			keccak256(
				abi.encode(PERMIT_SINGLE_TYPEHASH, _hashPermitDetails(params.details), params.spender, params.sigDeadline)
			);
	}

	function hash(IPermit2.PermitBatch memory params) internal pure returns (bytes32 digest) {
		return
			keccak256(
				abi.encode(PERMIT_BATCH_TYPEHASH, _hashPermitDetails(params.details), params.spender, params.sigDeadline)
			);
	}

	function _hashPermitDetails(IPermit2.PermitDetails memory params) private pure returns (bytes32 digest) {
		return keccak256(abi.encode(PERMIT_DETAILS_TYPEHASH, params));
	}

	function _hashPermitDetails(IPermit2.PermitDetails[] memory params) private pure returns (bytes32 digest) {
		uint256 length = params.length;
		bytes32[] memory hashes = new bytes32[](length);
		for (uint256 i; i < length; ++i) hashes[i] = _hashPermitDetails(params[i]);
		return keccak256(abi.encodePacked(hashes));
	}
}
