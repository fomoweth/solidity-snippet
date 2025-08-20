// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Fixtures} from "./Fixtures.sol";

abstract contract BaseTest is Test, Fixtures {
	uint256 internal snapshotId = type(uint256).max;

	function revertToState() internal virtual {
		if (snapshotId != type(uint256).max) vm.revertToState(snapshotId);
		snapshotId = vm.snapshotState();
	}
}
