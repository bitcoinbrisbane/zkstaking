// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RocketStorageInterface} from "./Vendors/RocketPool/RocketStorageInterface.sol";
import {RocketDepositPoolInterface} from "./Vendors/RocketPool/RocketDepositPoolInterface.sol";
import {RocketTokenRETHInterface} from "./Vendors/RocketPool/RocketTokenRETHInterface.sol";
import {IOracle} from "./IOracle.sol";

interface IRocketPoolRouter {
    function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) external payable;
}

contract RPVault is IVault, ERC20 {
    address private constant lpToken = 0xae78736cd615f374d3085123a210448e74fc6393;
    address private immutable _router;
    address private immutable _oracle;
    address private immutable _self;

    uint256 public uniswapPortion;
    uint256 public balancerPortion;

    mapping(address => uint256) balances;

    // router address
    RocketStorageInterface rocketStorage;

    function getUnderlyingToken() external view returns (address) {
        return lpToken;
    }

    function getOracle() external view returns (address) {
        return _oracle;
    }

    function setWeight(uint256 _uniswapPortion, uint256 _balancerPortion) external onlyOwner {
        require(_uniswapPortion + _balancerPortion == 100, "RPLVault: Invalid weight");

        uniswapPortion = _uniswapPortion;
        balancerPortion = _balancerPortion;

        emit WeightsUpdated(uniswapPortion, balancerPortion);
    }

    constructor(address _oracleAddress, address _router) ERC20("Rocket Pool Liquidity Token", "rPL") {
        _router = _router;
        _oracle = _oracleAddress;
        _self = address(this);
    }

    function deposit() external payable {
        // Check deposit amount
        require(msg.value > 0, "RPLVault: Invalid deposit amount");

        IRocketPoolRouter(_router).swapTo{value: msg.value}(50, 50, 0, 0);

        emit Deposit(msg.sender, msg.value);
    }

    // function deposit(uint256 amount) external payable {
    //     // Check deposit amount
    //     require(msg.value > 0, "Invalid deposit amount");
    //     require(msg.value == amount, "Invalid deposit amount");

    //     // Load contracts
    //     address rocketDepositPoolAddress = rocketStorage.getAddress(
    //         keccak256(abi.encodePacked("contract.address", "rocketDepositPool"))
    //     );

    //     RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(
    //             rocketDepositPoolAddress
    //         );

    //     address rocketTokenRETHAddress = rocketStorage.getAddress(
    //         keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
    //     );

    //     RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(
    //         rocketTokenRETHAddress
    //     );

    //     // Forward deposit to RP & get amount of rETH minted
    //     uint256 rethBalance1 = rocketTokenRETH.balanceOf(_self);
    //     rocketDepositPool.deposit{value: msg.value}();
    //     uint256 rethBalance2 = rocketTokenRETH.balanceOf(_self);

    //     require(rethBalance2 > rethBalance1, "No rETH was minted");
    //     uint256 rethMinted = rethBalance2 - rethBalance1;
        
    //     // Update user's balance
    //     balances[msg.sender] += rethMinted;
    // }

    // function withdraw(uint256 amount) external {
    //     // Load contracts
    //     address rocketTokenRETHAddress = rocketStorage.getAddress(
    //         keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
    //     );
    //     RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(
    //         rocketTokenRETHAddress
    //     );

    //     require(
    //         balances[msg.sender] >= amount,
    //         "Insufficient rETH balance to withdraw"
    //     );

    //     // Transfer rETH to caller
    //     uint256 balance = balances[msg.sender];
    //     balances[msg.sender] -= amount;

    //     require(
    //         rocketTokenRETH.transfer(msg.sender, balance),
    //         "rETH was not transferred to caller"
    //     );
    // }

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

    event WeightsUpdated(uint256 uniswapPortion, uint256 balancerPortion);

}
