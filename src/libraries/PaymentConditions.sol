// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { IConditionCheck } from "../internal/interfaces/IConditionCheck.sol";
import { PaymentStructs } from "./PaymentStructs.sol";

library PaymentConditions {
    /**
     * @dev Helper function for checking a single condition.
     * @param condition The condition to check.
     * @param data The result data returned from the contract call.
     * @return true if the condition is satisfied, false otherwise.
     */
    function checkCondition(
        PaymentStructs.Condition calldata condition,
        bytes memory data
    )
        internal
        pure
        returns (bool)
    {
        uint256 value;
        bool boolValue;

        if (
            condition.checkType == PaymentStructs.CheckType.TRUE
                || condition.checkType == PaymentStructs.CheckType.FALSE
        ) {
            boolValue = abi.decode(data, (bool));
        } else {
            value = abi.decode(data, (uint256));
        }

        if (!_check(condition.checkType, value, boolValue, condition.check)) {
            revert IConditionCheck.ConditionFailed(0);
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
        PaymentStructs.CheckType checkType,
        uint256 value,
        bool boolValue,
        bytes memory checkData
    )
        internal
        pure
        returns (bool)
    {
        if (checkType == PaymentStructs.CheckType.EQUAL) {
            return value == abi.decode(checkData, (uint256));
        } else if (checkType == PaymentStructs.CheckType.NOT_EQUAL) {
            return value != abi.decode(checkData, (uint256));
        } else if (checkType == PaymentStructs.CheckType.GREATER_THAN) {
            return value > abi.decode(checkData, (uint256));
        } else if (checkType == PaymentStructs.CheckType.LESS_THAN) {
            return value < abi.decode(checkData, (uint256));
        } else if (checkType == PaymentStructs.CheckType.GREATER_THAN_OR_EQUAL) {
            return value >= abi.decode(checkData, (uint256));
        } else if (checkType == PaymentStructs.CheckType.LESS_THAN_OR_EQUAL) {
            return value <= abi.decode(checkData, (uint256));
        } else if (checkType == PaymentStructs.CheckType.TRUE) {
            return boolValue;
        } else if (checkType == PaymentStructs.CheckType.FALSE) {
            return !boolValue;
        }
        // If none of the conditions match, return false
        return false;
    }
}
