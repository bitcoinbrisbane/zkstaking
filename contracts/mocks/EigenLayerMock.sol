// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IDelegationManger, IStrategyManager, IStrategy} from "../vendors/EigenLayer/IEigenLayer.sol";
import {console} from "hardhat/console.sol";

contract EigenLayerMock is IDelegationManger, IStrategyManager {
    function queueWithdrawals(
        QueuedWithdrawalParams[] calldata /*queuedWithdrawalParams*/
    ) external pure returns (bytes32[] memory) {
        return new bytes32[](0);
    }

    function completeWithdrawal() external pure override {
        // Do nothing
        console.log("Completing withdrawal");
    }

    function depositIntoStrategy(
        address strategy,
        address token,
        uint256 amount
    ) external pure override {
        // do nothing
        console.log("Depositing %s %s into %s", amount, token, strategy);
    }
}
