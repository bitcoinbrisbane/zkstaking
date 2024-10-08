// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IVault {
    // function balance() external view returns (uint256);
    // function getOracle() external view returns (address);
    // function getUnderlyingToken() external view returns (address);
    // function deposit() external payable;
    // function withdraw(uint256 amount) external;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
}
