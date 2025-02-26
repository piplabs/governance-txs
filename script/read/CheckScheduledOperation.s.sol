// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { Predeploys } from "@piplabs/story-contracts/libraries/Predeploys.sol";
import { IUBIPool } from "@piplabs/story-contracts/interfaces/IUBIPool.sol";

contract CheckScheduledOperation is Script {
    TimelockController public timelock;
    bytes32 public operationId;
    
    function setUp() public {
        timelock = TimelockController(payable(vm.envAddress("TIMELOCK_ADDRESS")));
        
        // Reconstruct the operation ID
        address target = Predeploys.UBIPool;
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(IUBIPool.setUBIPercentage.selector, 500);
        bytes32 predecessor = bytes32(0);
        bytes32 salt = keccak256(abi.encode("salt"));
        
        operationId = timelock.hashOperation(target, value, data, predecessor, salt);
        console2.log("Operation ID:", vm.toString(operationId));
    }

    function run() public view {
        // Check operation state
        TimelockController.OperationState state = timelock.getOperationState(operationId);
        console2.log("Operation State:", uint8(state)); // 0=Unset, 1=Waiting, 2=Ready, 3=Done
        
        // Get timestamp when operation becomes ready
        uint256 timestamp = timelock.getTimestamp(operationId);
        console2.log("Ready Timestamp:", timestamp);
        console2.log("Current Timestamp:", block.timestamp);
        
        if (timestamp > block.timestamp) {
            console2.log("Time until ready:", timestamp - block.timestamp, "seconds");
            console2.log("Time until ready:", (timestamp - block.timestamp) / 3600, "hours");
        }
        
        // Check if operation exists and its various states
        console2.log("\nOperation Status:");
        console2.log("Operation State:", uint8(timelock.getOperationState(operationId)));
        console2.log("Exists:", timelock.isOperation(operationId));
        console2.log("Pending:", timelock.isOperationPending(operationId));
        console2.log("Ready:", timelock.isOperationReady(operationId));
        console2.log("Done:", timelock.isOperationDone(operationId));
    }
} 