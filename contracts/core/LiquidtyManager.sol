// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVault} from "../IVault.sol";

contract LiquidityManger is Ownable {

    uint256 public unallocatedAssets;
    uint256 public allocatedAssets;
    uint256 public totalAssets;

    constructor() Ownable(msg.sender) {

    }

    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => address) public vaults;

    function addVault(IVault vault) external onlyOwner {
        require(vaults[address(vault)] == address(0), "LM: Pool already exists");

        vaults[address(vault)] = address(vault);

        emit PoolAdded(address(vault));
    }

    function stake(address vaultId) external payable {
        require(vaultId != address(0), "LM: Pool not found");
        require(vaults[vaultId] != address(0), "LM: Pool not found");

        balances[vaultId][msg.sender] += msg.value;
        totalAssets += msg.value;
        unallocatedAssets += msg.value;

        IVault(vaults[vaultId]).deposit{value: msg.value}();

        emit Staked(msg.sender, msg.value);
    }

    function unstake(address poolId, uint256 amount) external {
        require(balances[poolId][msg.sender] >= amount, "LM: Insufficient funds");

        balances[poolId][msg.sender] -= amount;
        totalAssets -= amount;
        unallocatedAssets -= amount;

        payable(msg.sender).transfer(amount);

        emit Unstaked(msg.sender, amount);
    }

    function allocate(address poolId, uint256 amount) external {
        require(poolId != address(0), "LM: Invalid pool id");
        require(balances[poolId][msg.sender] >= amount, "LM: Insufficient funds");

        balances[poolId][msg.sender] += amount;
        allocatedAssets += amount;

        /// emit Staked(msg.sender, amount);
    }

    event PoolAdded(address indexed pool);
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
}