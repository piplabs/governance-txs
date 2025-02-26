// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Script } from "forge-std/Script.sol";
import { JSONTxHelper } from "../utils/JSONTxHelper.s.sol";
import { console2 } from "forge-std/console2.sol";

contract SingleTx is JSONTxHelper {
    constructor() JSONTxHelper() {}

    function run() public {
        address from = 0x13919a0d8603c35DAC923f92D7E4e1D55e993898;
        address to = 0x28756A43b51ca11031f32b9a3616930471aC40eb;
        uint256 value = 1 ether;
        bytes memory data = "";

        _saveTx(from, to, value, data, "single-transfer");
        
        console2.log("Generating tx json...");
        _saveTxArrayToJson("single-transfer");
    }
}
