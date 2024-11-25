import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TokenModule = buildModule("Token", (m) => {
  const token = m.contract("Token", ["Open ZK", "OZK"], {});

  return { token };
});

export default TokenModule;
