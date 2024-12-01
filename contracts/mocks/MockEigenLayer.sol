// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IDelegationManger, IStrategyManager, IStrategy} from "../vendors/EigenLayer/IEigenLayer.sol";
import {IRestake} from "../IRestake.sol";
import {console} from "hardhat/console.sol";

contract MockEigenLayer is ERC20, IRestake, IDelegationManger, IStrategyManager {

    constructor() ERC20("Mock", "ME") {
    }

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

    function restake(uint256 amount) external {
        console.log("Restaking %s", amount);
        _mint(msg.sender, amount);
        emit Restaked(amount);
    }

    function queueUnstake() external pure {
        // do nothing
        console.log("Queueing unstake");
    }

    function unstake() external {
        console.log("Unstaking");
        _burn(msg.sender, balanceOf(msg.sender));
        emit Unstaked(0);
    }
}
