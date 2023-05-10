// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { Test } from "forge-std/Test.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { Permit2Payment } from "src/Permit2Payment.sol";
import { PaymentStructs } from "src/libraries/PaymentStructs.sol";
import { DeployPermit2 } from "./util/DeployPermit2.sol";
import { MockERC20 } from "./util/MockERC20.sol";
import { PermitSignatures } from "./util/PermitSignatures.sol";

contract Permit2PaymentTest is Test, DeployPermit2, PermitSignatures {
    address constant recipient = address(1);
    uint256 constant senderPk = 0x1234;
    address sender;
    address operator;
    MockERC20 tokenA;
    Permit2Payment permit2Payment;

    function setUp() public {
        sender = vm.addr(senderPk);
        operator = makeAddr("operator");
        deployPermit2();

        tokenA = new MockERC20("TokenA", "TA");

        permit2Payment = new Permit2Payment();

        tokenA.mint(sender, 10 ether);
        vm.prank(sender);
        tokenA.approve(address(permit2), type(uint256).max);
    }

    // Relayers -> Permit2Payment -> Permit2 -> Token transfer
    function testSimplePayment() public {
        PaymentStructs.Execution memory unsigned = setupPaymentExecution();
        PaymentStructs.Execution memory execution = _signPaymentsExecution(unsigned, senderPk, address(permit2Payment));

        vm.prank(operator);
        permit2Payment.execute(execution);

        assertEq(tokenA.balanceOf(sender), 9 ether);
        assertEq(tokenA.balanceOf(recipient), 0.9 ether);
        assertEq(tokenA.balanceOf(operator), 0.1 ether);
    }

    function setupPaymentExecution() internal view returns (PaymentStructs.Execution memory unsigned) {
        ISignatureTransfer.TokenPermissions[] memory tokens = new ISignatureTransfer.TokenPermissions[](1);
        tokens[0] = ISignatureTransfer.TokenPermissions({ token: address(tokenA), amount: 1 ether });

        ISignatureTransfer.TokenPermissions memory payment =
            ISignatureTransfer.TokenPermissions({ token: address(tokenA), amount: 0.1 ether });

        PaymentStructs.Operation[] memory operations = new PaymentStructs.Operation[](1);
        operations[0] = PaymentStructs.Operation({
            to: address(tokenA),
            data: abi.encodeWithSelector(ERC20.transfer.selector, recipient, 0.9 ether)
        });

        PaymentStructs.Condition[] memory conditions = new PaymentStructs.Condition[](0);

        unsigned = PaymentStructs.Execution({
            tokens: tokens,
            payment: payment,
            operations: operations,
            conditions: conditions,
            sender: sender,
            nonce: 0,
            deadline: block.timestamp + 100,
            signature: new bytes(0)
        });
    }
}
