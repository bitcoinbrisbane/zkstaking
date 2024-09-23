// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IVault {
    function getOracle() external view returns (address);
    function getUnderlyingToken() external view returns (address);
    function deposit() external payable;
    function withdraw() external;
}
