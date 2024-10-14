// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "../IOracle.sol";
import {IVault} from "../IVault.sol";

interface IRocketPoolRouter {
    function swapFrom(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) external;
    // function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut, uint256 _ethTokensIn) external payable;
    // https://github.com/rocket-pool/rocketpool-router/blob/master/contracts/RocketSwapRouter.sol#L64
    function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) external payable;
}

contract RPVault is ERC20, IVault, Ownable {
    address private constant lpToken = 0xae78736Cd615f374D3085123A210448E74Fc6393; // rETH
    address private constant _router = 0x16D5A408e807db8eF7c578279BEeEe6b228f1c1C; // https://etherscan.io/address/0x16d5a408e807db8ef7c578279beeee6b228f1c1c#writeContract & https://github.com/rocket-pool/rocketpool-router/blob/master/src/RocketPoolRouter.ts#L25
    address private _oracle;
    address private immutable _self;

    uint256 public uniswapPortion;
    uint256 public balancerPortion;

    mapping(address => uint256) balances;

    function balance () external view returns (uint256) {
        return address(this).balance;
    }

    function lpBalance() external view returns (uint256) {
        return IERC20(lpToken).balanceOf(_self);
    }

    function getOracle() external view returns (address) {
        return _oracle;
    }

    function getRouter() external pure returns (address) {
        return _router;
    }

    function getUnderlyingToken() external pure returns (address) {
        return lpToken;
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

    constructor() ERC20("ZK rETH", "zkrETH") Ownable(msg.sender) {
        uniswapPortion = 50;
        balancerPortion = 50;
        _self = address(this);
    }

    function deposit() external payable {
        // Check deposit amount
        require(msg.value > 0, "RPLVault: Invalid deposit amount");

        uint256 amount = msg.value;
        // uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut 
        // function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut
        IRocketPoolRouter(_router).swapTo{value: msg.value}(uniswapPortion, balancerPortion, 0, amount);
        balances[msg.sender] += amount;
        _mint(msg.sender, amount);

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "RPLVault: Invalid withdraw amount");
        require(balances[msg.sender] >= amount, "RPLVault: Insufficient balance");

        IRocketPoolRouter(_router).swapFrom(uniswapPortion, balancerPortion, 0, amount);

        balances[msg.sender] -= amount;
        _burn(msg.sender, amount);
        // IERC20(lpToken).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    // function exit() external {
    //     uint256 amount = balances[msg.sender];
    //     require(amount > 0, "RPLVault: Insufficient balance");

    //     balances[msg.sender] = 0;
    //     IERC20(lpToken).transfer(msg.sender, amount);

    //     emit Withdraw(msg.sender, amount);
    // }

    function getLatestPrice() external view returns (int) {
        IOracle oracle = IOracle(_oracle);
        return oracle.getLatestPrice();
    }

    function emerganceyWithdraw() external onlyOwner {
        uint256 amount = IERC20(lpToken).balanceOf(_self);
        IERC20(lpToken).transfer(owner(), amount);

        payable(owner()).transfer(address(this).balance);
    }

    event WeightsUpdated(uint256 uniswapPortion, uint256 balancerPortion);
}
