// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IRestake {
    function restake(uint256 amount) external;
    function queueUnstake() external;
    function unstake() external;

    event Restaked(uint256 amount);
    event Unstaked(uint256 amount);
}
