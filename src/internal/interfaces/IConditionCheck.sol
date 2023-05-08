// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IConditionCheck {
    error ConditionCallFailed(uint256 index);
    error ConditionFailed(uint256 index);
}
