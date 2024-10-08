// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IRocketPoolRouter {
    function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) external payable;
}