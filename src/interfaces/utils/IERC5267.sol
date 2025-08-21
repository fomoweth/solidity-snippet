// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IERC5267
interface IERC5267 {
	/// @notice Returns the fields and values that describe the domain separator used by this contract for EIP-712 signature
	/// @dev See: https://eips.ethereum.org/EIPS/eip-5267
	/// @return fields The bitmap of used fields
	/// @return name The value of the `EIP712Domain.name` field
	/// @return version The value of the `EIP712Domain.version` field
	/// @return chainId The value of the `EIP712Domain.chainId` field
	/// @return verifyingContract The value of the `EIP712Domain.verifyingContract` field
	/// @return salt The value of the `EIP712Domain.salt` field
	/// @return extensions The list of EIP numbers, that extends EIP-712 with new domain fields
	function eip712Domain()
		external
		view
		returns (
			bytes1 fields,
			string memory name,
			string memory version,
			uint256 chainId,
			address verifyingContract,
			bytes32 salt,
			uint256[] memory extensions
		);
}
