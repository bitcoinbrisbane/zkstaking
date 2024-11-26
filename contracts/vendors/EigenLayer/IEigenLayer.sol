// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IStrategy} from "./IStrategy.sol";

// https://docs.eigenlayer.xyz/eigenlayer/restaking-guides/restaking-developer-guide
interface IStrategyManager {
    function depositIntoStrategy(
        address strategy,
        address token,
        uint256 amount
    ) external;
}

interface IDelegationManger {
    struct QueuedWithdrawalParams {
        // Array of strategies that the QueuedWithdrawal contains
        IStrategy[] strategies;
        // Array containing the amount of shares in each Strategy in the `strategies` array
        uint256[] shares;
        // The address of the withdrawer
        address withdrawer;
    }

    function queueWithdrawals(
        QueuedWithdrawalParams[] calldata queuedWithdrawalParams
    ) external returns (bytes32[] memory);

    function completeWithdrawal() external;
}
