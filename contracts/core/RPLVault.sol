// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "../IOracle.sol";
import {IVault} from "../IVault.sol";
import {IRocketPoolRouter} from "./IRocketPoolRouter.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RPVault is ERC20, IVault, Ownable, ReentrancyGuard {
    address private constant _lpToken =
        0xae78736Cd615f374D3085123A210448E74Fc6393; // rETH
    address private constant _router =
        0x16D5A408e807db8eF7c578279BEeEe6b228f1c1C; // https://etherscan.io/address/0x16d5a408e807db8ef7c578279beeee6b228f1c1c#writeContract & https://github.com/rocket-pool/rocketpool-router/blob/master/src/RocketPoolRouter.ts#L25
    address private _oracle;
    address private immutable _self;

    uint256 public uniswapPortion;
    uint256 public balancerPortion;
    uint256 public vestingPeriod;

    mapping(address => uint256) public balances; // Eth deposited by sender
    mapping(address => uint256) public nextClaimTime;

    function asset() external pure returns (address) {
        return _lpToken;
    }

    function balance() external view returns (uint256) {
        return _self.balance;
    }

    function totalAssets()
        external
        view
        override
        returns (uint256 totalManagedAssets)
    {
        return IERC20(_lpToken).balanceOf(_self);
    }

    function getOracle() external view returns (address) {
        return _oracle;
    }

    function getRouter() external pure returns (address) {
        return _router;
    }


    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function setOracle(address oracle) external onlyOwner {
        _oracle = oracle;
    }

    function setWeight(
        uint256 _uniswapPortion,
        uint256 _balancerPortion
    ) external onlyOwner {
        require(
            _uniswapPortion + _balancerPortion == 100,
            "RPLVault: Invalid weight"
        );

        uniswapPortion = _uniswapPortion;
        balancerPortion = _balancerPortion;

        emit WeightsUpdated(uniswapPortion, balancerPortion);
    }

    constructor() ERC20("ZK rETH", "zkrETH") Ownable(msg.sender) {
        uniswapPortion = 50;
        balancerPortion = 50;
        vestingPeriod = 1 days;
        _self = address(this);

        IERC20(_lpToken).approve(_router, type(uint256).max);
    }

    function deposit() external payable nonReentrant() {
        uint256 amount = msg.value;
        _deposit(amount);
    }

    function _deposit(uint256 amount) private {
        // Check deposit amount
        require(amount > 0, "RPLVault: Invalid deposit amount");

        // Get the current balance of this contract in ETH
        uint256 balanceBefore = _self.balance;

        // Swap ETH to rETH
        IRocketPoolRouter(_router).swapTo{value: msg.value}(
            uniswapPortion,
            balancerPortion,
            0,
            amount
        );

        assert(IERC20(_lpToken).balanceOf(_self) > 0);
        
        // Get the current balance of this contract in ETH
        uint256 balanceAfter = _self.balance;
        assert(balanceAfter > balanceBefore);
        
        // Amount of ETH traded back to this contract via the router
        uint256 delta = balanceBefore - balanceAfter;
        assert(delta > 0);

        nextClaimTime[msg.sender] = block.timestamp + vestingPeriod;
        balances[msg.sender] += amount;
        _mint(msg.sender, delta);

        emit Deposit(msg.sender, amount);
    }

    // function stakeAll() external onlyOwner {
    //     uint256 amount = _self.balance;
    //     IRocketPoolRouter(_router).swapTo{value: amount}(
    //         uniswapPortion,
    //         balancerPortion,
    //         0,
    //         amount
    //     );
    //     emit Staked(amount);
    // }

    function withdraw(uint256 assets) external {
        require(assets > 0, "RPLVault: Invalid withdraw amount");
        require(
            balances[msg.sender] >= assets,
            "RPLVault: Insufficient balance"
        );
        
        // rETH balance of this contract
        uint256 amount = IERC20(_lpToken).balanceOf(_self);

        // Get the current balance of this contract in ETH
        uint256 balanceBefore = _self.balance;

        // function swapFrom(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut, uint256 _tokensIn) external;
        IRocketPoolRouter(_router).swapFrom(
            uniswapPortion,
            balancerPortion,
            0,
            amount,
            amount
        );

        uint256 balanceAfter = _self.balance;
        assert(balanceAfter > balanceBefore);

        uint256 delta = balanceAfter - balanceBefore;
        emit Staked(delta);
    }

    // function exitAll() external {
    //     uint256 amount = balances[msg.sender];
    //     require(amount > 0, "RPLVault: Insufficient balance");

    //     _exit(amount);
    // }

    // function exit(uint256 amount) external {
    //     require(amount > 0, "RPLVault: Invalid withdraw amount");
    //     require(
    //         balances[msg.sender] >= amount,
    //         "RPLVault: Insufficient balance"
    //     );

    //     _exit(amount);
    // }

    function _withdraw(uint256 amount, address sender) internal {
        // remove the users ETH balance
        // function swapFrom(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut, uint256 _tokensIn) external;

        uint256 tokensIn = IERC20(_lpToken).balanceOf(_self);

        // Get the current balance of this contract in ETH
        uint256 balanceBefore = _self.balance;

        IRocketPoolRouter(_router).swapFrom(
            uniswapPortion,
            balancerPortion,
            0,
            amount,
            tokensIn
        );

        uint256 balanceAfter = _self.balance;

        // // Amount of ETH traded back to this contract via the router
        // uint256 delta = balanceBefore - balanceAfter;

        // // Decrement the users balance
        // balances[msg.sender] -= amount;

        // _burn(msg.sender, amount);
        // IERC20(lpToken).transfer(msg.sender, amount);

        // address payable sender = payable(msg.sender);
        // (bool sent, ) = sender.call{value: delta}("");
        // require(sent, "Failed to send Ether");

        emit Withdrawn(sender, amount);
    }

    function getLatestPrice() external view returns (int) {
        IOracle oracle = IOracle(_oracle);
        return oracle.getLatestPrice();
    }

    function emerganceyWithdraw() external onlyOwner {
        uint256 amount = IERC20(_lpToken).balanceOf(_self);
        IERC20(_lpToken).transfer(owner(), amount);

        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {
        _deposit(msg.value);
    }

    event Staked(uint256 amount);
    event WeightsUpdated(uint256 uniswapPortion, uint256 balancerPortion);
    event Withdrawn(uint256 amount, address indexed sender);
}
