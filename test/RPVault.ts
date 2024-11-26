import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { expect } from "chai";
import hre, { ethers, network } from "hardhat";

const MAINNET_RETH = "0xae78736cd615f374d3085123a210448e74fc6393";

describe("RPLVault", () => {
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

    // Send owner 1 eth
    const tx = await robinHood.sendTransaction({
      to: await owner.getAddress(),
      value: ethers.parseEther("1"),
    });

    const RPVault = await hre.ethers.getContractFactory("RPVault");
    const vault = await RPVault.deploy(ethers.ZeroAddress);

    const provider = hre.ethers.provider;

    return { vault, owner, robinHood, otherAccount, provider };
  }

  describe("Deployment", () => {
    it("Should setup the vault", async () => {
      const { vault, owner } = await loadFixture(deployFixture);

      expect(await vault.owner()).to.equal(owner.address);
      expect(await vault.uniswapPortion()).to.equal(50);
      expect(await vault.balancerPortion()).to.equal(50);
      expect(await vault.totalAssets()).to.equal(0);
      expect(await vault.asset()).to.equal("0xae78736Cd615f374D3085123A210448E74Fc6393");
    });

    it("Should let owner set weights", async () => {
      const { vault, owner } = await loadFixture(deployFixture);

      expect(await vault.uniswapPortion()).to.equal(50);
      expect(await vault.balancerPortion()).to.equal(50);

      await vault.connect(owner).setWeight(60, 40);
      expect(await vault.uniswapPortion()).to.equal(60);
      expect(await vault.balancerPortion()).to.equal(40);
    });

    it("Should not let non-owner set weights", async () => {
      const { vault, otherAccount } = await loadFixture(deployFixture);
      await expect(vault.connect(otherAccount).setWeight(60, 40)).to.be
        .reverted;
    });

    it("Should not allow uniswap and balancer weights to exceed 100", async () => {
      const { vault, owner } = await loadFixture(deployFixture);
      await expect(vault.connect(owner).setWeight(60, 50)).to.be.reverted;
    });
  });

  describe("Deposit and withdraw", () => {
    it("Should deposit 1 ETH and receive rETH", async () => {
      const { vault, owner, provider } = await loadFixture(deployFixture);

      const depositAmount = hre.ethers.parseEther("1");
      const ownerBalance = await provider.getBalance(owner.address);
      expect(ownerBalance).to.be.greaterThanOrEqual(depositAmount);

      // await vault.connect(owner).deposit({ value: depositAmount });
      await expect(vault.connect(owner).deposit({ value: depositAmount })).to.emit(vault, "Deposit");
      const afterOwnerBalance = await provider.getBalance(owner.address);
      expect(afterOwnerBalance).to.be.lt(ownerBalance);

      // Should have no balance as its stake in RP
      const ethBalance = await vault.balance();
      expect(ethBalance).to.equal(0);

      // Should still have no balance as its stake in RP
      const balance = await vault.balance();
      expect(balance).to.equal(0);

      const ethBalanceOwner = await vault.balanceOf(owner.address);
      expect(ethBalanceOwner).to.equal(depositAmount);

      const totalAssets = await vault.totalAssets();
      expect(totalAssets).to.be.greaterThan(0);

      const reth = await hre.ethers.getContractAt("IERC20", MAINNET_RETH);
      let rETHBalance = await reth.balanceOf(owner.address);

      // expect(rETHBalance).to.be.greaterThan(0);
      // await expect(vault.connect(owner).withdraw(rETHBalance)).to.emit(vault, "Withdraw");
      await vault.connect(owner).withdraw(rETHBalance);
      rETHBalance = await reth.balanceOf(owner.address);

      expect(rETHBalance).to.equal(0);
    });
  });
});
