// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { Test } from "forge-std/Test.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { Permit2Payment } from "src/Permit2Payment.sol";
import { PaymentStructs } from "src/libraries/PaymentStructs.sol";
import { PaymentTypes } from "src/libraries/PaymentTypes.sol";
import { IConditionCheck } from "src/internal/interfaces/IConditionCheck.sol";
import { DeployPermit2 } from "test/util/DeployPermit2.sol";
import { MockERC20 } from "test/util/MockERC20.sol";
import { PermitSignatures } from "test/util/PermitSignatures.sol";

contract Permit2PaymentTest is Test, DeployPermit2, PermitSignatures, IConditionCheck {
    address constant recipient = address(1);
    uint256 constant senderPk = 0x1234;
    address sender;
    address relayer;
    MockERC20 tokenA;
    MockERC20 tokenB;
    Permit2Payment permit2Payment;

    function setUp() public {
        sender = vm.addr(senderPk);
        relayer = makeAddr("relayer");
        deployPermit2();

        tokenA = new MockERC20("TokenA", "TA");
        tokenB = new MockERC20("TokenB", "TB");

        permit2Payment = new Permit2Payment();

        tokenA.mint(sender, 10 ether);
        vm.prank(sender);
        tokenA.approve(address(permit2), type(uint256).max);

        tokenB.mint(sender, 10 ether);
        vm.prank(sender);
        tokenB.approve(address(permit2), type(uint256).max);
    }

    // Relayers -> Permit2Payment -> Permit2 -> Token transfer
    function testSimplePayment() public {
        PaymentStructs.Execution memory unsigned = setupPaymentExecution();
        PaymentStructs.Execution memory execution = _signPaymentsExecution(unsigned, senderPk, address(permit2Payment));

        vm.prank(relayer);
        permit2Payment.execute(execution);

        assertEq(tokenA.balanceOf(sender), 9 ether);
        assertEq(tokenA.balanceOf(recipient), 0.9 ether);
        assertEq(tokenA.balanceOf(relayer), 0.1 ether);
    }

    function testSimplePaymentFailingCondition() public {
        PaymentStructs.Execution memory unsigned = setupPaymentExecution();

        PaymentStructs.Condition[] memory conditions = new PaymentStructs.Condition[](1);
        conditions[0] = PaymentStructs.Condition({
            toCall: address(tokenA),
            data: abi.encodeWithSignature("balanceOf(address)", sender),
            checkType: PaymentStructs.CheckType.GREATER_THAN,
            check: abi.encode(100 ether)
        });
        unsigned.conditions = conditions;

        PaymentStructs.Execution memory execution = _signPaymentsExecution(unsigned, senderPk, address(permit2Payment));

        vm.prank(relayer);
        vm.expectRevert(abi.encodeWithSelector(ConditionFailed.selector, 0));
        permit2Payment.execute(execution);
    }

    function testSimplePaymentPassingCondition() public {
        PaymentStructs.Execution memory unsigned = setupPaymentExecution();

        PaymentStructs.Condition[] memory conditions = new PaymentStructs.Condition[](1);
        conditions[0] = PaymentStructs.Condition({
            toCall: address(tokenA),
            data: abi.encodeWithSignature("balanceOf(address)", sender),
            checkType: PaymentStructs.CheckType.EQUAL,
            check: abi.encode(9 ether)
        });
        unsigned.conditions = conditions;

        PaymentStructs.Execution memory execution = _signPaymentsExecution(unsigned, senderPk, address(permit2Payment));

        vm.prank(relayer);
        permit2Payment.execute(execution);
        assertEq(tokenA.balanceOf(sender), 9 ether);
        assertEq(tokenA.balanceOf(recipient), 0.9 ether);
        assertEq(tokenA.balanceOf(relayer), 0.1 ether);
    }

    function testSimpleTwoTransfers() public {
        PaymentStructs.Execution memory unsigned = setupPaymentExecution();

        ISignatureTransfer.TokenPermissions[] memory tokens = new ISignatureTransfer.TokenPermissions[](2);
        tokens[0] = ISignatureTransfer.TokenPermissions({ token: address(tokenA), amount: 1 ether });
        tokens[1] = ISignatureTransfer.TokenPermissions({ token: address(tokenB), amount: 0.5 ether });

        PaymentStructs.Operation[] memory operations = new PaymentStructs.Operation[](2);
        operations[0] = PaymentStructs.Operation({
            to: address(tokenA),
            data: abi.encodeWithSelector(ERC20.transfer.selector, recipient, 0.9 ether)
        });
        operations[1] = PaymentStructs.Operation({
            to: address(tokenB),
            data: abi.encodeWithSelector(ERC20.transfer.selector, recipient, 0.5 ether)
        });

        unsigned.tokens = tokens;
        unsigned.operations = operations;

        PaymentStructs.Execution memory execution = _signPaymentsExecution(unsigned, senderPk, address(permit2Payment));

        vm.prank(relayer);
        permit2Payment.execute(execution);

        assertEq(tokenA.balanceOf(sender), 9 ether);
        assertEq(tokenA.balanceOf(recipient), 0.9 ether);
        assertEq(tokenA.balanceOf(relayer), 0.1 ether);

        assertEq(tokenB.balanceOf(sender), 9.5 ether);
        assertEq(tokenB.balanceOf(recipient), 0.5 ether);
        assertEq(tokenB.balanceOf(relayer), 0);
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
