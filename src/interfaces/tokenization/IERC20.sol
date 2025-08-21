// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IERC20
interface IERC20 {
	/// @notice Thrown when spender doesn't have sufficient allowance
	error InsufficientAllowance();

	/// @notice Thrown when account doesn't have sufficient balance
	error InsufficientBalance();

	/// @notice Thrown when approver address is invalid (zero address)
	error InvalidApprover();

	/// @notice Thrown when recipient address is invalid (zero address)
	error InvalidRecipient();

	/// @notice Thrown when sender address is invalid (zero address)
	error InvalidSender();

	/// @notice Thrown when spender address is invalid (zero address)
	error InvalidSpender();

	/// @notice Thrown when total supply would overflow uint256
	error TotalSupplyOverflow();

	/// @notice Emitted when `value` amount tokens is approved by `owner` to be used by `spender`
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/// @notice Emitted when `value` amount tokens is transferred from `sender` to `recipient`
	event Transfer(address indexed sender, address indexed recipient, uint256 value);

	/// @notice Returns the value of tokens in existence
	/// @return Current total supply of tokens
	function totalSupply() external view returns (uint256);

	/// @notice Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`
	/// @param owner Token owner address
	/// @param spender Address authorized to spend tokens
	/// @return Current allowance amount
	function allowance(address owner, address spender) external view returns (uint256);

	/// @notice Returns the value of tokens owned by `account`
	/// @param account Address to query balance for
	/// @return Current balance of the account
	function balanceOf(address account) external view returns (uint256);

	/// @notice Sets a `value` amount of tokens as the allowance of `spender` over the caller's tokens
	/// @param spender Address to grant allowance to
	/// @param value Amount of tokens to approve
	/// @return A boolean value indicating whether the operation succeeded (reverts on failure)
	function approve(address spender, uint256 value) external returns (bool);

	/// @notice Moves a `value` amount of tokens from the caller's account to `recipient`
	/// @param recipient Address to transfer tokens to
	/// @param value Amount of tokens to transfer
	/// @return A boolean value indicating whether the operation succeeded (reverts on failure)
	function transfer(address recipient, uint256 value) external returns (bool);

	/// @notice Moves a `value` amount of tokens from `sender` to `recipient`
	/// @param sender Address to transfer tokens from
	/// @param recipient Address to transfer tokens to
	/// @param value Amount of tokens to transfer
	/// @return A boolean value indicating whether the operation succeeded (reverts on failure)
	function transferFrom(address sender, address recipient, uint256 value) external returns (bool);
}
