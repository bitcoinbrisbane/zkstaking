import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { expect } from "chai";
import { Contract, Wallet } from "ethers";
import hre, { network } from "hardhat";

// const MAINNET_ROCKET_STORAGE = "0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46";
// const MAINNET_WETH = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
const MAINNET_RETH = "0xae78736cd615f374d3085123a210448e74fc6393";
// const MAINNET_UNISWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
// const MAINNET_UNISWAP_QUOTER = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6";
// const MAINNET_BALANCER_VAULT = "0xba12222222228d8ba445958a75a0704d566bf2c8";

// const privateKey = process.env.TEST_PRIVATE_KEY || "";

describe("RPLVault", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
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

    // Check the balance of the account
    const balance = await hre.ethers.provider.getBalance(vitalik_address);

    const RPVault = await hre.ethers.getContractFactory("RPVault");
    const vault = await RPVault.deploy();

    const provider = hre.ethers.provider;

    // get block number
    const blockNumber = await provider.getBlockNumber();
    console.log(blockNumber);

    // const wallet = new Wallet(privateKey, provider);

    return { vault, owner, vitalik, otherAccount, provider };
  }

  describe("Test swaps on RPL router", function () {
    it("Should do a swap via the router", async () => {
      const provider = hre.ethers.provider;
      const [owner, otherAccount] = await hre.ethers.getSigners();

      const abi = [
        "function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) external payable",
        "function swapFrom(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut, uint256 _tokensIn) external",
      ];

      const router = new Contract(
        "0x16d5a408e807db8ef7c578279beeee6b228f1c1c",
        abi,
        provider
      );

      const rethContract = new hre.ethers.Contract(
        MAINNET_RETH,
        [
          "function balanceOf(address) external view returns (uint256)",
          "function approve(address spender, uint256 amount) external returns (bool)",
        ],
        provider
      );

      const owner_address = await owner.getAddress();
      const balance_before = await rethContract.balanceOf(owner_address);
      console.log(balance_before);

      // Do a swap
      await router.connect(owner).swapTo(50, 50, 100, 100, {
        value: 1000000000000000000n,
      });

      const balance = await rethContract.balanceOf(owner_address);
      console.log(balance);

      expect(balance).to.be.gt(balance_before);

      // Approve
      await rethContract
        .connect(owner)
        .approve("0x16d5a408e807db8ef7c578279beeee6b228f1c1c", balance);

      // Do a swap back
      await router.connect(owner).swapFrom(50, 50, 0, 100, balance);
    });
  });

  describe("Deployment", () => {
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

      const lpBalance = await vault.lpBalance();
      expect(lpBalance).to.be.gt(0);
      console.log(lpBalance.toString());

      const ethBalanceOwner = await vault.balanceOf(owner.address);
      console.log(ethBalanceOwner.toString());
      expect(ethBalanceOwner).to.equal(depositAmount);

      // await vault.connect(owner).exitAll();
    });

    it.only("Should stake and unstake", async () => {
      const { vault, owner, provider } = await loadFixture(deployFixture);

      const depositAmount = hre.ethers.parseEther("1");
      const ownerBalance = await provider.getBalance(owner.address);
      console.log(ownerBalance.toString());

      const vaultAddress = await vault.getAddress();

      await owner.sendTransaction({
        to: vaultAddress,
        value: depositAmount,
      });

      const balance = await vault.balance();
      expect(balance).to.equal(depositAmount);

      await vault.connect(owner).stakeAll();
      const ethBalanceAfter = await vault.balance();
      expect(ethBalanceAfter).to.equal(0);

      const lpBalance = await vault.lpBalance();
      expect(lpBalance).to.be.gt(0);

      await vault.connect(owner).unstakeAll();
      // const ethBalanceOwner = await vault.balanceOf(owner.address);

      // console.log(ethBalanceOwner.toString());
      // expect(ethBalanceOwner).to.be.approximately(
      //   depositAmount,
      //   1000000000000000
      // );
    });
  });
});
