// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "../IOracle.sol";
import {IVault} from "../IVault.sol";

interface IRocketPoolRouter {
    function swapFrom(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut, uint256 _tokensIn) external;
    function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) external payable;
}

contract RPVault is ERC20, IVault, Ownable {
    address private constant lpToken = 0xae78736Cd615f374D3085123A210448E74Fc6393; // rETH
    address private constant _router = 0x16D5A408e807db8eF7c578279BEeEe6b228f1c1C; // https://etherscan.io/address/0x16d5a408e807db8ef7c578279beeee6b228f1c1c#writeContract & https://github.com/rocket-pool/rocketpool-router/blob/master/src/RocketPoolRouter.ts#L25
    address private _oracle;
    address private immutable _self;

    uint256 public uniswapPortion;
    uint256 public balancerPortion;
    uint256 public vestingPeriod;

    mapping(address => uint256) balances; // Eth deposited by user
    mapping(address => uint256) nextClaimTime;

    function balance () external view returns (uint256) {
        return _self.balance;
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
        vestingPeriod = 1 days;
        _self = address(this);

        IERC20(lpToken).approve(_router, type(uint256).max);
    }

    function deposit() external payable {
        uint256 amount = msg.value;

        // Check deposit amount
        require(amount > 0, "RPLVault: Invalid deposit amount");

        IRocketPoolRouter(_router).swapTo{value: msg.value}(uniswapPortion, balancerPortion, 0, amount);
        
        nextClaimTime[msg.sender] = block.timestamp + vestingPeriod;
        balances[msg.sender] += amount;
        _mint(msg.sender, amount);

        emit Deposit(msg.sender, amount);
    }

    function stake(uint256 amount) external onlyOwner {
        require(amount > _self.balance, "RPLVault: Invalid amount");
        IRocketPoolRouter(_router).swapTo{value: amount}(uniswapPortion, balancerPortion, 0, amount);
        emit Staked(amount);
    }

    function stakeAll() external onlyOwner {
        uint256 amount = _self.balance;
        IRocketPoolRouter(_router).swapTo{value: amount}(uniswapPortion, balancerPortion, 0, amount);
        emit Staked(amount);
    }

    function unstakeAll() external onlyOwner {
        // rETH balance of this contract
        uint256 amount = IERC20(lpToken).balanceOf(_self);

        // Get the current balance of this contract in ETH
        uint256 balanceBefore = msg.sender.balance;

        // function swapFrom(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut, uint256 _tokensIn) external;
        IRocketPoolRouter(_router).swapFrom(uniswapPortion, balancerPortion, 0, amount, amount);
        uint256 balanceAfter = msg.sender.balance;

        uint256 delta = balanceAfter - balanceBefore;
        emit Staked(delta);
    }

    function exitAll() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "RPLVault: Insufficient balance");

        _exit(amount);
    }

    function exit(uint256 amount) external {
        require(amount > 0, "RPLVault: Invalid withdraw amount");
        require(balances[msg.sender] >= amount, "RPLVault: Insufficient balance");

        _exit(amount);
    }

    function _exit(uint256 amount) internal {
        // remove the users ETH balance
        // function swapFrom(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut, uint256 _tokensIn) external;

        uint256 tokensIn = IERC20(lpToken).balanceOf(_self);

        // Get the current balance of this contract in ETH
        uint256 balanceBefore = _self.balance;
        IRocketPoolRouter(_router).swapFrom(uniswapPortion, balancerPortion, 0, amount, tokensIn);
        // uint256 balanceAfter = _self.balance;

        // // Amount of ETH traded back to this contract via the router
        // uint256 delta = balanceBefore - balanceAfter;

        // // Decrement the users balance
        // balances[msg.sender] -= amount;
        
        // _burn(msg.sender, amount);
        // IERC20(lpToken).transfer(msg.sender, amount);

        // address payable sender = payable(msg.sender);
        // (bool sent, ) = sender.call{value: delta}("");
        // require(sent, "Failed to send Ether");

        emit Withdraw(msg.sender, amount);
    }

    function getLatestPrice() external view returns (int) {
        IOracle oracle = IOracle(_oracle);
        return oracle.getLatestPrice();
    }

    function emerganceyWithdraw() external onlyOwner {
        uint256 amount = IERC20(lpToken).balanceOf(_self);
        IERC20(lpToken).transfer(owner(), amount);

        payable(owner()).transfer(address(this).balance);
    }
    
    receive() external payable{}

    event Staked(uint256 amount);
    event WeightsUpdated(uint256 uniswapPortion, uint256 balancerPortion);
    event Unstaked(uint256 amount);
}
