// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockERC4626 is ERC4626 {
	constructor(string memory name, string memory symbol, IERC20 asset) ERC20(name, symbol) ERC4626(asset) {}

	function mint(address account, uint256 value) public virtual {
		_mint(account, value);
	}

	function burn(address account, uint256 value) public virtual {
		_burn(account, value);
	}
}
