// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { PaymentStructs } from "../libraries/PaymentStructs.sol";

interface IPermit2Payment {
    error ExecuteOperationFailed(uint256 i);

    function execute(PaymentStructs.Execution calldata execution) external;
}
