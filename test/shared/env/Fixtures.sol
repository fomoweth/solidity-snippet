// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {CommonBase} from "forge-std/Base.sol";
import {Static} from "test/shared/utils/Static.sol";
import {Brutalizer} from "./Brutalizer.sol";
import {Random} from "./Random.sol";

abstract contract Fixtures is CommonBase, Brutalizer, Random {
	function deployPermit2() internal virtual {
		vm.etch(address(Static.PERMIT2), Static.PERMIT2_BYTECODE);
	}

	function encodePrivateKey(string memory key) internal pure virtual returns (uint256 privateKey) {
		return uint256(keccak256(abi.encodePacked(key)));
	}
}
