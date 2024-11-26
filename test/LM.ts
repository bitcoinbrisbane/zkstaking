import { expect } from "chai";
import hre, { ethers, network } from "hardhat";

describe.skip("LiquidityManager", () => {
  let liquidityManager: any;
  let mockVault1: any;
  let mockVault2: any;
  let owner: any;
  let user1: any;
  let user2: any;

  beforeEach(async () => {
    // Get signers
    [owner, user1, user2] = await hre.ethers.getSigners();

    // Deploy mock vault contract
    const MockVault = await ethers.getContractFactory("MockVault");
    mockVault1 = await MockVault.deploy();
    mockVault2 = await MockVault.deploy();

    // Deploy LiquidityManager
    const LiquidityManager = await ethers.getContractFactory("LiquidityManager");
    liquidityManager = await LiquidityManager.deploy();

    // Wait for deployments
    await mockVault1.deployed();
    await mockVault2.deployed();
    await liquidityManager.deployed();
  });

  describe("Vault Management", () => {
    it("Should add a vault successfully", async () => {
      const weight = 50;
      await expect(liquidityManager.connect(owner).addVault(mockVault1.address, weight))
        .to.emit(liquidityManager, "VaultAdded")
        .withArgs(mockVault1.address);

      const vault = await liquidityManager.vaults(mockVault1.address);
      expect(vault).to.equal(mockVault1.address);

      const weight1 = await liquidityManager.weights(0);
      expect(weight1.weight).to.equal(weight);
      expect(weight1.vault).to.equal(mockVault1.address);
    });

    it("Should fail to add duplicate vault", async () => {
      await liquidityManager.connect(owner).addVault(mockVault1.address, 50);
      await expect(
        liquidityManager.connect(owner).addVault(mockVault1.address, 50)
      ).to.be.revertedWith("addVault: Vault already exists");
    });

    it("Should fail if non-owner tries to add vault", async () => {
      await expect(
        liquidityManager.connect(user1).addVault(mockVault1.address, 50)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should remove vault successfully", async () => {
      await liquidityManager.connect(owner).addVault(mockVault1.address, 50);
      await liquidityManager.connect(owner).removeVault(mockVault1.address);

      const vault = await liquidityManager.vaults(mockVault1.address);
      expect(vault).to.equal(ethers.ZeroAddress);
    });
  });

  describe("Staking", () => {
    beforeEach(async () => {
      // Add vaults with weights
      await liquidityManager.connect(owner).addVault(mockVault1.address, 60);
      await liquidityManager.connect(owner).addVault(mockVault2.address, 40);
    });

    it("Should stake ETH successfully", async () => {
      const stakeAmount = ethers.parseEther("1");

      await expect(
        liquidityManager.connect(user1).stake({ value: stakeAmount })
      ).to.emit(liquidityManager, "Staked")
        .withArgs(user1.address, stakeAmount);

      const balance = await liquidityManager.balanceOf(user1.address);
      expect(balance).to.equal(stakeAmount);

      const totalAssets = await liquidityManager.totalAssets();
      expect(totalAssets).to.equal(stakeAmount);
    });

    it("Should fail staking with 0 amount", async () => {
      await expect(
        liquidityManager.connect(user1).stake({ value: 0 })
      ).to.be.revertedWith("stake: Invalid amount");
    });

    it("Should distribute ETH according to weights", async () => {
      const stakeAmount = ethers.parseEther("1");
      await liquidityManager.connect(user1).stake({ value: stakeAmount });

      const vault1Balance = await mockVault1.getBalance();
      const vault2Balance = await mockVault2.getBalance();

      // Check if distribution matches weights (60/40)
      expect(vault1Balance).to.equal(60);
      expect(vault2Balance).to.equal(40);
    });
  });

  describe("Unstaking", () => {
    const stakeAmount = ethers.parseEther("1");

    beforeEach(async () => {
      await liquidityManager.connect(owner).addVault(mockVault1.address, 100);
      await liquidityManager.connect(user1).stake({ value: stakeAmount });
      await liquidityManager.connect(user1).approve(liquidityManager.address, stakeAmount);
    });

    it("Should unstake ETH successfully", async () => {
      const initialBalance = await ethers.provider.getBalance(user1.address);

      await expect(
        liquidityManager.connect(user1).unstake(stakeAmount)
      ).to.emit(liquidityManager, "Unstaked")
        .withArgs(user1.address, stakeAmount);

      const finalBalance = await ethers.provider.getBalance(user1.address);
      expect(finalBalance.gt(initialBalance)).to.be.true;

      const totalAssets = await liquidityManager.totalAssets();
      expect(totalAssets).to.equal(0);
    });

    it("Should fail unstaking with 0 amount", async () => {
      await expect(
        liquidityManager.connect(user1).unstake(0)
      ).to.be.revertedWith("unstake: Invalid amount");
    });

    it("Should fail unstaking more than staked amount", async () => {
      const tooMuch = 100;
      await expect(
        liquidityManager.connect(user1).unstake(tooMuch)
      ).to.be.reverted;
    });
  });
});
