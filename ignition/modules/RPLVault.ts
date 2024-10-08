import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LiqudityManagerModule = buildModule("LiqudityManagerModule", (m) => {
  const lm = m.contract("LiqudityManager", [], {});

  return { lm };
});

export default LiqudityManagerModule;
