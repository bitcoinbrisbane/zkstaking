import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { expect } from "chai";
import hre, { ethers, network } from "hardhat";

describe("Liquidity Manager", () => {
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    // Get whale account to impersonate
    const vitalik_address = "0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B";

    // Impersonating vitalik's account
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [vitalik_address],
    });

    // Make vitalik the signer
    const vitalik = await hre.ethers.getSigner(vitalik_address);

    const LiquidityManager = await hre.ethers.getContractFactory("LiquidityManager");
    const manager = await LiquidityManager.deploy();

    const RPVault = await hre.ethers.getContractFactory("RPVault");
    const vault = await RPVault.deploy();

    const provider = hre.ethers.provider;

    return { manager, vault, owner, vitalik, otherAccount, provider };
  }

  describe.only("Setup and Deployment", () => {
    it("Should setup the LM", async () => {
      const { manager, owner } = await loadFixture(deployFixture);

      expect(await manager.owner()).to.equal(owner.address);
      expect(await manager.unallocatedAssets()).to.equal(0);
      expect(await manager.allocatedAssets()).to.equal(0);
      expect(await manager.totalAssets()).to.equal(0);
      expect(await manager.totalWeight()).to.equal(0);
      expect(await manager.name()).to.equal("OZ Eth");
      expect(await manager.symbol()).to.equal("ozETH");
    });

    it("Should allow owner to add and remove Vault", async () => {
      const { manager, vault, owner } = await loadFixture(deployFixture);

      let vaultAddress = await vault.getAddress();

      expect(await manager.connect(owner).addVault(vaultAddress, 10)).to.emit(manager, "VaultAdded").withArgs(vaultAddress);
      expect(await manager.vaults(vaultAddress)).to.equal(vaultAddress);
      expect(await manager.totalWeight()).to.equal(10);

      await manager.connect(owner).removeVault(vaultAddress);
      vaultAddress = await vault.getAddress();
      expect(await manager.vaults(vaultAddress)).to.equal(ethers.ZeroAddress);
      expect(await manager.totalWeight()).to.equal(0);
    });
  });

  describe("Integration tests on LM", () => {

    let manager: any;
    let vault: any;
    let vitalik: any;

    beforeEach(async () => {
      ({ manager, vitalik } = await loadFixture(deployFixture));
      const RPVault = await ethers.getContractFactory("RPVault");
      const vault = await RPVault.deploy();

      const vaultAddress = await vault.getAddress();

      await manager.connect(manager.owner()).addVault(vaultAddress, 10);
    });

    it.only("Should stake assets and receive LP tokens", async () => {

      const amount = ethers.parseEther("1");
      // const balance_before = await ethers.provider.getBalance(vault.address);

      await manager.connect(vitalik).stake({ value: amount });

      // Manager should not have any ETH
      expect(await manager.balance()).to.equal(0);
      expect(await manager.totalAssets()).to.equal(amount);
      expect(await manager.balanceOf(vitalik.address)).to.equal(amount);

      const MAINNET_RETH = "0xae78736cd615f374d3085123a210448e74fc6393";

      // Check manager has rETH tokens
      const rethContract = new hre.ethers.Contract(
        MAINNET_RETH,
        [
          "function balanceOf(address) external view returns (uint256)",
        ],
        ethers.provider
      );

      const rethBalance = await rethContract.balanceOf(manager.address);
      expect(rethBalance).to.be.gt(0);
    });
  });
});
