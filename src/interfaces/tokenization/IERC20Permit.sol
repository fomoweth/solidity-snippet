// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IERC20Permit
interface IERC20Permit {
	/// @notice Thrown when permit deadline has passed
	error DeadlineExpired();

	/// @notice Thrown when permit signature is invalid or doesn't match owner
	error InvalidSigner();

	/// @notice Returns the EIP-712 domain separator used in the encoding of the signature for {permit}
	/// @return Current domain separator for this contract and chain
	function DOMAIN_SEPARATOR() external view returns (bytes32);

	/// @notice Returns the current nonce for `owner`
	/// @param owner Address to query nonce for
	/// @return Current nonce value used for permit signatures
	function nonces(address owner) external view returns (uint256);

	/// @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s signed approval
	/// @param owner Token owner who signed the permit
	/// @param spender Address to grant allowance to
	/// @param value Amount of tokens to approve
	/// @param deadline Timestamp when the permit expires
	/// @param v Recovery byte of the signature
	/// @param r First 32 bytes of the signature
	/// @param s Second 32 bytes of the signature
	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}
