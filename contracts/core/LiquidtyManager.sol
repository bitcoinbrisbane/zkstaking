// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVault} from "../IVault.sol";

contract LiqidityManger is Ownable {

    uint256 public unallocatedFunds;
    uint256 public allocatedFunds;
    uint256 public totalFunds;

    constructor() Ownable(msg.sender) {}

    mapping(uint256 => mapping(address => uint256)) public poolBalances;
    address[] public pools;

    function deposit(uint256 poolId) external payable {
        require(poolId < pools.length, "Invalid pool id");
        poolBalances[poolId][msg.sender] += msg.value;
        totalFunds += msg.value;
        unallocatedFunds += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 poolId, uint256 amount) external {
        require(poolId < pools.length, "Invalid pool id");
        require(poolBalances[poolId][msg.sender] >= amount, "Insufficient funds");

        poolBalances[poolId][msg.sender] -= amount;
        totalFunds -= amount;
        unallocatedFunds -= amount;

        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function addPool(IVault pool) external onlyOwner {
        pools.push(address(pool));
    }

    function stake(uint256 poolId, uint256 amount) external {
        require(poolId < pools.length, "Invalid pool id");
        require(poolBalances[poolId][msg.sender] >= amount, "Insufficient funds");

        poolBalances[poolId][msg.sender] += amount;
        allocatedFunds += amount;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
}