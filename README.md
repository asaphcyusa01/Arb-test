# Arbitrum Vending Machine DApp

Welcome to the Arbitrum Vending Machine DApp! This project is an educational example designed to help beginners understand how to build, deploy, and interact with a simple decentralized application on the Arbitrum network (specifically targeting the Arbitrum Sepolia testnet).

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup and Installation](#setup-and-installation)
- [Key Configuration Steps](#key-configuration-steps)
- [Available Scripts](#available-scripts)
  - [Hardhat Tasks](#hardhat-tasks)
  - [Frontend Scripts](#frontend-scripts)
- [Smart Contract: VendingMachine.sol](#smart-contract-vendingmachinesol)
- [Frontend Application](#frontend-application)
- [Deployment to Arbitrum Sepolia](#deployment-to-arbitrum-sepolia)
- [Contributing](#contributing)
- [License](#license)

## Project Overview

This DApp simulates a vending machine where users can view available items and purchase them using test Ether on the Arbitrum Sepolia network. The project includes a Solidity smart contract for the vending machine logic and a React frontend for user interaction.

## Features

- **Smart Contract (`VendingMachine.sol`)**:
  - Manages a list of items with names, prices, and available quantities.
  - Allows the owner to add new items and update existing ones.
  - Enables users to purchase items.
  - Allows the owner to withdraw funds.
- **React Frontend**:
  - Displays available items from the smart contract.
  - Allows users to connect their Web3 wallet (e.g., MetaMask).
  - Facilitates the purchase of items by interacting with the smart contract.
- **Hardhat Development Environment**:
  - Scripts for compiling and deploying the smart contract.
  - Tests for the smart contracts (example for `Lock.sol` provided, can be extended for `VendingMachine.sol`).
  - Hardhat Ignition module example for deploying `Lock.sol`.

## Tech Stack

- **Smart Contracts**: Solidity
- **Development Environment**: Hardhat
- **Ethereum Interaction**: Ethers.js
- **Frontend**: React (Create React App)
- **Target Network**: Arbitrum Sepolia (Testnet)
- **Package Management**: npm or yarn

## Project Structure

```
my-arbitrum-dapp/
├── .env.example            # Example environment variables for Hardhat (root)
├── .gitignore
├── README.md               # This file
├── contracts/              # Solidity smart contracts
│   ├── Lock.sol            # Example Lock contract (from Hardhat template)
│   └── VendingMachine.sol  # Core Vending Machine contract
├── frontend/               # React frontend application
│   ├── .env.example        # Example environment variables for React app
│   ├── package.json
│   ├── public/
│   └── src/                # Frontend source code
│       ├── App.js          # Main React component
│       └── VendingMachineABI.json # ABI for the Vending Machine contract (needs to be placed here or hosted)
├── hardhat.config.js       # Hardhat configuration file
├── ignition/               # Hardhat Ignition deployment modules
│   └── modules/
│       └── Lock.js         # Example deployment module for Lock.sol
├── package.json            # Root project dependencies (Hardhat, etc.)
├── scripts/                # Deployment scripts
│   └── deploy.js           # Script to deploy VendingMachine.sol
└── test/                   # Smart contract tests
    └── Lock.js             # Example tests for Lock.sol
```

## Prerequisites

- **Node.js**: Version 16.x or higher (LTS recommended). You can download it from [nodejs.org](https://nodejs.org/).
- **npm** (comes with Node.js) or **yarn**.
- **MetaMask**: A browser extension wallet to interact with the DApp. Configure it for Arbitrum Sepolia.
  - Network Name: Arbitrum Sepolia
  - RPC URL: `https://sepolia-rollup.arbitrum.io/rpc`
  - Chain ID: `421614`
  - Currency Symbol: `ETH`
- **Test Ether**: Obtain Arbitrum Sepolia ETH from a faucet (e.g., [Arbitrum Faucet](https://faucet.quicknode.com/arbitrum/sepolia), [Alchemy Arbitrum Sepolia Faucet](https://sepoliafaucet.com/)).

## Setup and Installation

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd my-arbitrum-dapp
    ```

2.  **Install root dependencies** (Hardhat, Ethers.js, etc.):
    ```bash
    npm install
    # or
    yarn install
    ```

3.  **Install frontend dependencies**:
    ```bash
    cd frontend
    npm install
    # or
    yarn install
    cd .. 
    ```

## Key Configuration Steps

Before running the project, you need to set up environment variables.

1.  **Configure Backend/Deployment Environment (`.env` in project root)**:
    -   Copy `.env.example` to a new file named `.env` in the project root (`my-arbitrum-dapp/.env`).
        ```bash
        cp .env.example .env
        ```
    -   Edit `.env` and add your private key for deploying to Arbitrum Sepolia:
        ```env
        ARBITRUM_SEPOLIA_PRIVATE_KEY=0xyourActualPrivateKey
        ```
    -   **IMPORTANT**: Ensure your `.env` file (containing the private key) is listed in `.gitignore` to prevent it from being committed to version control.
    -   You may also need to install `dotenv` if not already a dependency: `npm install dotenv` or `yarn add dotenv` (it's included in `hardhat.config.js`).

2.  **Configure Frontend Environment (`.env` in `frontend` directory)**:
    -   Navigate to the `frontend` directory: `cd frontend`
    -   Copy `frontend/.env.example` to a new file named `.env` in the `frontend` directory (`my-arbitrum-dapp/frontend/.env`).
        ```bash
        cp .env.example .env
        ```
    -   You will update this file after deploying the smart contract:
        -   `REACT_APP_CONTRACT_ADDRESS`: The address of your deployed `VendingMachine` contract.
        -   `REACT_APP_ABI_URL`: The URL to the `VendingMachine.json` ABI file. You can obtain the ABI file from `artifacts/contracts/VendingMachine.sol/VendingMachine.json` after compiling the contract. You can then:
            -   Copy it to `frontend/public/VendingMachineABI.json` and set `REACT_APP_ABI_URL=/VendingMachineABI.json`.
            -   Or host it (e.g., on GitHub Gist) and provide the raw URL.
    -   Return to the project root: `cd ..`

## Available Scripts

### Hardhat Tasks

(Run these from the project root directory `my-arbitrum-dapp/`)

-   **Compile Contracts**:
    ```bash
    npx hardhat compile
    ```
    This compiles your Solidity smart contracts and generates ABI files in the `artifacts/` directory.

-   **Run Tests** (Example for `Lock.sol`):
    ```bash
    npx hardhat test
    ```
    You can write tests for `VendingMachine.sol` in the `test/` directory following a similar pattern.

-   **Deploy `VendingMachine.sol` to Arbitrum Sepolia**:
    ```bash
    npx hardhat run scripts/deploy.js --network arbitrum_sepolia
    ```
    After successful deployment, note the contract address. You'll need it for the frontend configuration (`REACT_APP_CONTRACT_ADDRESS` in `frontend/.env`).

-   **Deploy `Lock.sol` using Hardhat Ignition (Example)**:
    ```bash
    npx hardhat ignition deploy ./ignition/modules/Lock.js --network arbitrum_sepolia
    ```

-   **Start a Local Hardhat Node** (for local testing without deploying to a testnet):
    ```bash
    npx hardhat node
    ```
    You can then deploy to this local node using `--network localhost`.

-   **Hardhat Help**:
    ```bash
    npx hardhat help
    ```

### Frontend Scripts

(Run these from the `frontend/` directory: `cd frontend`)

-   **Start the React Development Server**:
    ```bash
    npm start
    # or
    yarn start
    ```
    This will open the DApp frontend in your browser, usually at `http://localhost:3000`.

-   **Build the Frontend for Production**:
    ```bash
    npm run build
    # or
    yarn build
    ```

-   **Run Frontend Tests**:
    ```bash
    npm test
    # or
    yarn test
    ```

## Smart Contract: VendingMachine.sol

The `VendingMachine.sol` contract (located in `contracts/`) is the heart of the DApp. It includes:

-   **State Variables**: To store item details, balances, and owner information.
-   **Structs**: For defining item properties (name, price, quantity).
-   **Mappings**: To efficiently look up item data.
-   **Events**: To log important actions like item purchases.
-   **Functions**:
    -   `addItem()`: Allows the contract owner to add new items or update existing ones.
    -   `purchaseItem()`: Allows users to buy an item if they send the correct amount of Ether and the item is in stock.
    -   `getItemDetails()`: A view function to get details of a specific item.
    -   `withdrawFunds()`: Allows the owner to withdraw the Ether collected by the vending machine.
-   **Modifiers**: Such as `onlyOwner` to restrict access to certain functions.

Detailed comments within the `VendingMachine.sol` file explain each part of the contract.

## Frontend Application

The frontend is a React application built using Create React App, located in the `frontend/` directory.

-   **`App.js`**: The main component that handles:
    -   Connecting to the user's Ethereum wallet (e.g., MetaMask).
    -   Fetching item data from the deployed `VendingMachine` smart contract.
    -   Displaying items and allowing users to interact with them.
    -   Initiating purchase transactions.
-   **Environment Variables (`frontend/.env`)**:
    -   `REACT_APP_CONTRACT_ADDRESS`: The address of the deployed `VendingMachine` contract.
    -   `REACT_APP_ABI_URL`: URL to the contract's ABI JSON file.
-   **User Interface**: Provides a simple UI to view items and make purchases. Includes a "Developer Note for Open Source Users" to guide on configuration.

## Deployment to Arbitrum Sepolia

1.  **Ensure Prerequisites**: You have Node.js, npm/yarn, MetaMask, and Arbitrum Sepolia ETH.
2.  **Configure `hardhat.config.js`**: Verify that the `arbitrum_sepolia` network configuration is correct, especially the RPC URL. Your private key should be securely loaded from the root `.env` file.
3.  **Compile Contracts**:
    ```bash
    npx hardhat compile
    ```
4.  **Run Deployment Script**:
    ```bash
    npx hardhat run scripts/deploy.js --network arbitrum_sepolia
    ```
5.  **Update Frontend Configuration**:
    -   Copy the deployed contract address from the script's output.
    -   Update `REACT_APP_CONTRACT_ADDRESS` in `my-arbitrum-dapp/frontend/.env`.
    -   Ensure `VendingMachine.json` (ABI) is accessible (e.g., in `frontend/public/`) and `REACT_APP_ABI_URL` in `my-arbitrum-dapp/frontend/.env` points to it.
6.  **Start Frontend**:
    ```bash
    cd frontend
    npm start
    ```
    You should now be able to interact with your deployed DApp on the Arbitrum Sepolia testnet.

## Contributing

This project is for educational purposes. Contributions, suggestions, and bug reports are welcome! Please feel free to open an issue or submit a pull request.

When contributing, please ensure your code follows the existing style and includes comments where necessary, especially for educational clarity.

## License

This project is licensed under the MIT License. See the `LICENSE` file (if one exists, otherwise assume MIT) for details.
