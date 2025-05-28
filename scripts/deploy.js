// This script deploys the `VendingMachine` smart contract to the blockchain.
// It uses Hardhat and ethers.js for deployment.

// The `main` function is an asynchronous function where the deployment logic resides.
// Using an async function allows us to use `await` for promises, making the code cleaner.
async function main() {
    // --- Step 1: Get the Deployer Account ---
    // `ethers.getSigners()` returns an array of Hardhat Network accounts (or accounts configured for other networks).
    // The first account (`deployer`) is typically used to deploy contracts.
    // `await` pauses execution until the promise from `ethers.getSigners()` resolves.
    const [deployer] = await ethers.getSigners(); // `ethers` is globally available in Hardhat scripts
  
    // Log the address of the account that will be used for deployment.
    // This is helpful for verifying that the correct account is being used.
    console.log("Deploying VendingMachine contract with the account:", deployer.address);
  
    // --- Step 2: Get the Contract Factory ---
    // `ethers.getContractFactory("VendingMachine")` returns a factory object for our `VendingMachine` contract.
    // A ContractFactory in ethers.js is an abstraction used to deploy new smart contracts.
    // `await` pauses execution until the factory is ready.
    console.log("Fetching VendingMachine contract factory...");
    const VendingMachineFactory = await ethers.getContractFactory("VendingMachine");
    
    // --- Step 3: Deploy the Contract ---
    // `VendingMachineFactory.deploy()` creates a deployment transaction and sends it to the network.
    // If your contract's constructor takes arguments, you would pass them here (e.g., `VendingMachineFactory.deploy(arg1, arg2)`).
    // Our VendingMachine constructor does not take arguments.
    // `await` pauses execution until the deployment transaction is sent and a contract object representing the future deployment is returned.
    console.log("Deploying VendingMachine...");
    const vendingMachine = await VendingMachineFactory.deploy();
  
    // --- Step 4: Wait for Deployment to Complete ---
    // `vendingMachine.waitForDeployment()` waits for the deployment transaction to be mined and confirmed on the blockchain.
    // This ensures that the contract is fully deployed before we proceed.
    // It's important to wait for the deployment to avoid issues where you try to interact with a contract that isn't yet on-chain.
    console.log("Waiting for VendingMachine deployment to complete...");
    await vendingMachine.waitForDeployment();
  
    // --- Step 5: Log the Deployed Contract Address ---
    // `vendingMachine.target` (or `vendingMachine.address` in older ethers versions) gives the address where the contract was deployed.
    // This address is crucial for interacting with the contract later (e.g., from a frontend application or other scripts).
    console.log("VendingMachine deployed successfully to address:", vendingMachine.target);

    // --- Optional: Further setup (e.g., adding initial items) ---
    // After deployment, you might want to call functions on your contract to set its initial state.
    // For example, if VendingMachine had an `addItem` function callable by the owner:
    // console.log("Adding initial items to VendingMachine...");
    // const tx1 = await vendingMachine.connect(deployer).addItem("Soda", ethers.parseEther("0.01"), 100);
    // await tx1.wait(); // Wait for the transaction to be mined
    // console.log("Added Soda to VendingMachine.");
    // const tx2 = await vendingMachine.connect(deployer).addItem("Chips", ethers.parseEther("0.005"), 200);
    // await tx2.wait();
    // console.log("Added Chips to VendingMachine.");
  }
  
  // --- Script Execution Pattern ---
  // This pattern is commonly used for Hardhat scripts.
  // It calls the `main` function and handles its success or failure.
  main()
    .then(() => process.exit(0)) // If `main` completes successfully, exit the script with status code 0 (success).
    .catch((error) => {
      // If `main` throws an error, catch it here.
      console.error("Error deploying VendingMachine contract:", error);
      process.exitCode = 1; // Set the exit code to 1 (failure) to indicate that the script encountered an error.
    });

// To run this script, use the command:
// npx hardhat run scripts/deploy.js --network <your_network_name>
// For example, to deploy to a local Hardhat network:
// npx hardhat run scripts/deploy.js --network hardhat
// To deploy to Arbitrum Sepolia (assuming it's configured in hardhat.config.js):
// npx hardhat run scripts/deploy.js --network arbitrum_sepolia
  