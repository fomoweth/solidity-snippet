// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Static} from "test/shared/utils/Static.sol";
import {Brutalizer} from "./Brutalizer.sol";
import {Random} from "./Random.sol";

abstract contract Fixtures is Brutalizer, Random {
	function deployPermit2() internal virtual {
		Static.VM.etch(address(Static.PERMIT2), Static.PERMIT2_BYTECODE);
	}
}
