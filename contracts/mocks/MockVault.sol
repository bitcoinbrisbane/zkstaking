// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IVault} from "../IVault.sol";

// Mock Vault Contract for testing
contract MockVault is IVault {
    uint256 private balance;

    function asset() external view returns (address assetTokenAddress) {
        return address(0);
    }
    
    function totalAssets() external view returns (uint256 totalManagedAssets) {
        return balance;
    }

    function deposit() external payable {
        balance += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balance >= amount, "Insufficient balance");
        balance -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getOracle() external view returns (address) {
        return address(0);
    }
}