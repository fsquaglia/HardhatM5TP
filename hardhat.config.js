require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

// ################ hardhat.config.js #################
console.log("ALCHEMY_API_KEY:", process.env.ALCHEMY_API_KEY);

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
if (!ALCHEMY_API_KEY || !SEPOLIA_PRIVATE_KEY || !ETHERSCAN_API_KEY) {
  throw new Error(
    "Please set ALCHEMY_API_KEY, SEPOLIA_PRIVATE_KEY, and ETHERSCAN_API_KEY in your environment variables."
  );
}

module.exports = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_API_KEY,
    },
  },
  gasReporter: {
    currency: "USD",
    enabled: true,
    excludeContracts: [],
    src: "./contracts",
  },
};
