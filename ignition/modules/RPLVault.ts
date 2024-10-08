import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const RPVaultModule = buildModule("RPVaultModule", (m) => {
  const rpVault = m.contract("RPVault", [], {});

  return { rpVault };
});

export default RPVaultModule;
