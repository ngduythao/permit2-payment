// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { IPaymentConditions } from "../internal/interfaces/IPaymentConditions.sol";

library PaymentConditionsLibrary {
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

    struct Condition {
        CheckType checkType; // The type of check to perform
        address toCall; // The address of the contract to be called
        bytes data; // The data to be passed to the contract
        bytes check; // The check to be performed on the result of the contract call
    }

    struct Operation {
        address to; // The address of the contract to be called
        bytes data; // The data to be passed to the contract
    }

    struct PaymentExecution {
        ISignatureTransfer.TokenPermissions[] tokens; // The tokens to be transferred in the execution
        ISignatureTransfer.TokenPermissions payment; // The payment token and permissions
        Operation[] operations; // The operations to be performed in the execution
        Condition[] conditions; // The conditions that must be met after the execution
        address sender; // The user who initiated the execution
        uint256 nonce; // A unique identifier for the execution
        uint256 deadline; // The deadline for the execution to be completed
        bytes signature; // The signature that verifies the user's authorization for the execution
    }

    /**
     * @dev Helper function for checking a single condition.
     * @param condition The condition to check.
     * @param data The result data returned from the contract call.
     * @return true if the condition is satisfied, false otherwise.
     */
    function checkCondition(Condition calldata condition, bytes memory data) internal pure returns (bool) {
        uint256 value;
        bool boolValue;

        if (condition.checkType == CheckType.TRUE || condition.checkType == CheckType.FALSE) {
            boolValue = abi.decode(data, (bool));
        } else {
            value = abi.decode(data, (uint256));
        }

        if (!_check(condition.checkType, value, boolValue, condition.check)) {
            revert IPaymentConditions.ConditionFailed(0);
        }
        return true;
    }

    /**
     * @dev Helper function for checking a single condition.
     * @param checkType The type of check to perform.
     * @param value The value returned from the contract call.
     * @param boolValue The boolean value returned from the contract call.
     * @param checkData The data to be checked against.
     * @return true if the condition is satisfied, false otherwise.
     */
    function _check(
        CheckType checkType,
        uint256 value,
        bool boolValue,
        bytes memory checkData
    )
        internal
        pure
        returns (bool)
    {
        if (checkType == CheckType.EQUAL) {
            return value == abi.decode(checkData, (uint256));
        } else if (checkType == CheckType.NOT_EQUAL) {
            return value != abi.decode(checkData, (uint256));
        } else if (checkType == CheckType.GREATER_THAN) {
            return value > abi.decode(checkData, (uint256));
        } else if (checkType == CheckType.LESS_THAN) {
            return value < abi.decode(checkData, (uint256));
        } else if (checkType == CheckType.GREATER_THAN_OR_EQUAL) {
            return value >= abi.decode(checkData, (uint256));
        } else if (checkType == CheckType.LESS_THAN_OR_EQUAL) {
            return value <= abi.decode(checkData, (uint256));
        } else if (checkType == CheckType.TRUE) {
            return boolValue;
        } else if (checkType == CheckType.FALSE) {
            return !boolValue;
        }
        // If none of the conditions match, return false
        return false;
    }
}
