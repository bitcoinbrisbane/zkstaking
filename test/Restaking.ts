import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { expect } from "chai";
import { Contract } from "ethers";
import hre, { ethers, network } from "hardhat";

const MAINNET_RETH = "0xae78736cd615f374d3085123a210448e74fc6393";
const MAINNET_RP_ROUTER = "0x16D5A408e807db8eF7c578279BEeEe6b228f1c1C";

describe("rETH restaking", () => {
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
      expect(await vault.asset()).to.equal(
        "0xae78736Cd615f374D3085123A210448E74Fc6393"
      );
    });
  });
});
