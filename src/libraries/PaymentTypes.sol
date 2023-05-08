// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { PaymentConditionsLibrary } from "./PaymentConditionsLibrary.sol";

library PaymentTypes {
    // keccak256("Operation(address to,bytes data)")
    bytes32 private constant OPERATION_TYPE_HASH = 0x05bfd119fc4bc5e1c9648b74edc051994bd2fe9e90827b03de35bbc8936d7d30;

    // keccak256("Condition(uint8 conditionType,address toCall,bytes data,bytes check)")
    bytes32 private constant CONDITION_TYPE_HASH = 0x1d0cda2640c2148f7f1ed2bd20bfcdec4f7bada4c8f0d3a01b16ab5506550627;

    bytes private constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";

    bytes private constant EXECUTION_TYPE = abi.encodePacked(
        "PaymentExecution(Operation[] operations,Condition[] conditions,TokenPermissions payment)",
        "Condition(uint8 conditionType,address toCall,bytes data,bytes check)",
        "Operation(address to,bytes data)",
        TOKEN_PERMISSIONS_TYPE
    );

    bytes32 private constant EXECUTION_TYPE_HASH = keccak256(EXECUTION_TYPE);

    string internal constant PERMIT2_EXECUTION_TYPE = string(abi.encodePacked("Execution witness)", EXECUTION_TYPE));

    function hash(PaymentConditionsLibrary.Operation memory operation) private pure returns (bytes32) {
        return keccak256(abi.encode(OPERATION_TYPE_HASH, operation.to, keccak256(operation.data)));
    }

    function hashes(PaymentConditionsLibrary.Operation[] memory operations) private pure returns (bytes32) {
        uint256 length = operations.length;
        bytes32[] memory operationHashes = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            operationHashes[i] = hash(operations[i]);
            unchecked {
                ++i;
            }
        }
        return keccak256(abi.encodePacked(operationHashes));
    }

    function hash(PaymentConditionsLibrary.Condition memory condition) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                CONDITION_TYPE_HASH,
                condition.checkType,
                condition.toCall,
                keccak256(condition.data),
                keccak256(condition.check)
            )
        );
    }

    function hashes(PaymentConditionsLibrary.Condition[] memory conditions) private pure returns (bytes32) {
        uint256 length = conditions.length;
        bytes32[] memory conditionHashes = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            conditionHashes[i] = hash(conditions[i]);
            unchecked {
                ++i;
            }
        }
        return keccak256(abi.encodePacked(conditionHashes));
    }

    function hash(ISignatureTransfer.TokenPermissions memory permissions) private pure returns (bytes32) {
        return keccak256(abi.encode(TOKEN_PERMISSIONS_TYPE, permissions.token, permissions.amount));
    }

    function hashes(PaymentConditionsLibrary.PaymentExecution memory execution) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                EXECUTION_TYPE_HASH, hashes(execution.operations), hashes(execution.conditions), hash(execution.payment)
            )
        );
    }

    function toPermit(PaymentConditionsLibrary.PaymentExecution memory execution)
        internal
        pure
        returns (ISignatureTransfer.PermitBatchTransferFrom memory permit)
    {
        return ISignatureTransfer.PermitBatchTransferFrom({
            permitted: execution.tokens,
            nonce: execution.nonce,
            deadline: execution.deadline
        });
    }

    function transferDetails(PaymentConditionsLibrary.PaymentExecution memory execution)
        internal
        view
        returns (ISignatureTransfer.SignatureTransferDetails[] memory details)
    {
        uint256 length = execution.tokens.length;
        details = new ISignatureTransfer.SignatureTransferDetails[](length);
        for (uint256 i = 0; i < length;) {
            details[i] = ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: execution.tokens[i].amount
            });
            unchecked {
                ++i;
            }
        }
    }
}
