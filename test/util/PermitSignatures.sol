// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";
import { ECDSA } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "permit2/src/EIP712.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";
import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { PermitHash } from "permit2/src/libraries/PermitHash.sol";
import { PaymentStructs } from "src/libraries/PaymentStructs.sol";
import { PaymentTypes } from "src/libraries/PaymentTypes.sol";

/**
 * @title PermitSignatures
 * @dev A contract that provides functions for signing and verifying signatures for executing batch transfers with
 * permit using EIP-712.
 */
contract PermitSignatures is Test {
    bytes32 public constant FULL_EXECUTION_TYPEHASH = keccak256(
        abi.encodePacked(
            PermitHash._PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB, PaymentTypes.PERMIT2_EXECUTION_TYPE
        )
    );

    ISignatureTransfer public immutable permit2 = ISignatureTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    /**
     * @dev Generates the signature for executing a batch transfer with permit.
     * @param execution The `Execution` struct that contains the transfer details.
     * @param privateKey The private key of the signer.
     * @param spender The address of the spender.
     * @return result The `Execution` struct with the generated signature.
     */
    function _signPaymentsExecution(
        PaymentStructs.Execution memory execution,
        uint256 privateKey,
        address spender
    )
        internal
        view
        returns (PaymentStructs.Execution memory result)
    {
        // Generate the permit for batch transfer from.
        ISignatureTransfer.PermitBatchTransferFrom memory permit = ISignatureTransfer.PermitBatchTransferFrom({
            permitted: execution.tokens,
            nonce: execution.nonce,
            deadline: execution.deadline
        });

        // Set the result with the given execution details and an empty signature.
        result = PaymentStructs.Execution({
            tokens: execution.tokens,
            payment: execution.payment,
            operations: execution.operations,
            conditions: execution.conditions,
            sender: execution.sender,
            nonce: execution.nonce,
            deadline: execution.deadline,
            signature: new bytes(0)
        });

        // Generate the signature for the given execution details and the permit.
        bytes memory sig = _getPermitBatchWitnessSignature(
            permit,
            spender,
            privateKey,
            FULL_EXECUTION_TYPEHASH,
            PaymentTypes.hashes(result),
            EIP712(address(permit2)).DOMAIN_SEPARATOR()
        );

        // Set the result signature with the generated signature.
        result.signature = sig;
    }

    /**
     * @dev Generates the signature for a permit batch transfer from.
     * @param permit The `PermitBatchTransferFrom` struct that contains the permit details.
     * @param spender The address of the spender.
     * @param privateKey The private key of the signer.
     * @param typeHash The type hash of the permit.
     * @param witness The hash of the witness data.
     * @param domainSeparator The domain separator for EIP-712.
     * @return sig The generated signature.
     */
    function _getPermitBatchWitnessSignature(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        address spender,
        uint256 privateKey,
        bytes32 typeHash,
        bytes32 witness,
        bytes32 domainSeparator
    )
        internal
        pure
        returns (bytes memory sig)
    {
        uint256 length = permit.permitted.length;
        bytes32[] memory tokenPermissions = new bytes32[](length);
        for (uint256 i = 0; i < length; ++i) {
            tokenPermissions[i] = keccak256(abi.encode(PermitHash._TOKEN_PERMISSIONS_TYPEHASH, permit.permitted[i]));
        }

        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        typeHash,
                        keccak256(abi.encodePacked(tokenPermissions)),
                        spender,
                        permit.nonce,
                        permit.deadline,
                        witness
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }

    function _getERC20PermitMultiple(
        address[] memory tokens,
        uint256 nonce
    )
        internal
        view
        returns (ISignatureTransfer.PermitBatchTransferFrom memory)
    {
        uint256 length = tokens.length;
        ISignatureTransfer.TokenPermissions[] memory permitted = new ISignatureTransfer.TokenPermissions[](length);
        for (uint256 i = 0; i < length; ++i) {
            permitted[i] = ISignatureTransfer.TokenPermissions({ token: tokens[i], amount: 10 ** 18 });
        }
        return ISignatureTransfer.PermitBatchTransferFrom({
            permitted: permitted,
            nonce: nonce,
            deadline: block.timestamp + 100
        });
    }
}
