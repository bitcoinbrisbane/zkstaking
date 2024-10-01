// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RocketStorageInterface} from "../vendors/RocketPool/RocketStorageInterface.sol";
import {RocketDepositPoolInterface} from "../vendors/RocketPool/RocketDepositPoolInterface.sol";
import {RocketTokenRETHInterface} from "../vendors/RocketPool/RocketTokenRETHInterface.sol";
import {IOracle} from "../IOracle.sol";
import {IVault} from "../IVault.sol";

contract RPLVault is IVault, ERC20 {
    // address public immutable depositPool;
    address public immutable lpToken;

    address private immutable _oracle;
    address private immutable _self;

    mapping(address => uint256) balances;

    RocketStorageInterface rocketStorage = RocketStorageInterface(address(0));

    function getUnderlyingToken() external view returns (address) {
        return lpToken;
    }

    function getOracle() external view returns (address) {
        return _oracle;
    }

    function balance() external view returns (uint256) {
        return IERC20(lpToken).balanceOf(address(this));
    }

    constructor(address _rocketStorageAddress, address _oracleAddress) {
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
        _self = address(this);
        _oracle = _oracleAddress;
    }

    function deposit(uint256 amount) external payable {
        // Check deposit amount
        require(msg.value > 0, "Invalid deposit amount");
        require(msg.value == amount, "Invalid deposit amount");

        // Load contracts
        address rocketDepositPoolAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketDepositPool"))
        );

        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(
                rocketDepositPoolAddress
            );

        address rocketTokenRETHAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
        );

        RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(
            rocketTokenRETHAddress
        );

        // Forward deposit to RP & get amount of rETH minted
        uint256 rethBalance1 = rocketTokenRETH.balanceOf(_self);
        rocketDepositPool.deposit{value: msg.value}();
        uint256 rethBalance2 = rocketTokenRETH.balanceOf(_self);

        require(rethBalance2 > rethBalance1, "No rETH was minted");
        uint256 rethMinted = rethBalance2 - rethBalance1;
        
        // Update user's balance
        balances[msg.sender] += rethMinted;
    }

    function withdraw(uint256 amount) external {
        // Load contracts
        address rocketTokenRETHAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
        );
        RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(
            rocketTokenRETHAddress
        );

        require(
            balances[msg.sender] >= amount,
            "Insufficient rETH balance to withdraw"
        );

        // Transfer rETH to caller
        uint256 balance = balances[msg.sender];
        balances[msg.sender] -= amount;

        require(
            rocketTokenRETH.transfer(msg.sender, balance),
            "rETH was not transferred to caller"
        );
    }

    function getLatestPrice() external view returns (int) {
        IOracle oracle = IOracle(_oracle);
        return oracle.getLatestPrice();
    }

    function emerganceyWithdraw() external {
        // // Load contracts
        // address rocketTokenRETHAddress = rocketStorage.getAddress(
        //     keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
        // );
        // RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(
        //     rocketTokenRETHAddress
        // );
        // // Transfer rETH to caller
        // uint256 balance = balances[msg.sender];
        // balances[msg.sender] = 0;
        // require(
        //     rocketTokenRETH.transfer(msg.sender, balance),
        //     "rETH was not transferred to caller"
        // );
    }
}
