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
    const ROBINHOOD_ADDRESS = "0x40B38765696e3d5d8d9d834D8AaD4bB6e418E489";

    // Impersonating vitalik's account
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ROBINHOOD_ADDRESS],
    });

    // Make whale the signer
    const whale = await hre.ethers.getSigner(ROBINHOOD_ADDRESS);

    const LiquidityManager = await hre.ethers.getContractFactory(
      "LiquidityManager"
    );
    const manager = await LiquidityManager.deploy();
    const managerAddress = await manager.getAddress();

    const RPVault = await hre.ethers.getContractFactory("RPVault");
    const vault = await RPVault.deploy(managerAddress);

    const provider = hre.ethers.provider;

    return { manager, vault, owner, whale, otherAccount, provider };
  }

  describe("Setup and Deployment", () => {
    it("Should setup the LM", async () => {
      const { manager, owner } = await loadFixture(deployFixture);

      expect(await manager.owner()).to.equal(owner.address);
      expect(await manager.allocatedAssets()).to.equal(0);
      expect(await manager.totalAssets()).to.equal(0);
      expect(await manager.totalWeight()).to.equal(0);
      expect(await manager.name()).to.equal("OZ Eth");
      expect(await manager.symbol()).to.equal("ozETH");
    });

    it("Should allow owner to add and remove Vault", async () => {
      const { manager, vault, owner } = await loadFixture(deployFixture);

      let vaultAddress = await vault.getAddress();

      expect(
        await manager
          .connect(owner)
          .addVault(vaultAddress, 10, ethers.ZeroAddress)
      )
        .to.emit(manager, "VaultAdded")
        .withArgs(vaultAddress);

      expect(await manager.vaults(vaultAddress)).to.equal(vaultAddress);
      expect(await manager.totalWeight()).to.equal(10);

      expect(await manager.connect(owner).removeVault(vaultAddress))
        .to.emit(manager, "VaultRemoved")
        .withArgs(vaultAddress);
      vaultAddress = await vault.getAddress();

      expect(await manager.vaults(vaultAddress)).to.equal(ethers.ZeroAddress);
      expect(await manager.totalWeight()).to.equal(0);
    });
  });

  describe("Integration tests on LM", () => {
    let manager: any;
    let whale: any;
    let owner: any;
    let vault: any;

    beforeEach(async () => {
      ({ manager, owner, whale } = await loadFixture(deployFixture));

      const managerAddress = await manager.getAddress();
      const RPVault = await ethers.getContractFactory("RPVault");

      vault = await RPVault.deploy(managerAddress);
      const vaultAddress = await vault.getAddress();

      await manager
        .connect(owner)
        .addVault(vaultAddress, 10, ethers.ZeroAddress);
    });

    it("Should revert when no eth sent", async () => {
      expect(await manager.connect(whale).stake()).to.be.revertedWith(
        "stake: Invalid amount"
      );
    });

    it("Should stake assets and receive LP tokens", async () => {
      const amount = ethers.parseEther("1");
      const managerAddress = await manager.getAddress();
      const balanceBefore = await ethers.provider.getBalance(managerAddress);
      expect(balanceBefore).to.equal(0);

      await manager.connect(whale).stake({ value: amount });

      // Manager should not have any ETH
      expect(await manager.balance()).to.equal(0);
      expect(await manager.totalAssets()).to.equal(amount);
      expect(await manager.balanceOf(whale.address)).to.equal(amount);
    });

    it("Should not restake when restaking contract is not set", async () => {
      const erc20_abi = [
        "function balanceOf(address) external view returns (uint256)",
        "function approve(address spender, uint256 amount) external returns (bool)",
      ];

      const rethContract = new hre.ethers.Contract(
        "0xae78736cd615f374d3085123a210448e74fc6393",
        erc20_abi,
        ethers.provider
      );

      const vaultAddress = await vault.getAddress();
      const vaultBalanceBefore = await ethers.provider.getBalance(
        vaultAddress
      );

      expect(vaultBalanceBefore).to.equal(0);
      const rethVaultBalanceBfore = await rethContract.balanceOf(
        vaultAddress
      );
      expect(rethVaultBalanceBfore).to.be.eq(0);

      const managerAddress = await manager.getAddress();
      const balanceBefore = await ethers.provider.getBalance(managerAddress);
      expect(balanceBefore).to.equal(0);

      const amount = ethers.parseEther("1");
      await manager.connect(whale).stake({ value: amount });

      const balanceAfter = await ethers.provider.getBalance(managerAddress);
      expect(balanceAfter).to.equal(0);

      // rEth should be restaked
      const rethVaultBalanceAfter = await rethContract.balanceOf(
        vaultAddress
      );

      expect(rethVaultBalanceAfter).to.be.gt(0);
    });

    describe("Restaking on Eigen Layer", () => {
      let vault: any;

      beforeEach(async () => {
        ({ manager, owner, whale } = await loadFixture(deployFixture));

        const managerAddress = await manager.getAddress();
        const RPVault = await ethers.getContractFactory("RPVault");

        vault = await RPVault.deploy(managerAddress);
        const vaultAddress = await vault.getAddress();

        const REthRestaking = await hre.ethers.getContractFactory("MockEigenLayer");
        const rEthRestaking = await REthRestaking.deploy();
        const rEthRestakingAddress = await rEthRestaking.getAddress();

        await manager
          .connect(owner)
          .addVault(vaultAddress, 100, rEthRestakingAddress);
      });

      it("Should have weight set", async () => {
        const vaultAddress = await vault.getAddress();
        expect(await manager.vaults(vaultAddress)).to.equal(vaultAddress);
        expect(await manager.totalWeight()).to.equal(100);

        const weight = await manager.weights(0);
        expect(weight[0]).to.equal(100);
        expect(weight[1]).to.equal(vaultAddress);
      });

      it.only("Should restake with restaking contract is set", async () => {
        const erc20_abi = [
          "function balanceOf(address) external view returns (uint256)",
          "function approve(address spender, uint256 amount) external returns (bool)",
        ];

        const rethContract = new hre.ethers.Contract(
          "0xae78736cd615f374d3085123a210448e74fc6393",
          erc20_abi,
          ethers.provider
        );

        const vaultAddress = await vault.getAddress();
        const vaultBalanceBefore = await ethers.provider.getBalance(
          vaultAddress
        );

        expect(vaultBalanceBefore).to.equal(0);
        const rethVaultBalanceBfore = await rethContract.balanceOf(
          vaultAddress
        );
        expect(rethVaultBalanceBfore).to.be.eq(0);

        const managerAddress = await manager.getAddress();
        const balanceBefore = await ethers.provider.getBalance(managerAddress);
        expect(balanceBefore).to.equal(0);

        const amount = ethers.parseEther("1");
        await manager.connect(whale).stake({ value: amount });

        const balanceAfter = await ethers.provider.getBalance(managerAddress);
        expect(balanceAfter).to.equal(0);

        // rEth should be restaked
        const rethVaultBalanceAfter = await rethContract.balanceOf(
          vaultAddress
        );

        expect(rethVaultBalanceAfter).to.be.eq(0);
      });
    });
  });
});
