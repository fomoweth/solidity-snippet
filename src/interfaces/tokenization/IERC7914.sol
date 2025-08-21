// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IERC7914
interface IERC7914 {
	/// @notice Thrown when the caller's allowance is exceeded when transferring
	error AllowanceExceeded();

	/// @notice Thrown when the sender is not the expected one
	error IncorrectSender();

	/// @notice Thrown when the transfer of native tokens fails
	error TransferNativeFailed();

	/// @notice Emitted when a native approval is made
	event ApproveNative(address indexed owner, address indexed spender, uint256 value);

	/// @notice Emitted when a transient native approval is made
	event ApproveNativeTransient(address indexed owner, address indexed spender, uint256 value);

	/// @notice Emitted when the native allowance of a spender is updated when a transfer happens
	event NativeAllowanceUpdated(address indexed spender, uint256 value);

	/// @notice Emitted when a transfer from native is made
	event TransferFromNative(address indexed sender, address indexed recipient, uint256 value);

	/// @notice Emitted when a transfer from native transient is made
	event TransferFromNativeTransient(address indexed sender, address indexed recipient, uint256 value);

	/// @notice Returns the allowance of a spender
	function nativeAllowance(address spender) external view returns (uint256);

	/// @notice Returns the transient allowance of a spender
	function transientNativeAllowance(address spender) external view returns (uint256);

	/// @notice Approves a spender to transfer native tokens on behalf of the caller
	function approveNative(address spender, uint256 value) external returns (bool);

	/// @notice Approves a spender to transfer native tokens on behalf of the caller with transient storage
	function approveNativeTransient(address spender, uint256 value) external returns (bool);

	/// @notice Transfers native tokens from the caller to a recipient
	/// @dev Doesn't forward transferFrom requests - the specified `spender` address must be address(this)
	function transferFromNative(address spender, address recipient, uint256 value) external returns (bool);

	/// @notice Transfers native tokens from the caller to a recipient with transient storage
	/// @dev Doesn't forward transferFrom requests - the specified `spender` address must be address(this)
	function transferFromNativeTransient(address spender, address recipient, uint256 value) external returns (bool);
}
