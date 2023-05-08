// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IConditionCheck } from "./interfaces/IConditionCheck.sol";
import { PaymentConditions } from "../libraries/PaymentConditions.sol";
import { PaymentStructs } from "../libraries/PaymentStructs.sol";

/**
 * @dev Contract for checking sponsor payment.
 */
contract ConditionCheck is IConditionCheck {
    using PaymentConditions for PaymentStructs.Condition;

    /**
     * @dev Checks multiple conditions at once.
     * Conditions are specified as a list of Condition structs.
     * @param conditions A list of Condition structs representing the conditions to be checked.
     */
    function _checkConditions(PaymentStructs.Condition[] calldata conditions) internal view {
        uint256 length = conditions.length;

        for (uint256 i = 0; i < length;) {
            PaymentStructs.Condition calldata condition = conditions[i];
            (bool success, bytes memory data) = condition.toCall.staticcall(condition.data);

            if (!success) revert ConditionCallFailed(i);

            if (!condition.checkCondition(data)) revert ConditionFailed(i);

            unchecked {
                ++i;
            }
        }
    }
}
