// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LiqudityManagerModule = buildModule("LiqudityManagerModule", (m) => {
  const lm = m.contract("LiqudityManager", [], {});

  return { lm };
});

export default LiqudityManagerModule;
