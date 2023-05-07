// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IPaymentConditions } from "./interfaces/IPaymentConditions.sol";
import { PaymentConditionsLibrary } from "../libraries/PaymentConditionsLibrary.sol";

/**
 * @dev Contract for checking payment conditions.
 */
contract PaymentConditions is IPaymentConditions {
    using PaymentConditionsLibrary for PaymentConditionsLibrary.ContractCheck;

    /**
     * @dev Checks multiple conditions at once.
     * Conditions are specified as a list of ContractCheck structs.
     * @param conditions A list of ContractCheck structs representing the conditions to be checked.
     */
    function _checkConditions(PaymentConditionsLibrary.ContractCheck[] calldata conditions) internal view {
        uint256 length = conditions.length;

        for (uint256 i = 0; i < length;) {
            PaymentConditionsLibrary.ContractCheck calldata condition = conditions[i];
            (bool success, bytes memory data) = condition.toCall.staticcall(condition.data);
            
            if (!success) revert ConditionCallFailed(i);
            
            if (!condition.checkCondition(data)) revert ConditionFailed(i);
            
            unchecked {
                ++i;
            }
        }
    }
}
