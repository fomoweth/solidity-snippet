// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "src/tokenization/ERC20.sol";

contract MockERC20 is ERC20 {
	bytes32 private immutable _cachedNameHash;
	bytes32 private immutable _cachedVersionHash;

	uint8 private immutable _decimals;
	string private _name;
	string private _symbol;

	constructor(string memory name_, string memory symbol_, uint8 decimals_) {
		_name = name_;
		_symbol = symbol_;
		_decimals = decimals_;

		_cachedNameHash = keccak256(bytes(name_));
		_cachedVersionHash = keccak256(bytes("1"));
	}

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}

	function mint(address account, uint256 value) public virtual {
		_mint(account, value);
	}

	function burn(address account, uint256 value) public virtual {
		_burn(account, value);
	}

	function _nameHash() internal view virtual override returns (bytes32 hash) {
		return _cachedNameHash;
	}

	function _versionHash() internal view virtual override returns (bytes32 hash) {
		return _cachedVersionHash;
	}
}
