import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { expect } from "chai";
import { Contract } from "ethers";
import hre, { ethers, network } from "hardhat";

// const MAINNET_ROCKET_STORAGE = "0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46";
// const MAINNET_WETH = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
const MAINNET_RETH = "0xae78736cd615f374d3085123a210448e74fc6393";
const MAINNET_RP_ROUTER = "0x16D5A408e807db8eF7c578279BEeEe6b228f1c1C";
// const MAINNET_UNISWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
// const MAINNET_UNISWAP_QUOTER = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6";
// const MAINNET_BALANCER_VAULT = "0xba12222222228d8ba445958a75a0704d566bf2c8";


describe.only("RPLVault", () => {
  async function deployFixture() {
    const [owner, otherAccount] = await hre.ethers.getSigners();

    // Get whale account to impersonate
    const ROBINHOOD_ADDRESS = "0x40B38765696e3d5d8d9d834D8AaD4bB6e418E489";

    // Impersonating robinHood's account
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ROBINHOOD_ADDRESS],
    });

    // Make robinHood the signer
    const robinHood = await hre.ethers.getSigner(ROBINHOOD_ADDRESS);

    // Check the balance of the account
    const balance = await hre.ethers.provider.getBalance(ROBINHOOD_ADDRESS);
    expect(balance).to.be.gt(0);

    const RPVault = await hre.ethers.getContractFactory("RPVault");
    const vault = await RPVault.deploy();

    const provider = hre.ethers.provider;

    return { vault, owner, robinHood, otherAccount, provider };
  }

  describe("Integration tests on RPL", () => {
    it.only("Should do a swap via the router", async () => {
      const provider = hre.ethers.provider;
      const [owner, robinHood] = await hre.ethers.getSigners();

      // transfer ETH from robinHood to owner
      const tx = await robinHood.sendTransaction({
        to: await owner.getAddress(),
        value: ethers.parseEther("1"),
      });

      const abi = [
        "function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) external payable",
        "function swapFrom(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut, uint256 _tokensIn) external",
      ];

      const router = new Contract(
        MAINNET_RP_ROUTER,
        abi,
        provider
      );

      const erc20_abi = [
        "function balanceOf(address) external view returns (uint256)",
        "function approve(address spender, uint256 amount) external returns (bool)",
      ];

      const rethContract = new hre.ethers.Contract(
        MAINNET_RETH,
        erc20_abi,
        provider
      );

      const owner_address = await owner.getAddress();
      const balance_before = await rethContract.balanceOf(owner_address);

      // Do a swap
      await router.connect(owner).swapTo(50, 50, 100, 100, {
        value: ethers.parseEther("1"),
      });

      const balance = await rethContract.balanceOf(owner_address);
      expect(balance).to.be.gt(balance_before);

      // Approve
      await rethContract
        .connect(owner)
        .approve(MAINNET_RP_ROUTER, balance);

      // Do a swap back
      await router.connect(owner).swapFrom(50, 50, 0, 100, balance);
    });
  });

  describe("Stake and unstake", () => {
    it("Should setup the vault", async () => {
      const { vault, owner } = await loadFixture(deployFixture);

      expect(await vault.owner()).to.equal(owner.address);
      expect(await vault.uniswapPortion()).to.equal(50);
      expect(await vault.balancerPortion()).to.equal(50);
    });

    it.skip("Should deposit 1 ETH and withdraw 1 ETH", async () => {
      const { vault, owner, provider } = await loadFixture(deployFixture);

      const depositAmount = hre.ethers.parseEther("1");
      const ownerBalance = await provider.getBalance(owner.address);
      console.log(ownerBalance.toString());

      await vault.connect(owner).deposit({ value: depositAmount });

      // Should have no balance as its stake in RP
      const ethBalance = await vault.balance();
      expect(ethBalance).to.equal(0);

      const balance = await vault.balance();
      expect(balance).to.be.gt(0);
      console.log(balance.toString());

      const ethBalanceOwner = await vault.balanceOf(owner.address);
      console.log(ethBalanceOwner.toString());
      expect(ethBalanceOwner).to.equal(depositAmount);
    });

    it("Should deposit ETH and receive rETH", async () => {
      const { vault, owner, vitalik, provider } = await loadFixture(deployFixture);

      const depositAmount = hre.ethers.parseEther("1");
      const vitalikBalance = await provider.getBalance(vitalik.address);
      console.log(vitalikBalance.toString());

      expect(vitalikBalance).to.be.gt(0);

      const vaultAddress = await vault.getAddress();
      console.log(vaultAddress);

      await vault.connect(vitalik).deposit({ value: depositAmount });
      const balanceAfter = await provider.getBalance(vitalik.address);
      expect(balanceAfter).to.be.lt(vitalikBalance);

      const ethBalanceAfter = await provider.getBalance(vitalik.address);
      expect(ethBalanceAfter).to.equal(0);
    });
  });
});

// describe("Deployment", () => {
//   it("Should setup the vault", async () => {
//     const { vault, owner } = await loadFixture(deployFixture);

//     expect(await vault.owner()).to.equal(owner.address);
//     expect(await vault.uniswapPortion()).to.equal(50);
//     expect(await vault.balancerPortion()).to.equal(50);
//   });

//   it("Should let owner set weights", async () => {
//     const { vault, owner } = await loadFixture(deployFixture);

//     expect(await vault.uniswapPortion()).to.equal(50);
//     expect(await vault.balancerPortion()).to.equal(50);

//     await vault.connect(owner).setWeight(60, 40);
//     expect(await vault.uniswapPortion()).to.equal(50);
//     expect(await vault.balancerPortion()).to.equal(50);
//   });

//   it.skip("Should deposit 1 ETH and withdraw 1 ETH", async () => {
//     const { vault, owner, provider } = await loadFixture(deployFixture);

//     const depositAmount = hre.ethers.parseEther("1");
//     const ownerBalance = await provider.getBalance(owner.address);
//     console.log(ownerBalance.toString());

//     await vault.connect(owner).deposit({ value: depositAmount });

//     // Should have no balance as its stake in RP
//     const ethBalance = await vault.balance();
//     expect(ethBalance).to.equal(0);

//     const balance = await vault.balance();
//     expect(balance).to.be.gt(0);
//     console.log(balance.toString());

//     const ethBalanceOwner = await vault.balanceOf(owner.address);
//     console.log(ethBalanceOwner.toString());
//     expect(ethBalanceOwner).to.equal(depositAmount);
//   });

//   it.only("Should deposit", async () => {
//     const { vault, owner, vitalik, provider } = await loadFixture(deployFixture);

//     const depositAmount = hre.ethers.parseEther("1");
//     const vitalikBalance = await provider.getBalance(vitalik.address);
//     console.log(vitalikBalance.toString());

//     expect(vitalikBalance).to.be.gt(0);

//     await vault.connect(vitalik).deposit( { value: depositAmount } );
//     const balanceAfter = await provider.getBalance(vitalik.address);
//     expect(balanceAfter).to.be.lt(vitalikBalance);

//     const vaultAddress = await vault.getAddress();
//     const ethBalanceAfter = await provider.getBalance(vaultAddress);
//     expect(ethBalanceAfter).to.equal(0);
//   });
// });
// });
