import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition-ethers";
import "solidity-coverage";

import dotenv from "dotenv";
dotenv.config();

const PK = process.env.PK;

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
			chains: {
				8453: {
					hardforkHistory: {
						london: 0,
					},
				},
			},
			blockGasLimit: 60000000 // Network block gasLimit
		},
	},
};

export default config;
