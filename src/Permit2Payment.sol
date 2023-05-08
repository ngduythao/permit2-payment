// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { IPermit2Payment, PaymentStructs } from "./interfaces/IPermit2Payment.sol";
import { PaymentTypes } from "./libraries/PaymentTypes.sol";

/// @notice a contract that executes signed user token-oriented operations on their behalf
contract Permit2Payment is IPermit2Payment {
    using PaymentTypes for PaymentStructs.Execution;

    ISignatureTransfer public immutable permit2 = ISignatureTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    /// @notice execute the given user execution by spec
    /// @param execution the execution to execute
    function execute(PaymentStructs.Execution calldata execution) external {
        _receiveTokens(execution);
        _executeOperations(execution.operations);
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
        uint256 length = operations.length;
        bool success;

        for (uint256 i = 0; i < length;) {
            PaymentStructs.Operation calldata operation = operations[i];
            (success,) = operation.to.call(operation.data);

            if (!success) revert ExecuteOperationFailed(i);

            unchecked {
                ++i;
            }
        }
    }
}
