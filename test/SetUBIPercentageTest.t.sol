// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Test, console2 } from "forge-std/Test.sol";
import { IUBIPool } from "@piplabs/story-contracts/interfaces/IUBIPool.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";

contract SetUBIPercentageTest is Test {
    // We'll keep the struct definition for reference but not use it
    struct TimelockOperation {
        address from;
        address to;
        uint256 value;
        string data;
        uint8 operation;
        string comment;
    }
    
    address internal constant UBIPool = 0xCccCCC0000000000000000000000000000000002;
    address internal constant Timelock = 0x4827c76bD61A223Ddd36D013c78F825eb0bb3Be3;
    address internal constant Admin = 0x4C30baDa479D0e13300b31b1696A5E570848bbEe;

    function setUp() public {}

    function test_SetUBIPercentageEncoding() public view {
        // Load JSON file with the transaction data
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/script/admin-actions/output/1514/set-ubi-percentage-5%-schedule.json"
        );
        
        // Check if file exists
        try vm.readFile(path) returns (string memory json) {
            console2.log("JSON file found");
            
            // Parse each field individually using JSON path
            address from = vm.parseJsonAddress(json, ".[0].from");
            address to = vm.parseJsonAddress(json, ".[0].to");
            uint256 value = vm.parseJsonUint(json, ".[0].value");
            bytes memory callData = vm.parseJsonBytes(json, ".[0].data");
            uint8 operation = uint8(vm.parseJsonUint(json, ".[0].operation"));
            string memory comment = vm.parseJsonString(json, ".[0].comment");
            
            // Verify basic operation parameters
            console2.log("From address:", from);
            assertEq(from, Admin, "From address is not Admin");
            
            console2.log("To address:", to);
            assertEq(to, Timelock, "To address is not Timelock");
            
            console2.log("Value:", value);
            assertEq(value, 0, "Value is not 0");
            
            console2.log("Operation:", operation);
            assertEq(operation, 0, "Operation is not 0");
            
            console2.log("Comment:", comment);
            assertEq(comment, "set-ubi-percentage-5%-schedule", "Comment is not correct");
            
            console2.log("Calldata length:", callData.length);
            
            // Check if the calldata starts with the selector for TimelockController.schedule
            bytes4 firstBytes;
            assembly {
                firstBytes := mload(add(callData, 32))
            }
            console2.log("First 4 bytes:", vm.toString(firstBytes));

            // Check if the calldata starts with the selector for TimelockController.schedule
            bytes4 expectedSelector = TimelockController.schedule.selector;
            console2.log("Expected selector:", vm.toString(expectedSelector));
            
            assertEq(firstBytes, expectedSelector, "Calldata does not start with TimelockController.schedule selector");

            // Decode the schedule call parameters using the function signature
            bytes memory scheduleParams = new bytes(callData.length - 4);
            for (uint i = 0; i < scheduleParams.length; i++) {
                scheduleParams[i] = callData[i + 4];
            }

            (address target, uint256 valueParam, bytes memory data, bytes32 predecessor, bytes32 salt, uint256 delay) = abi
                .decode(scheduleParams, (address, uint256, bytes, bytes32, bytes32, uint256));

            // Verify target is UBIPool
            console2.log("Target:", target);
            assertEq(target, UBIPool, "Target is not UBIPool");
            
            console2.log("Value param:", valueParam);
            assertEq(valueParam, 0, "Value param should be 0");
            
            console2.log("Predecessor:");
            console2.logBytes32(predecessor);
            assertEq(predecessor, bytes32(0), "Predecessor should be bytes32(0)");
            
            console2.log("Salt:");
            console2.logBytes32(salt);
            
            console2.log("Delay:", delay);

            // Verify data contains call to setUBIPercentage
            bytes4 dataSelector;
            assembly {
                dataSelector := mload(add(data, 32))
            }
            
            bytes4 setUBIPercentageSelector = IUBIPool.setUBIPercentage.selector;
            console2.log("Data selector:", vm.toString(dataSelector));
            console2.log("Expected UBI selector:", vm.toString(setUBIPercentageSelector));

            assertEq(dataSelector, setUBIPercentageSelector, "Inner data is not calling setUBIPercentage");

            // Extract the percentage parameter
            bytes memory setUBIParams = new bytes(data.length - 4);
            for (uint i = 0; i < setUBIParams.length; i++) {
                setUBIParams[i] = data[i + 4];
            }

            uint32 percentage = abi.decode(setUBIParams, (uint32));
            console2.log("Percentage:", percentage);
            assertEq(percentage, 500, "Percentage is not 500 (5.00%)");
        } catch Error(string memory reason) {
            console2.log("Error reading or parsing JSON file:", reason);
            revert(string.concat("JSON file error: ", reason));
        } catch (bytes memory) {
            console2.log("Unknown error reading or parsing JSON file");
            revert("Unknown JSON file error");
        }
    }
}
