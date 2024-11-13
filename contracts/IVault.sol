// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IERC4626Partial {
    function asset() external view returns (address assetTokenAddress);
    function totalAssets() external view returns (uint256 totalManagedAssets);
}

interface IVault is IERC4626Partial {
    function getOracle() external view returns (address);
    
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function exitAll() external;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);
}
