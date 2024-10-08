// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "../IOracle.sol";
import {IVault} from "../IVault.sol";
import {IRocketPoolRouter} from "../vendor/RocketPool/IRocketPoolRouter.sol";

contract RPVault is IVault, ERC20, Ownable {
    address private constant lpToken = 0xae78736cd615f374d3085123a210448e74fc6393; // rETH
    address private constant _router = 0x16d5a408e807db8ef7c578279beeee6b228f1c1c; // https://etherscan.io/address/0x16d5a408e807db8ef7c578279beeee6b228f1c1c#writeContract
    address private _oracle;
    address private immutable _self;

    uint256 public uniswapPortion;
    uint256 public balancerPortion;

    mapping(address => uint256) balances;

    function getUnderlyingToken() external view returns (address) {
        return lpToken;
    }

    function getOracle() external view returns (address) {
        return _oracle;
    }

    function setOracle(address oracle) external onlyOwner {
        _oracle = oracle;
    }

    function setWeight(uint256 _uniswapPortion, uint256 _balancerPortion) external onlyOwner {
        require(_uniswapPortion + _balancerPortion == 100, "RPLVault: Invalid weight");

        uniswapPortion = _uniswapPortion;
        balancerPortion = _balancerPortion;

        emit WeightsUpdated(uniswapPortion, balancerPortion);
    }

    constructor() ERC20("Rocket Pool Liquidity Token", "rPL") {
        uniswapPortion = 50;
        balancerPortion = 50;
        _self = address(this);
    }

    function deposit() external payable {
        // Check deposit amount
        require(msg.value > 0, "RPLVault: Invalid deposit amount");

        IRocketPoolRouter(_router).swapTo{value: msg.value}(50, 50, 0, 0);

        emit Deposit(msg.sender, msg.value);
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

    event WeightsUpdated(uint256 uniswapPortion, uint256 balancerPortion);

}
