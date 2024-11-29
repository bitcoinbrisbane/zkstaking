// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "./IStrategy.sol";
import {IRestake} from "../../IRestake.sol";
import {IStrategyManager} from "./IEigenLayer.sol";
import {IDelegationManger} from "./IEigenLayer.sol";
import {IVault} from "../../IVault.sol";

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

    address private immutable _self;

    constructor() {
        _self = address(this);
    }

    function restake(uint256 amount) external {
        require(amount > 0, "restake: No assets to stake");
        assert(IERC20(_lpToken).balanceOf(_self) >= amount);

        IStrategyManager(strategyManager).depositIntoStrategy(
            strategy,
            _lpToken,
            amount
        );

        emit Restaked(amount);
    }

    function queueUnstake() external {
        uint256 shares = IStrategy(strategy).sharesToUnderlying(
            IERC20(_lpToken).balanceOf(_self)
        );
        require(shares > 0, "queueUnstake: No shares to withdraw");

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
    }

    function unstake() external {
        IDelegationManger(delegationManager).completeWithdrawal();

        emit Unstaked(IERC20(_lpToken).balanceOf(_self));
    }
}
