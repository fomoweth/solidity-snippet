// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "./IERC20.sol";

/// @title IERC20Metadata
interface IERC20Metadata is IERC20 {
	/// @notice Returns the name of the token
	/// @return Token name string
	function name() external view returns (string memory);

	/// @notice Returns the symbol of the token
	/// @return Token symbol string
	function symbol() external view returns (string memory);

	/// @notice Returns the decimals places of the token
	/// @return Number of decimals used for token display and calculations
	function decimals() external view returns (uint8);
}
