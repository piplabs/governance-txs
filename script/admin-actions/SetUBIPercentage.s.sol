// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { JSONTimelockedOperations } from "../utils/JSONTimelockedOperations.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { ChainIds } from "../utils/ChainIds.sol";
import { Predeploys } from "@piplabs/story-contracts/libraries/Predeploys.sol";
import { IUBIPool } from "@piplabs/story-contracts/interfaces/IUBIPool.sol";
import { console2 } from "forge-std/console2.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

/// @notice Helper script that generates a json file with the timelocked operation to set the UBI percentage
/// @dev Set in the constructor Modes.SCHEDULE to run _scheduleActions, Modes.EXECUTE to run _executeActions
/// or Modes.CANCEL to run _cancelActions
contract SetUBIPercentage is JSONTimelockedOperations {
    address from;

    constructor() JSONTimelockedOperations(
        "set-ubi-percentage-5%",
        Modes.EXECUTE,
        address(0) // Current timelock
    ) {
        from = vm.envAddress("ADMIN_ADDRESS");
        console2.log("from", from);
    }

    uint32 public percentage = 500; // 5.00%

    function _scheduleActions() internal virtual override {
        // Check that sender is owner of UBIPool
        console2.log("from", from);
        if (!timelock.hasRole(timelock.PROPOSER_ROLE(), from)) {
            revert("Sender does not have PROPOSER_ROLE");
        }
        _scheduleAction(
            from,
            Predeploys.UBIPool,
            uint256(0),
            abi.encodeWithSelector(IUBIPool.setUBIPercentage.selector, percentage),
            bytes32(0),
            keccak256(abi.encode("salt")),
            minDelay
        );
    }

    function _executeActions() internal virtual override {
       vm.startBroadcast(vm.envUint("EXECUTOR_PRIVATE_KEY"));
       console2.log("Operation ID:");
       bytes32 operationId = timelock.hashOperation(
            Predeploys.UBIPool,
            uint256(0),
            abi.encodeWithSelector(IUBIPool.setUBIPercentage.selector, percentage),
            bytes32(0),
            keccak256(abi.encode("salt"))
        );
       console2.logBytes32(operationId);
       console2.log("Executing setUBIPercentage");
        timelock.execute(
            Predeploys.UBIPool,
            uint256(0),
            abi.encodeWithSelector(IUBIPool.setUBIPercentage.selector, percentage),
            bytes32(0),
            keccak256(abi.encode("salt"))
        );
        vm.stopBroadcast();
    }

    function _cancelActions() internal virtual override {
        _cancelAction(
            from,
            Predeploys.UBIPool,
            uint256(0),
            abi.encodeWithSelector(IUBIPool.setUBIPercentage.selector, percentage),
            bytes32(0),
            bytes32(0)
        );
    }
}
