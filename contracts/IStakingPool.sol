// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IStakingPool {
    function deposit(uint256 amount) external payable;
    function withdraw(uint256 amount) external;
}
