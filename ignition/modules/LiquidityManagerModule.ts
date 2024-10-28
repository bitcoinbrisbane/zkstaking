// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LiquidityManagerModule = buildModule("LiquidityManagerModule", (m) => {
  const lm = m.contract("LiquidityManager", [], {});

  return { lm };
});

export default LiquidityManagerModule;
