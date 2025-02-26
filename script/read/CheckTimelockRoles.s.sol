// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Script } from "forge-std/Script.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { ChainIds } from "../utils/ChainIds.sol";
import { Predeploys } from "@piplabs/story-contracts/libraries/Predeploys.sol";
import { console2 } from "forge-std/console2.sol";

/// @notice Helper script that generates a json file with the timelocked operation to set the IPToken staking fee
/// @dev Set in the constructor Modes.SCHEDULE to run _scheduleActions, Modes.EXECUTE to run _executeActions
/// or Modes.CANCEL to run _cancelActions
contract CheckTimelockRoles is Script {
    constructor() Script() {}


    function run() public view {
        TimelockController timelock = TimelockController(payable(0x4827c76bD61A223Ddd36D013c78F825eb0bb3Be3));
        console2.log("CheckTimelockRoles");
        
        console2.log("Proposer role:");
        console2.logBytes32(timelock.PROPOSER_ROLE());
        address proposer = 0x13919a0d8603c35DAC923f92D7E4e1D55e993898;
        console2.log("proposer", proposer);
        console2.log("Has proposer role:", timelock.hasRole(timelock.PROPOSER_ROLE(), proposer));
        console2.log("Canceller role:");
        console2.logBytes32(timelock.EXECUTOR_ROLE());
        address executor = 0x28756A43b51ca11031f32b9a3616930471aC40eb;
        console2.log("executor", executor);
        console2.log("Has executor role:", timelock.hasRole(timelock.EXECUTOR_ROLE(), executor));
        address canceller = 0x9dd1C4d9Dc87dDbF4fa1721b94B7Af4F08D8A83C;
        console2.log("canceller", canceller);
        console2.log("Has canceller role:", timelock.hasRole(timelock.CANCELLER_ROLE(), canceller));
        console2.log("Executor role:");
        console2.logBytes32(timelock.CANCELLER_ROLE());
    }
}
