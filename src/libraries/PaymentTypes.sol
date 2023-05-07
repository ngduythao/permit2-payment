// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";

enum CheckType {
    EQUAL,
    NOT_EQUAL,
    GREATER_THAN,
    LESS_THAN,
    GREATER_THAN_OR_EQUAL,
    LESS_THAN_OR_EQUAL,
    TRUE,
    FALSE
}

struct ContractCheck {
    CheckType checkType; // The type of check to perform
    address toCall; // The address of the contract to be called
    bytes data; // The data to be passed to the contract
    bytes check; // The check to be performed on the result of the contract call
}

struct ContractOperation {
    address to; // The address of the contract to be called
    bytes data; // The data to be passed to the contract
}

struct SponsoredExecution {
    ISignatureTransfer.TokenPermissions[] tokens; // The tokens to be transferred in the execution
    ISignatureTransfer.TokenPermissions payment; // The payment token and permissions
    ContractOperation[] contractOperations; // The operations to be performed in the execution
    ContractCheck[] contractChecks; // The conditions that must be met before the execution can proceed
    address sender; // The user who initiated the execution
    uint256 nonce; // A unique identifier for the execution
    uint256 deadline; // The deadline for the execution to be completed
    bytes signature; // The signature that verifies the user's authorization for the execution
}
