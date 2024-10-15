// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IVault {
    function balance() external view returns (uint256);
    function getOracle() external view returns (address);
    function getUnderlyingToken() external view returns (address);
    function deposit() external payable;
    function exit(uint256 amount) external;
    function exitAll() external;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
}
