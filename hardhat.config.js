// This line imports the Hardhat Ethers plugin, which provides integration with the ethers.js library.
// Ethers.js is a popular JavaScript library for interacting with Ethereum and Ethereum-like blockchains.
// This plugin allows you to deploy contracts, send transactions, and interact with contracts from your Hardhat scripts and tests using ethers.js.
// This line imports the Hardhat Ethers plugin, which provides integration with the ethers.js library.
// Ethers.js is a popular JavaScript library for interacting with Ethereum and Ethereum-like blockchains.
// This plugin allows you to deploy contracts, send transactions, and interact with contracts from your Hardhat scripts and tests using ethers.js.
require("@nomicfoundation/hardhat-ethers");

// Import and configure dotenv to load environment variables from a .env file.
// This is crucial for securely managing sensitive information like private keys and API keys.
// Make sure you have a .env file in your project root and have installed the dotenv package (npm install dotenv or yarn add dotenv).
require('dotenv').config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 * This is the main configuration file for your Hardhat project.
 * Hardhat is a development environment to compile, deploy, test, and debug your Ethereum software.
 * This file allows you to customize various aspects of Hardhat, such as the Solidity compiler version,
 * network configurations (for deployment and testing), and plugins.
 */
module.exports = {
  // Specifies the version of the Solidity compiler to be used by Hardhat.
  // It's important to use a version compatible with your smart contracts.
  // "0.8.28" means Hardhat will use version 0.8.28 of the Solidity compiler.
  solidity: "0.8.28",

  // The `networks` object is where you define the different blockchain networks Hardhat can connect to.
  // This includes local development networks (like Hardhat Network), testnets (like Sepolia, Goerli), and mainnets.
  networks: {
    // Configuration for the Arbitrum Sepolia testnet.
    // Arbitrum is a Layer 2 scaling solution for Ethereum.
    // Sepolia is a common Ethereum testnet.
    arbitrum_sepolia: {
      // `url`: The RPC (Remote Procedure Call) endpoint for the Arbitrum Sepolia network.
      // This URL is used by Hardhat to send requests (like deploying contracts or sending transactions) to the network.
      // You can often find public RPC URLs for various networks from providers like Alchemy, Infura, or the network's official documentation.
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      
      // `accounts`: An array of private keys for the accounts you want to use for deploying contracts or sending transactions on this network.
      // IMPORTANT: Never commit your actual private keys directly into your codebase, especially if the repository is public.
      // Instead, use environment variables (e.g., via a `.env` file and a library like `dotenv`) to store private keys securely.
      // The private key for the account used to deploy contracts on this network.
      // IMPORTANT: Never hardcode private keys in your configuration files, especially if your project is open source.
      // Instead, use environment variables to keep them secure.
      // 1. Create a `.env` file in the root of your project (e.g., `my-arbitrum-dapp/.env`).
      // 2. Add your private key to the `.env` file like this: `ARBITRUM_SEPOLIA_PRIVATE_KEY=0xyourActualPrivateKey`
      // 3. Make sure `.env` is listed in your `.gitignore` file to prevent it from being committed to version control.
      // 4. Install the `dotenv` package: `npm install dotenv` or `yarn add dotenv`
      // 5. Require and configure `dotenv` at the top of this `hardhat.config.js` file: `require('dotenv').config();`
      //
      // `process.env.ARBITRUM_SEPOLIA_PRIVATE_KEY` will then load the private key from your `.env` file.
      // If the private key is not set, an empty array `[]` is used as a fallback to prevent errors during local development if the key isn't needed.
      accounts: process.env.ARBITRUM_SEPOLIA_PRIVATE_KEY ? [process.env.ARBITRUM_SEPOLIA_PRIVATE_KEY] : []
    }
    // You can add more network configurations here, for example:
    // hardhat: { // This is the default Hardhat Network, a local Ethereum network designed for development.
    //   chainId: 31337 // Default chain ID for Hardhat Network
    // },
    // mainnet: { // Example for Ethereum Mainnet (use with extreme caution and secure private key management)
    //   url: "YOUR_MAINNET_RPC_URL",
    //   accounts: [process.env.MAINNET_PRIVATE_KEY]
    // }
  }
  // You can also configure other Hardhat settings here, such as:
  // paths: { // To customize project paths (contracts, artifacts, etc.)
  //   sources: "./contracts",
  //   tests: "./test",
  //   cache: "./cache",
  //   artifacts: "./artifacts"
  // },
  // etherscan: { // For verifying contracts on Etherscan or similar block explorers
  //   apiKey: process.env.ETHERSCAN_API_KEY
  // }
};