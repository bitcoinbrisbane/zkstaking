import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition-ethers";
import "solidity-coverage";

import dotenv from "dotenv";
dotenv.config();

const PK = process.env.PK;
const SEPOLIA_PK = process.env.SEPOLIA_PK;

// if (!PK) {
//   throw new Error("PK is not set");
// }

// vars.get("PK", PK);

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
      viaIR: true,
    },
  },
  etherscan: {
    apiKey: {
      base: process.env.ETHSCAN_API_KEY || "",
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.FORKING_URL as string,
        // blockNumber: 19197423,
        enabled: true,
      },
      blockGasLimit: 60000000, // Network block gasLimit
    },
    // main: {
    //   url: process.env.FORKING_URL as string,
    //   accounts: [PK as string],
    // },
    sepolia: {
      url: process.env.SEPOLIA_NODE as string,
      accounts: [SEPOLIA_PK as string],
    },
  },
};

export default config;
