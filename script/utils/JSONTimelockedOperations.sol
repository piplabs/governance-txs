/* solhint-disable no-console */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { console2 } from "forge-std/console2.sol";
import { Script } from "forge-std/Script.sol";

import { Predeploys } from "@piplabs/story-contracts/libraries/Predeploys.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

// script
import { JSONTxHelper } from "./JSONTxHelper.s.sol";
import { StringUtil } from "./StringUtil.sol";

/**
 * @title JSONTimelockedOperations
 * @notice Script to schedule, execute, or cancel upgrades for the protocol calling TimelockController
 * via multisig.
 * @dev This script is designed to be used with the JSONTxHelper script to generate the tx json
 */
abstract contract JSONTimelockedOperations is Script, JSONTxHelper {

    /// @notice Upgrade modes
    enum Modes {
        UNSET, // Unset, invalidvalue (0)
        SCHEDULE, // Schedule upgrades in AccessManager
        EXECUTE, // Execute scheduled upgrades
        CANCEL // Cancel scheduled upgrades
    }

    ///////// USER INPUT /////////
    Modes internal mode;
    /// @notice action name for tx description
    string internal action;
    /// @notice timelock controller
    TimelockController public timelock;

    /// @notice min delay for the timelock operation
    uint256 public minDelay;

    constructor(string memory _action, Modes _mode, address _timelockAddress) JSONTxHelper() {
        if (_mode == Modes.UNSET) {
            revert("Mode must be set");
        }
        mode = _mode;
        action = _action;
        timelock = TimelockController(payable(_timelockAddress));
    }

    function currentTimelock() public view returns (address) {
        return Ownable2StepUpgradeable(Predeploys.Staking).owner();
    }

    function run() public virtual {
        if (address(timelock) == address(0)) {
            timelock = TimelockController(payable(currentTimelock()));
        }

        minDelay = timelock.getMinDelay();
        _startOperation();
        console2.log("Generating tx json...");
        _saveTxArrayToJson(string.concat(action, "-", _modeDescription())); // JSONTxHelper.s.sol
    }

    function _startOperation() private {
        // Decide actions based on mode
        if (mode == Modes.SCHEDULE) {
            _scheduleActions();
        } else if (mode == Modes.EXECUTE) {
            _executeActions();
        } else if (mode == Modes.CANCEL) {
            _cancelActions();
        } else {
            revert("Invalid mode");
        }
    }

    function _scheduleActions() internal virtual;
    function _executeActions() internal virtual;
    function _cancelActions() internal virtual;

    /// @notice Schedule an action
    /// @param from The address of the sender
    /// @param target The address of the contract to call
    /// @param value The value to send with the call
    /// @param data The encoded target method call
    /// @param predecessor The hash of the predecessor operation (optional)
    /// @param salt The salt for the timelock operation (optional, needed for calls with repeated `data`)
    /// @param delay The delay for the timelock operation. Must be >= minDelay
    function _scheduleAction(address from, address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt, uint256 delay) internal {
        bytes memory _txData = abi.encodeWithSelector(TimelockController.schedule.selector, target, value, data, predecessor, salt, delay);
        _saveTx(from, address(timelock), value, _txData, string.concat(action, "-", _modeDescription()));
    }

    /// @notice Execute an action
    /// @param target The address of the contract to call
    /// @param value The value to send with the call
    /// @param data The encoded target method call
    /// @param predecessor The hash of the predecessor operation (optional)
    /// @param salt The salt for the timelock operation (optional, needed for calls with repeated `data`)
    function _executeAction(address from, address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt) internal {
        bytes memory _txData = abi.encodeWithSelector(TimelockController.execute.selector, target, value, data, predecessor, salt);
        _saveTx(from, address(timelock), value, _txData, string.concat(action, "-", _modeDescription()));
    }

    /// @notice Cancel a scheduled action
    /// @param target The address of the contract to call
    /// @param value The value sent to scheduled call
    /// @param data The encoded target method call
    /// @param predecessor The hash of the predecessor operation (optional)
    /// @param salt The salt for the timelock operation (optional, needed for calls with repeated `data`)
    function _cancelAction(address from, address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt) internal {
        bytes memory _txData = abi.encodeWithSelector(TimelockController.cancel.selector, timelock.hashOperation(target, value, data, predecessor, salt));
        _saveTx(from, address(timelock), value, _txData, string.concat(action, "-", _modeDescription()));
    }

    /// @notice Get the mode description for the tx json
    function _modeDescription() internal view returns (string memory) {
        if (mode == Modes.SCHEDULE) {
            return "schedule";
        } else if (mode == Modes.EXECUTE) {
            return "execute";
        } else if (mode == Modes.CANCEL) {
            return "cancel";
        } else {
            revert("Invalid mode");
        }
    }
}
