// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { IPermit2Payment, PaymentStructs } from "src/interfaces/IPermit2Payment.sol";
import { ConditionCheck } from "src/internal/ConditionCheck.sol";
import { PaymentTypes } from "src/libraries/PaymentTypes.sol";
import { PaymentConditions } from "src/libraries/PaymentConditions.sol";

/// @notice a contract that executes signed user token-oriented operations on their behalf
contract Permit2Payment is IPermit2Payment, ConditionCheck {
    using PaymentTypes for PaymentStructs.Execution;
    using PaymentConditions for PaymentStructs.Condition;

    ISignatureTransfer public immutable permit2 = ISignatureTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    /// @notice execute the given user execution by spec
    /// @param execution the execution to execute
    function execute(PaymentStructs.Execution calldata execution) external {
        _receiveTokens(execution);
        _executeOperations(execution.operations);
        _payExecution(execution.payment);
        _checkConditions(execution.conditions);
    }

    /// @notice receive tokens from the user
    /// @dev also verifies user signature over the execution data
    /// @param execution the execution to receive tokens for
    function _receiveTokens(PaymentStructs.Execution calldata execution) internal {
        permit2.permitWitnessTransferFrom(
            execution.toPermit(),
            execution.transferDetails(),
            execution.sender,
            execution.hashes(),
            PaymentTypes.PERMIT2_EXECUTION_TYPE,
            execution.signature
        );
    }

    /// @notice execute the given operations
    /// @param operations the operations to execute
    function _executeOperations(PaymentStructs.Operation[] calldata operations) internal {
        uint256 opLength = operations.length;
        bool success;
        bytes memory data;
        PaymentStructs.Operation calldata operation;

        for (uint256 i = 0; i < opLength;) {
            operation = operations[i];
            (success, data) = operation.to.call(operation.data);

            if (!success) revert ExecuteOperationFailed(i);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice pay the relayer for execution
    function _payExecution(ISignatureTransfer.TokenPermissions calldata payment) internal {
        // users may execute their own transaction
        if (payment.amount == 0) return;

        // or allow relayers to claim fee as payment
        SafeTransferLib.safeTransfer(ERC20(payment.token), msg.sender, payment.amount);
    }
}
