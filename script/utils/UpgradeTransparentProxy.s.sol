// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { JSONTimelockedOperations } from "../utils/JSONTimelockedOperations.sol";
import { console2 } from "forge-std/console2.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { EIP1967Helper } from "../utils/EIP1967Helper.sol";

/// @notice Helper script that generates a json file with the timelocked operation to upgrade a TransparentUpgradeableProxy
/// @dev Set in the constructor Modes.SCHEDULE to run _scheduleActions, Modes.EXECUTE to run _executeActions
/// or Modes.CANCEL to run _cancelActions
abstract contract UpgradeTransparentProxy is JSONTimelockedOperations {
    // The address of the sender with proposer role
    address public from;
    // The address of the proxy to upgrade
    address public proxyAddress;
    // The address of the new implementation
    address public newImplementationAddress;
    // The proxy admin address that will be called
    address public proxyAdminAddress;
    // The operation salt for deterministic operation ID
    bytes32 public salt;

    constructor(address _proxyAddress, address _newImplementationAddress, string memory message, Modes _mode, address _timelock, address _from) JSONTimelockedOperations(
        message,
        _mode,
        _timelock
    ) {
        from = _from;
        proxyAddress = _proxyAddress;
        newImplementationAddress = _newImplementationAddress;

        // Get the proxy admin address from the proxy
        proxyAdminAddress = EIP1967Helper.getAdmin(proxyAddress);
        console2.log("ProxyAdmin address:", proxyAdminAddress);
        
        // Create a deterministic salt
        salt = keccak256("salt");
        
        console2.log("From:", from);
        console2.log("Proxy address:", proxyAddress);
        console2.log("New implementation:", newImplementationAddress);
    }

    function _scheduleActions() internal virtual override {
        // Check that sender has PROPOSER_ROLE
        if (!timelock.hasRole(timelock.PROPOSER_ROLE(), from)) {
            revert("Sender does not have PROPOSER_ROLE");
        }
        
        // Create the upgrade calldata
        bytes memory upgradeCalldata = abi.encodeWithSignature(
            "upgradeAndCall(address,address,bytes)",
            proxyAddress,
            newImplementationAddress,
            ""
        );
        
        // Schedule the action through JSONTimelockedOperations
        _scheduleAction(
            from,
            proxyAdminAddress,
            uint256(0), // No IP is sent
            upgradeCalldata,
            bytes32(0), // predecessor (none)
            salt,
            minDelay
        );
        
        console2.log("Upgrade scheduled through timelock");
        console2.log("Waiting period:", minDelay);
    }

    function _executeActions() internal virtual override {
        // Create the upgrade calldata
        bytes memory upgradeCalldata = abi.encodeWithSignature(
            "upgradeAndCall(address,address,bytes)",
            proxyAddress,
            newImplementationAddress,
            ""
        );
        // Get the proxy implementation address
        vm.startBroadcast(vm.envUint("EXECUTOR_PRIVATE_KEY"));
        console2.log("Executing proxy upgrade");
        
        // Execute the action through the timelock
        timelock.execute(
            proxyAdminAddress,
            uint256(0),
            upgradeCalldata,
            bytes32(0),
            salt
        );
        
        vm.stopBroadcast();
        console2.log("Proxy successfully upgraded to new implementation");
    }

    function _cancelActions() internal virtual override {
        // Create the upgrade calldata
        bytes memory upgradeCalldata = abi.encodeWithSignature(
            "upgradeAndCall(address,address,bytes)",
            proxyAddress,
            newImplementationAddress,
            ""
        );
        
        // Cancel the action
        _cancelAction(
            from,
            proxyAdminAddress,
            uint256(0),
            upgradeCalldata,
            bytes32(0),
            salt
        );
        
        console2.log("Proxy upgrade operation cancelled");
    }
    
}
