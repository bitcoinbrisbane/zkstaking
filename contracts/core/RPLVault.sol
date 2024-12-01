// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "../IOracle.sol";
import {IVault} from "../IVault.sol";
import {IRocketPoolRouter} from "../vendors/RocketPool/IRocketPoolRouter.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RPVault is ERC20, IVault, Ownable, ReentrancyGuard {
    address private constant _lpToken =
        0xae78736Cd615f374D3085123A210448E74Fc6393; // rETH
    address private constant _router =
        0x16D5A408e807db8eF7c578279BEeEe6b228f1c1C; // https://etherscan.io/address/0x16d5a408e807db8ef7c578279beeee6b228f1c1c#writeContract & https://github.com/rocket-pool/rocketpool-router/blob/master/src/RocketPoolRouter.ts#L25
    address private _oracle;
    address private immutable _self;
    address private immutable _lm;

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
        totalManagedAssets = _totalAssets();
    }

    function _totalAssets() public view returns (uint256) {
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
            "setWeight: Invalid weight"
        );

        uniswapPortion = _uniswapPortion;
        balancerPortion = _balancerPortion;

        emit WeightsUpdated(uniswapPortion, balancerPortion);
    }

    constructor(address lm) ERC20("ZK rETH", "zkrETH") Ownable(msg.sender) {
        uniswapPortion = 50;
        balancerPortion = 50;
        vestingPeriod = 1 days;
        _self = address(this);
        _lm = lm;

        IERC20(_lpToken).approve(_router, type(uint256).max);
    }

    function deposit() external payable nonReentrant() {
        uint256 amount = msg.value;
        // Check deposit amount
        require(amount > 0, "deposit: Invalid deposit amount");
        _deposit(amount, msg.sender);
    }

    function _deposit(uint256 amount, address sender) private {
        // Get the current balance of this contract in ETH
        uint256 balanceBefore = _self.balance;
        uint256 lpBalanceBefore = _totalAssets();

        // Swap ETH to rETH
        IRocketPoolRouter(_router).swapTo{value: amount}(
            uniswapPortion,
            balancerPortion,
            0,
            amount
        );

        // Get the current balance of this contract in ETH
        uint256 balanceAfter = _self.balance;
        assert(balanceBefore > balanceAfter);

        uint256 lpBalanceAfter = _totalAssets();
        assert(lpBalanceAfter > lpBalanceBefore);
        uint256 delta = lpBalanceAfter - lpBalanceBefore;
        assert(delta > 0);

        nextClaimTime[sender] = block.timestamp + vestingPeriod;
        balances[sender] += amount;
        _mint(sender, amount);

        emit Deposit(sender, amount);
    }

    function withdraw(uint256 assets) external onlyLM {
        require(assets > 0, "withdraw: Invalid withdraw amount");
        require(
            balances[msg.sender] >= assets,
            "withdraw: Insufficient balance"
        );

        address payable sender = payable(msg.sender);
        _exit(assets, sender);
    }

    function withdrawShares() external onlyLM {
        uint256 assets = _totalAssets();
        IERC20(_lpToken).transfer(msg.sender, assets);
    }

    function _exit(uint256 amount, address payable sender) internal {
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
        assert(balanceAfter > balanceBefore);

        // Amount of ETH traded back to this contract via the router
        uint256 delta = balanceBefore - balanceAfter;
        assert(delta > 0);

        // Decrement the users balance
        balances[msg.sender] -= amount;

        IERC20(_lpToken).transfer(sender, amount);

        // Burn the users shares
        _burn(msg.sender, amount);

        (bool sent, ) = sender.call{value: delta}("");
        require(sent, "_exit: Failed to send Ether");
        
        emit Withdraw(sender, delta);
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

    modifier onlyLM() {
        // Allow anyone to call this function if the LM is not set
        if (_lm == address(0)) {
            return;
        }

        require(msg.sender == _lm, "RPLVault: Only LM");
        _;
    }

    receive() external payable {
        _deposit(msg.value, msg.sender);
    }

    event WeightsUpdated(uint256 uniswapPortion, uint256 balancerPortion);
}
