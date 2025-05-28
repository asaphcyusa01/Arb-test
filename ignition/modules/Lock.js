// This file demonstrates how to deploy the `Lock` smart contract using Hardhat Ignition.
// Hardhat Ignition is a declarative system for deploying smart contracts on Ethereum and EVM-compatible chains.
// It helps manage complex deployments, making them more reliable and easier to understand.
// Official Documentation: https://hardhat.org/ignition

// Import the `buildModule` function from Hardhat Ignition.
// This function is the entry point for defining a deployment module.
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

// --- Deployment Parameters ---
// These are default values for the parameters required by the Lock contract's constructor.

// `JAN_1ST_2030`: A constant representing a future timestamp (January 1st, 2030, in seconds since Unix epoch).
// This will be the default `unlockTime` for the Lock contract if not overridden during deployment.
const JAN_1ST_2030 = 1893456000; // Unix timestamp for Jan 1, 2030, 00:00:00 GMT

// `ONE_GWEI`: A constant representing 1 Gwei (1,000,000,000 Wei).
// Gwei is a denomination of Ether (1 Ether = 10^9 Gwei = 10^18 Wei).
// This will be the default amount of Ether locked in the contract if not overridden.
// The `n` at the end signifies a BigInt literal, which is necessary for handling large numbers in JavaScript.
const ONE_GWEI = 1_000_000_000n;

// --- Ignition Module Definition ---
// An Ignition module defines a set of deployment operations.
// `buildModule` takes two arguments:
//   1. A unique name for the module (e.g., "LockModule").
//   2. A callback function that receives a `ModuleBuilder` object (here named `m`).
module.exports = buildModule("LockModule", (m) => {
  // --- Module Parameters ---
  // `m.getParameter()` allows you to define parameters that can be passed to the module during deployment.
  // This makes your deployment scripts more flexible.

  // `unlockTime`: Defines a parameter for the contract's unlock time.
  // If a value for `unlockTime` is provided when running the deployment, that value will be used.
  // Otherwise, it defaults to `JAN_1ST_2030`.
  const unlockTime = m.getParameter("unlockTime", JAN_1ST_2030);

  // `lockedAmount`: Defines a parameter for the amount of Ether to be locked in the contract.
  // Defaults to `ONE_GWEI` if not specified during deployment.
  const lockedAmount = m.getParameter("lockedAmount", ONE_GWEI);

  // --- Contract Deployment ---
  // `m.contract()` is used to define a contract deployment operation.
  // It takes the contract name ("Lock") as the first argument.
  // The second argument is an array of constructor arguments for the `Lock` contract (in this case, just `unlockTime`).
  // The third argument is an options object. Here, `value: lockedAmount` specifies that `lockedAmount` of Ether
  // should be sent with the deployment transaction, which will be received by the `Lock` contract's payable constructor.
  const lock = m.contract("Lock", [unlockTime], {
    value: lockedAmount, // This Ether is sent to the Lock contract's constructor
  });

  // --- Module Return Value ---
  // The module should return an object containing the deployed contract instances.
  // This allows other modules or scripts to reference the deployed `lock` contract.
  // For example, `return { lockContract: lock };` would make it accessible as `lockContract`.
  return { lock }; // The key `lock` will be how this deployed contract is referenced.
});

// To run this Ignition deployment, you would typically use a command like:
// npx hardhat ignition deploy ./ignition/modules/Lock.js --network <your_network_name>
// For example, to deploy to a local Hardhat network:
// npx hardhat ignition deploy ./ignition/modules/Lock.js --network hardhat
// To deploy to Arbitrum Sepolia (assuming it's configured in hardhat.config.js):
// npx hardhat ignition deploy ./ignition/modules/Lock.js --network arbitrum_sepolia --parameters '{"unlockTime": 1924992000, "lockedAmount": "2000000000"}'
// (Note: `lockedAmount` in parameters should be a string representing Wei for command line usage)
