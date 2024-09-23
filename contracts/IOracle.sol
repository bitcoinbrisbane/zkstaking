// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IOracle {
    function getLatestPrice() external view returns (int);
}
