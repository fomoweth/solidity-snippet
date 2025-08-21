// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC5267} from "src/interfaces/utils/IERC5267.sol";

/// @title EIP712
/// @notice Provides EIP-712 typed data signing functionality with multiple domain separator variants
/// @dev Modified from https://github.com/Vectorized/solady/blob/main/src/utils/EIP712.sol
/// @author fomoweth
abstract contract EIP712 is IERC5267 {
	/// @notice Precomputed EIP-712 domain typehash with all fields included
	/// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
	bytes32 internal constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

	/// @notice Precomputed EIP-712 domain typehash excluding version field
	/// @dev keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 internal constant DOMAIN_SANS_VERSION_TYPEHASH =
		0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	/// @notice Precomputed EIP-712 domain typehash excluding chain ID field
	/// @dev keccak256("EIP712Domain(string name,string version,address verifyingContract)")
	bytes32 internal constant DOMAIN_SANS_CHAIN_ID_TYPEHASH =
		0x91ab3d17e3a50a9d89e63fd30b92be7f5336b03b287bb946787a83a9d62a2766;

	/// @notice Precomputed EIP-712 domain typehash excluding verifying contract field
	/// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId)")
	bytes32 internal constant DOMAIN_SANS_VERIFYING_CONTRACT_TYPEHASH =
		0xc2f8787176b8ac6bf7215b4adcc1e069bf4ab82d9ab1df05a57a91d425935b6e;

	/// @notice Precomputed EIP-712 domain typehash excluding both chain ID and verifying contract
	/// @dev keccak256("EIP712Domain(string name,string version)")
	bytes32 internal constant DOMAIN_SANS_CHAIN_ID_AND_VERIFYING_CONTRACT_TYPEHASH =
		0xb03948446334eb9b2196d5eb166f69b9d49403eb4a12f36de8d3f9f3cb8e15c3;

	/// @notice Precomputed EIP-712 domain typehash excluding both name and version
	/// @dev keccak256("EIP712Domain(uint256 chainId,address verifyingContract)")
	bytes32 internal constant DOMAIN_SANS_NAME_AND_VERSION_TYPEHASH =
		0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

	/// @notice Cached contract address as uint256 for gas-efficient comparisons
	/// @dev Used to determine when domain separator needs recomputation
	uint256 private immutable _cachedThis;

	/// @notice Cached chain ID for detecting chain changes
	/// @dev Used to determine when domain separator needs recomputation
	uint256 private immutable _cachedChainId;

	/// @notice Cached hash of domain name for domain separator computation
	/// @dev Avoids repeated string hashing operations
	bytes32 private immutable _cachedNameHash;

	/// @notice Cached hash of version string for domain separator computation
	/// @dev Avoids repeated string hashing operations
	bytes32 private immutable _cachedVersionHash;

	/// @notice Cached domain separator for original deployment context
	/// @dev Used when chain ID and contract address haven't changed
	bytes32 private immutable _cachedDomainSeparator;

	/// @notice Initializes EIP-712 domain with cached values
	constructor() {
		_cachedThis = uint256(uint160(address(this)));
		_cachedChainId = block.chainid;

		if (!_domainNameAndVersionMayChange()) {
			(string memory name, string memory version) = _domainNameAndVersion();

			_cachedDomainSeparator = _computeDomainSeparator(
				_cachedNameHash = keccak256(bytes(name)),
				_cachedVersionHash = keccak256(bytes(version))
			);
		}
	}

	/// @inheritdoc IERC5267
	function eip712Domain()
		public
		view
		virtual
		returns (
			bytes1 fields,
			string memory name,
			string memory version,
			uint256 chainId,
			address verifyingContract,
			bytes32 salt,
			uint256[] memory extensions
		)
	{
		(name, version) = _domainNameAndVersion();
		assembly ("memory-safe") {
			fields := hex"0f" // 01111
			chainId := chainid()
			verifyingContract := address()
			pop(salt)
			pop(extensions)
		}
	}

	/// @notice Returns the domain separator for the current chain
	/// @dev Recomputes if cached values have become stale
	/// @return separator Current domain separator (cached or recomputed)
	function _domainSeparator() internal view virtual returns (bytes32 separator) {
		if (_domainNameAndVersionMayChange()) {
			(string memory name, string memory version) = _domainNameAndVersion();
			separator = _computeDomainSeparator(keccak256(bytes(name)), keccak256(bytes(version)));
		} else {
			separator = _isDomainSeparatorStale()
				? _computeDomainSeparator(_cachedNameHash, _cachedVersionHash)
				: _cachedDomainSeparator;
		}
	}

	/// @notice Returns the hash of the fully encoded EIP712 message for this domain
	/// @dev See: https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct]
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		digest = _domainSeparator();
		assembly ("memory-safe") {
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x00, 0x1901000000000000)
			mstore(0x1a, digest) // domain separator
			mstore(0x3a, structHash)
			digest := keccak256(0x18, 0x42)
			mstore(0x3a, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting version in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansVersion(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		(string memory name, ) = _domainNameAndVersion();
		assembly ("memory-safe") {
			// Build domain separator with without version
			let ptr := mload(0x40)
			mstore(0x00, DOMAIN_SANS_VERSION_TYPEHASH)
			mstore(0x20, keccak256(add(name, 0x20), mload(name)))
			mstore(0x40, chainid())
			mstore(0x60, address())
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x20, keccak256(0x00, 0x80)) // domain separator
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			digest := keccak256(0x1e, 0x42)
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting chain ID in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansChainId(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		(string memory name, string memory version) = _domainNameAndVersion();
		assembly ("memory-safe") {
			// Build domain separator without chain ID
			let ptr := mload(0x40)
			mstore(0x00, DOMAIN_SANS_CHAIN_ID_TYPEHASH)
			mstore(0x20, keccak256(add(name, 0x20), mload(name)))
			mstore(0x40, keccak256(add(version, 0x20), mload(version)))
			mstore(0x60, address())
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x20, keccak256(0x00, 0x80)) // domain separator
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			digest := keccak256(0x1e, 0x42)
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting verifying contract in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansVerifyingContract(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		(string memory name, string memory version) = _domainNameAndVersion();
		assembly ("memory-safe") {
			// Build domain separator without verifying contract
			let ptr := mload(0x40)
			mstore(0x00, DOMAIN_SANS_VERIFYING_CONTRACT_TYPEHASH)
			mstore(0x20, keccak256(add(name, 0x20), mload(name)))
			mstore(0x40, keccak256(add(version, 0x20), mload(version)))
			mstore(0x60, chainid())
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x20, keccak256(0x00, 0x80)) // domain separator
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			digest := keccak256(0x1e, 0x42)
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting both chain ID and verifying contract in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansChainIdAndVerifyingContract(
		bytes32 structHash
	) internal view virtual returns (bytes32 digest) {
		(string memory name, string memory version) = _domainNameAndVersion();
		assembly ("memory-safe") {
			// Build domain separator without chain ID and verifying contract
			let ptr := mload(0x40)
			mstore(0x00, DOMAIN_SANS_CHAIN_ID_AND_VERIFYING_CONTRACT_TYPEHASH)
			mstore(0x20, keccak256(add(name, 0x20), mload(name)))
			mstore(0x40, keccak256(add(version, 0x20), mload(version)))
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x20, keccak256(0x00, 0x60)) // domain separator
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			digest := keccak256(0x1e, 0x42)
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting both name and version in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansNameAndVersion(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		assembly ("memory-safe") {
			// Build domain separator without name and version
			let ptr := mload(0x40)
			mstore(0x00, DOMAIN_SANS_NAME_AND_VERSION_TYPEHASH)
			mstore(0x20, chainid())
			mstore(0x40, address())
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x20, keccak256(0x00, 0x60)) // domain separator
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			digest := keccak256(0x1e, 0x42)
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Computes the EIP-712 domain separator
	/// @param nameHash Hash of the domain name string
	/// @param versionHash Hash of the domain version string
	/// @return digest The computed domain separator
	function _computeDomainSeparator(bytes32 nameHash, bytes32 versionHash) private view returns (bytes32 digest) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)
			mstore(ptr, DOMAIN_TYPEHASH)
			mstore(add(ptr, 0x20), nameHash)
			mstore(add(ptr, 0x40), versionHash)
			mstore(add(ptr, 0x60), chainid())
			mstore(add(ptr, 0x80), address())
			digest := keccak256(ptr, 0xa0)
		}
	}

	/// @notice Determines if the cached domain separator needs to be recomputed due to context changes
	/// @dev Returns true if either chain ID or contract address differs from cached values
	/// @return result True if domain separator is stale and needs recomputation, false if cached value is still valid
	function _isDomainSeparatorStale() private view returns (bool result) {
		uint256 cachedChainId = _cachedChainId;
		uint256 cachedThis = _cachedThis;
		assembly ("memory-safe") {
			result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
		}
	}

	/// @notice Returns the domain name and version
	/// @dev Must be implemented by inheriting contracts to provide domain metadata
	/// @return name The domain name string
	/// @return version The domain version string
	function _domainNameAndVersion() internal view virtual returns (string memory name, string memory version);

	/// @notice Returns if {_domainNameAndVersion} may change after the deployment (default to false)
	function _domainNameAndVersionMayChange() internal pure virtual returns (bool result) {}
}
