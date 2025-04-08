// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { UpgradeTransparentProxy } from "../../utils/UpgradeTransparentProxy.s.sol";

/// @notice Script to upgrade the IPTokenStaking contract through a timelock
contract UpgradeIpTokenStaking is UpgradeTransparentProxy {
    
    constructor() UpgradeTransparentProxy(
        vm.envAddress("PROXY_ADDRESS"), // proxy address
        vm.envAddress("NEW_IMPLEMENTATION_ADDRESS"),
        "upgrade-staking-v1_0_1", // file name
        Modes.SCHEDULE, // mode
        address(0), // timelock address (current timelock)
        vm.envAddress("PROPOSER_ADDRESS") // Schedule proposer address
    ) {}
}
