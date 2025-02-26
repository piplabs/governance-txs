// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { JSONTimelockedOperations } from "../utils/JSONTimelockedOperations.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { ChainIds } from "../utils/ChainIds.sol";
import { Predeploys } from "@piplabs/story-contracts/libraries/Predeploys.sol";
import { IPTokenStaking } from "@piplabs/story-contracts/protocol/IPTokenStaking.sol";
import { console2 } from "forge-std/console2.sol";

/// @notice Helper script that generates a json file with the timelocked operation to set the IPToken staking fee
/// @dev Set in the constructor Modes.SCHEDULE to run _scheduleActions, Modes.EXECUTE to run _executeActions
/// or Modes.CANCEL to run _cancelActions
contract SetIPTokenStakingFee is JSONTimelockedOperations {
    address from;

    constructor() JSONTimelockedOperations(
        "set-ip-token-staking-fee-10IP",
        Modes.EXECUTE,
        address(0) // Current timelock
    ) {
        from = vm.envAddress("ADMIN_ADDRESS");
    }

    uint256 public fee = 10 ether;

    function _scheduleActions() internal virtual override {
        _scheduleAction(
            from,
            Predeploys.Staking,
            uint256(0),
            abi.encodeWithSelector(IPTokenStaking.setFee.selector, fee),
            bytes32(0),
            keccak256(abi.encode("salt")),
            minDelay
        );
    }

    function _executeActions() internal virtual override {
        vm.startBroadcast(vm.envUint("NEW_TIMELOCK_DEPLOYER_PRIVATE_KEY"));
        timelock.execute(
            Predeploys.Staking,
            uint256(0),
            abi.encodeWithSelector(IPTokenStaking.setFee.selector, fee),
            bytes32(0),
            keccak256(abi.encode("salt"))
        );
        
        vm.stopBroadcast();

    }

    function _cancelActions() internal virtual override {
        _cancelAction(
            from,
            Predeploys.Staking,
            uint256(0),
            abi.encodeWithSelector(IPTokenStaking.setFee.selector, fee),
            bytes32(0),
            bytes32(0)
        );
    }
}
