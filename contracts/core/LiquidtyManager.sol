// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IVault} from "../IVault.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LiquidityManager is ERC20, Ownable, ReentrancyGuard {

    uint256 public unallocatedAssets;
    uint256 public allocatedAssets;
    uint256 public totalAssets;

    struct Weight {
        uint8 weight;
        address vault;
    }

    Weight[] public weights;
    mapping(address => address) public vaults;
    mapping(address => mapping(address => uint256)) public balances;

    uint256 public totalWeight;
    
    constructor() Ownable(msg.sender) ERC20("OZ Eth", "ozETH") {
    }


    function addVault(IVault vault, uint8 weight) external onlyOwner {
        require(vaults[address(vault)] == address(0), "addVault: Vault already exists");

        vaults[address(vault)] = address(vault);
        weights.push(Weight(weight, address(vault)));
        totalWeight += weight;

        emit VaultAdded(address(vault));
    }

    function removeVault(address vaultId) external onlyOwner {
        require(vaults[vaultId] != address(0), "removeVault: Vault not found");

        for (uint i = 0; i < weights.length; i++) {
            if (weights[i].vault == vaultId) {
                totalWeight -= weights[i].weight;
                delete weights[i];
            }
        }

        delete vaults[vaultId];
    }

    // function _rebalance() internal {
    //     for (uint i = 0; i < weights.length; i++) {
    //         uint256 target = (totalAssets * weights[i].weight) / totalWeight;
    //         uint256 current = IERC20(weights[i].vault).balanceOf(address(this));

    //         if (current > target) {
    //             uint256 excess = current - target;
    //             IERC20(weights[i].vault).transfer(owner(), excess);
    //         } else if (current < target) {
    //             uint256 deficit = target - current;
    //             IERC20(weights[i].vault).transferFrom(owner(), address(this), deficit);
    //         }
    //     }
    // }

    function stake() external payable nonReentrant() {
        require(msg.value > 0, "stake: Invalid amount");
        require(weights.length > 0, "stake: No vaults added");

        uint256 amount = msg.value;
        for (uint i = 0; i < weights.length; i++) {
            uint256 portion = (amount * weights[i].weight) / totalWeight;

            address _vault = weights[i].vault;
            assert(_vault != address(0));
            
            IVault vault = IVault(_vault);
            vault.deposit{value: portion}();

            balances[_vault][msg.sender] += msg.value;
        }

        totalAssets += amount;
        unallocatedAssets += amount;
        _mint(msg.sender, amount);

        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount) external nonReentrant() {
        require(amount > 0, "unstake: Invalid amount");
        IERC20(address(this)).transferFrom(msg.sender, address(this), amount);

        // balances[poolId][msg.sender] -= amount;
        totalAssets -= amount;
        unallocatedAssets -= amount;

        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);

        emit Unstaked(msg.sender, amount);
    }

    // function allocate(address poolId, uint256 amount) external {
    //     require(poolId != address(0), "LM: Invalid pool id");
    //     require(balances[poolId][msg.sender] >= amount, "LM: Insufficient funds");

    //     balances[poolId][msg.sender] += amount;
    //     allocatedAssets += amount;

    //     emit Staked(msg.sender, amount);
    // }

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event VaultAdded(address indexed vault);
}