// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IRestake {
    function stake(uint256 amount) external;
    function unstake() external;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
}
