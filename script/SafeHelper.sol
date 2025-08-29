// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

// Example of command to run:
// forge script script/SafeHelper.sol --sig "run(address,address,bytes,address,ISafe.Operation)" 0xC9a862Df1872402c4eAcbb8402F9BE628B52d270 0xC9a862Df1872402c4eAcbb8402F9BE628B52d270 0x0d582f13000000000000000000000000af43958ad62389be3e0b553dfd259ec335814c1c0000000000000000000000000000000000000000000000000000000000000001 0x576fa14594D1Ab7dc3fa7E08466E873321f5C95B 0 --rpc-url https://aeneid.storyrpc.io
contract SafeHelper is Script {
    /// @param _safeMultisig The address of the safe multisig
    /// @param _to The address of the contract to call (can be the same as _safeMultisig or not)
    /// @param _calldata The calldata of the function to call obtained via cast calldata command - example: cast calldata "addOwnerWithThreshold(address,uint256)" 0xAF43958ad62389BE3E0B553dFd259Ec335814c1C 1
    /// @param _approveHashCaller The address of the multisig signer that will call approveHash()
    /// @param _operation The operation to perform (0 for Call or 1 for DelegateCall)
    function run(address _safeMultisig, address _to, bytes memory _calldata, address _approveHashCaller, ISafe.Operation _operation ) public view {
        if (block.chainid != 1315 && block.chainid != 1514) revert("Not supported chain");
        ISafe safe = ISafe(_safeMultisig);

        bytes memory encodedData =
            safe.encodeTransactionData(_to, 0, _calldata, _operation, 0, 0, 0, address(0), address(0), safe.nonce());

        bytes32 safeTxHash = keccak256(encodedData);

        console2.log("safeTxHash - to use in approveHash()");
        console2.logBytes32(safeTxHash);
        console2.log(" ");

        bytes memory signature = abi.encodePacked(
            bytes32(uint256(uint160(_approveHashCaller))), // r = owner address, left-padded
            bytes32(0), // s = 0
            bytes1(0x01) // v = 1
        );

        console2.log("to use in execTransaction()");
        console2.log("to: ", _to);
        console2.log("value: ", "0");
        console2.log("data: ");
        console2.logBytes(_calldata);
        console2.log("operation: ");
        console2.logUint(uint8(_operation));
        console2.log("safeTxGas: ", "0");
        console2.log("baseGas: ", "0");
        console2.log("gasPrice: ", "0");
        console2.log("gasToken: ", address(0));
        console2.log("refundReceiver: ", address(0));
        console2.log("signature: ");
        console2.logBytes(signature);
    }
}

interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    function nonce() external view returns (uint256);

    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes memory);

    function approveHash(bytes32 hashToApprove) external;

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable virtual returns (bool success);
}
