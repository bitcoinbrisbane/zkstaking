// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "./IStrategy.sol";
import {IRestake} from "../../IRestake.sol";
import {IStrategyManager} from "./IEigenLayer.sol";
import {IDelegationManger} from "./IEigenLayer.sol";

contract rETH is IRestake {
    address private constant _lpToken =
        0xae78736Cd615f374D3085123A210448E74Fc6393; // rETH

    // https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#deployments
    address public constant strategyManager =
        0x858646372CC42E1A627fcE94aa7A7033e7CF075A;
    address public constant delegationManager =
        0x1BeE69b7dFFfA4E2d53C2a2Df135C388AD25dCD2; // rpl delegation manager
    address public constant strategy =
        0x1BeE69b7dFFfA4E2d53C2a2Df135C388AD25dCD2; // rpl strategy

    function stake(uint256 amount) external {
        require(amount > 0, "stake: Cannot stake 0");
        IERC20(_lpToken).transferFrom(msg.sender, address(this), amount);
        IERC20(_lpToken).approve(strategyManager, amount);

        IStrategyManager(strategyManager).depositIntoStrategy(
            strategy,
            _lpToken,
            amount
        );

        emit Staked(msg.sender, amount);
    }

    function unstake() external {
        uint256 shares = IStrategy(strategy).sharesToUnderlying(
            IERC20(_lpToken).balanceOf(address(this))
        );
        require(shares > 0, "unstake: No shares to withdraw");

        IDelegationManger.QueuedWithdrawalParams
            memory queuedWithdrawalParam = IDelegationManger
                .QueuedWithdrawalParams({
                    strategies: new IStrategy[](1),
                    shares: new uint256[](1),
                    withdrawer: msg.sender
                });

        queuedWithdrawalParam.strategies[0] = IStrategy(strategy);
        queuedWithdrawalParam.shares[0] = shares;

        IDelegationManger.QueuedWithdrawalParams[]
            memory queuedWithdrawalParams = new IDelegationManger.QueuedWithdrawalParams[](
                1
            );
        queuedWithdrawalParams[0] = queuedWithdrawalParam;
        IDelegationManger(delegationManager).queueWithdrawals(
            queuedWithdrawalParams
        );
        IDelegationManger(delegationManager).completeWithdrawal();

        emit Unstaked(msg.sender, IERC20(_lpToken).balanceOf(address(this)));
    }
}
