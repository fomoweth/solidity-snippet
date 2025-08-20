// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title EIP712
/// @notice Provides EIP-712 typed data signing functionality with multiple domain separator variants
/// @dev Modified from Solady: https://github.com/Vectorized/solady/blob/main/src/utils/EIP712.sol
/// @author fomoweth
abstract contract EIP712 {
	/// @notice Precomputed EIP-712 domain typehash with all fields included
	/// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
	bytes32 private constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

	/// @notice Precomputed EIP-712 domain typehash excluding chain ID field
	/// @dev keccak256("EIP712Domain(string name,string version,address verifyingContract)")
	bytes32 private constant DOMAIN_SANS_CHAIN_ID_TYPEHASH =
		0x91ab3d17e3a50a9d89e63fd30b92be7f5336b03b287bb946787a83a9d62a2766;

	/// @notice Precomputed EIP-712 domain typehash excluding verifying contract field
	/// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId)")
	bytes32 private constant DOMAIN_SANS_VERIFYING_CONTRACT_TYPEHASH =
		0xc2f8787176b8ac6bf7215b4adcc1e069bf4ab82d9ab1df05a57a91d425935b6e;

	/// @notice Precomputed EIP-712 domain typehash excluding name field
	/// @dev keccak256("EIP712Domain(string version,uint256 chainId,address verifyingContract)")
	bytes32 private constant DOMAIN_SANS_NAME_TYPEHASH = 0x2aef22f9d7df5f9d21c56d14029233f3fdaa91917727e1eb68e504d27072d6cd;

	/// @notice Precomputed EIP-712 domain typehash excluding version field
	/// @dev keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 private constant DOMAIN_SANS_VERSION_TYPEHASH =
		0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	/// @notice Precomputed EIP-712 domain typehash excluding both chain ID and verifying contract
	/// @dev keccak256("EIP712Domain(string name,string version)")
	bytes32 private constant DOMAIN_SANS_CHAIN_ID_AND_VERIFYING_CONTRACT_TYPEHASH =
		0xb03948446334eb9b2196d5eb166f69b9d49403eb4a12f36de8d3f9f3cb8e15c3;

	/// @notice Precomputed EIP-712 domain typehash excluding both name and version
	/// @dev keccak256("EIP712Domain(uint256 chainId,address verifyingContract)")
	bytes32 private constant DOMAIN_SANS_NAME_AND_VERSION_TYPEHASH =
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
	/// @dev Inheriting contracts must implement {_domainNameAndVersion} to provide domain metadata
	constructor() {
		// Get domain metadata from inheriting contract
		(string memory name, string memory version) = _domainNameAndVersion();

		// Cache all domain components and compute initial domain separator
		_cachedDomainSeparator = _computeDomainSeparator(
			_cachedNameHash = keccak256(bytes(name)),
			_cachedVersionHash = keccak256(bytes(version)),
			_cachedChainId = block.chainid,
			_cachedThis = uint256(uint160(address(this)))
		);
	}

	/// @notice Returns the fields and values that describe the domain separator used by this contract for EIP-712 signature
	/// @dev Implements EIP-5267 for domain introspection and wallet compatibility
	/// @dev See: https://eips.ethereum.org/EIPS/eip-5267
	/// @return fields Bitmap indicating which fields are used (0x0f = name, version, chainId, verifyingContract)
	/// @return name Domain name string
	/// @return version Domain version string
	/// @return chainId Current chain identifier
	/// @return verifyingContract Current contract address
	/// @return salt Always zero (not used)
	/// @return extensions Always empty (not used)
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
			// Set fields bitmap: 0x0f indicates name, version, chainId, and verifyingContract are used
			fields := hex"0f"
			chainId := chainid()
			verifyingContract := address()
			// Remove salt and extensions from stack (not used)
			pop(salt)
			pop(extensions)
		}
	}

	/// @notice Returns the domain separator for the current chain
	/// @dev Recomputes if cached values have become stale
	/// @return separator Current domain separator (cached or recomputed)
	function _domainSeparator() internal view virtual returns (bytes32 separator) {
		separator = _isDomainSeparatorStale()
			? _computeDomainSeparator(_cachedNameHash, _cachedVersionHash, _cachedChainId, _cachedThis)
			: _cachedDomainSeparator;
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
			// Hash 66 bytes starting from 0x18 (24 bytes from start to skip padding)
			digest := keccak256(0x18, 0x42)
			// Clean up: zero out struct hash slot
			mstore(0x3a, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting chain ID in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansChainId(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		bytes32 nameHash = _cachedNameHash;
		digest = _cachedVersionHash;
		assembly ("memory-safe") {
			// Load free memory pointer
			let ptr := mload(0x40)
			// Build domain separator without chain ID
			mstore(0x00, DOMAIN_SANS_CHAIN_ID_TYPEHASH)
			mstore(0x20, nameHash)
			mstore(0x40, digest) // Version hash
			mstore(0x60, address())
			// Compute domain separator (128 bytes total)
			mstore(0x20, keccak256(0x00, 0x80))
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			// Hash 66 bytes starting from 0x1e (30 bytes from start to skip padding)
			digest := keccak256(0x1e, 0x42)
			// Restore memory pointers
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting verifying contract in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansVerifyingContract(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		bytes32 nameHash = _cachedNameHash;
		digest = _cachedVersionHash;
		assembly ("memory-safe") {
			// Load free memory pointer
			let ptr := mload(0x40)
			// Build domain separator without verifying contract
			mstore(0x00, DOMAIN_SANS_VERIFYING_CONTRACT_TYPEHASH)
			mstore(0x20, nameHash)
			mstore(0x40, digest) // Version hash
			mstore(0x60, chainid())
			// Compute domain separator (128 bytes total)
			mstore(0x20, keccak256(0x00, 0x80))
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			// Hash 66 bytes starting from 0x1e (30 bytes from start to skip padding)
			digest := keccak256(0x1e, 0x42)
			// Restore memory pointers
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting name in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansName(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		digest = _cachedVersionHash;
		assembly ("memory-safe") {
			// Load free memory pointer
			let ptr := mload(0x40)
			// Build domain separator with without name
			mstore(0x00, DOMAIN_SANS_NAME_TYPEHASH)
			mstore(0x20, digest) // Version hash
			mstore(0x40, chainid())
			mstore(0x60, address())
			// Compute domain separator (128 bytes total)
			mstore(0x20, keccak256(0x00, 0x80))
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			// Hash 66 bytes starting from 0x1e (30 bytes from start to skip padding)
			digest := keccak256(0x1e, 0x42)
			// Restore memory pointers
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting version in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansVersion(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		digest = _cachedNameHash;
		assembly ("memory-safe") {
			// Load free memory pointer
			let ptr := mload(0x40)
			// Build domain separator with without version
			mstore(0x00, DOMAIN_SANS_VERSION_TYPEHASH)
			mstore(0x20, digest) // Name hash
			mstore(0x40, chainid())
			mstore(0x60, address())
			// Compute domain separator (128 bytes total)
			mstore(0x20, keccak256(0x00, 0x80))
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			// Hash 66 bytes starting from 0x1e (30 bytes from start to skip padding)
			digest := keccak256(0x1e, 0x42)
			// Restore memory pointers
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
		bytes32 nameHash = _cachedNameHash;
		digest = _cachedVersionHash;
		assembly ("memory-safe") {
			// Load free memory pointer
			let ptr := mload(0x40)
			// Build domain separator without chain ID and verifying contract
			mstore(0x00, DOMAIN_SANS_CHAIN_ID_AND_VERIFYING_CONTRACT_TYPEHASH)
			mstore(0x20, nameHash)
			mstore(0x40, digest) // Version hash
			// Compute domain separator (96 bytes total)
			mstore(0x20, keccak256(0x00, 0x60))
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			// Hash 66 bytes starting from 0x1e (30 bytes from start to skip padding)
			digest := keccak256(0x1e, 0x42)
			// Restore memory pointers
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Variant of {_hashTypedData} omitting both name and version in the domain
	/// @param structHash Hash of the struct data being signed
	/// @return digest Final message digest ready for signing
	function _hashTypedDataSansNameAndVersion(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		assembly ("memory-safe") {
			// Load free memory pointer
			let ptr := mload(0x40)
			// Build domain separator without name and version
			mstore(0x00, DOMAIN_SANS_NAME_AND_VERSION_TYPEHASH)
			mstore(0x20, chainid())
			mstore(0x40, address())
			// Compute domain separator (96 bytes total)
			mstore(0x20, keccak256(0x00, 0x60))
			// Build EIP-191 message: "\x19\x01" + domain separator + struct hash
			mstore(0x00, 0x1901)
			mstore(0x40, structHash)
			// Hash 66 bytes starting from 0x1e (30 bytes from start to skip padding)
			digest := keccak256(0x1e, 0x42)
			// Restore memory pointers
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
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

	/// @notice Computes the EIP-712 domain separator using the full domain typehash
	/// @param nameHash Hash of the domain name
	/// @param versionHash Hash of the version string
	/// @param chainId Chain identifier
	/// @param verifyingContract Contract address
	/// @return digest The computed domain separator
	function _computeDomainSeparator(
		bytes32 nameHash,
		bytes32 versionHash,
		uint256 chainId,
		uint256 verifyingContract
	) private pure returns (bytes32 digest) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)
			mstore(ptr, DOMAIN_TYPEHASH)
			mstore(add(ptr, 0x20), nameHash)
			mstore(add(ptr, 0x40), versionHash)
			mstore(add(ptr, 0x60), chainId)
			mstore(add(ptr, 0x80), verifyingContract)
			digest := keccak256(ptr, 0xa0)
		}
	}

	/// @notice Return the domain name and version
	/// @dev Must be implemented by inheriting contracts to provide domain metadata
	/// @return name The domain name string
	/// @return version The domain version string
	function _domainNameAndVersion() internal view virtual returns (string memory name, string memory version);
}
