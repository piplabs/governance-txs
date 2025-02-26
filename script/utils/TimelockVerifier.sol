// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface ITimelock {
    function getMinDelay() external view returns (uint256);
    function PROPOSER_ROLE() external view returns (bytes32);
    function EXECUTOR_ROLE() external view returns (bytes32);
    function CANCELLER_ROLE() external view returns (bytes32);
}

contract TimelockVerifier is Script {
    address public constant TIMELOCK_ADDRESS = 0x4827c76bD61A223Ddd36D013c78F825eb0bb3Be3;
    
    function verifyTimelock() public view returns (bool) {
        // Check if the address has code
        uint256 size;
        assembly {
            size := extcodesize(TIMELOCK_ADDRESS)
        }
        require(size > 0, "Address is not a contract");
        
        // Try to call timelock-specific functions
        try ITimelock(TIMELOCK_ADDRESS).getMinDelay() returns (uint256) {
            // If we can successfully call getMinDelay, it's likely a timelock
            try ITimelock(TIMELOCK_ADDRESS).PROPOSER_ROLE() returns (bytes32) {
                try ITimelock(TIMELOCK_ADDRESS).EXECUTOR_ROLE() returns (bytes32) {
                    try ITimelock(TIMELOCK_ADDRESS).CANCELLER_ROLE() returns (bytes32) {
                        // If all timelock-specific functions exist, it's very likely a timelock contract
                        return true;
                    } catch {
                        return false;
                    }
                } catch {
                    return false;
                }
            } catch {
                return false;
            }
        } catch {
            return false;
        }
    }
    
    function getTimelockDetails() public view returns (
        uint256 minDelay,
        bytes32 proposerRole,
        bytes32 executorRole,
        bytes32 cancellerRole
    ) {
        require(verifyTimelock(), "Not a timelock contract");
        
        minDelay = ITimelock(TIMELOCK_ADDRESS).getMinDelay();
        proposerRole = ITimelock(TIMELOCK_ADDRESS).PROPOSER_ROLE();
        executorRole = ITimelock(TIMELOCK_ADDRESS).EXECUTOR_ROLE();
        cancellerRole = ITimelock(TIMELOCK_ADDRESS).CANCELLER_ROLE();
    }

    function run() public view {

            (uint256 minDelay, bytes32 proposerRole, bytes32 executorRole, bytes32 cancellerRole) = getTimelockDetails();
            console2.log("Min Delay:", minDelay);
            console2.log("Proposer Role:");
            console2.logBytes32(proposerRole);
            console2.log("Executor Role:");
            console2.logBytes32(executorRole);
            console2.log("Canceller Role:");
            console2.logBytes32(cancellerRole);
        
    }
} 