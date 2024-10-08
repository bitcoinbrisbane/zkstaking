// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IRestake {
    function getOracle() external view returns (address);
    function getUnderlyingToken() external view returns (address);
    function deposit() external payable;
    function withdraw() external;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
}
