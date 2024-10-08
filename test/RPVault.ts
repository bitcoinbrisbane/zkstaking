import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { expect } from "chai";
import hre, { network } from "hardhat";

describe("RPLVault", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // const lockedAmount = ONE_GWEI;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    // Get whale account to impersonate
    const vitalik_address = "0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B";

    //  impersonating vitalik's account
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [vitalik_address],
    });

    //   make vitalik the signer
    const signer = await hre.ethers.getSigner(vitalik_address);

    const RPVault = await hre.ethers.getContractFactory("RPVault");
    const vault = await RPVault.deploy();

    return { vault, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should setup the vault", async function () {
      const { vault, owner } = await loadFixture(deployFixture);

      expect(await vault.owner()).to.equal(owner.address);
    });
  });
});
