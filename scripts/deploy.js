async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const VendingMachine = await ethers.getContractFactory("VendingMachine");
    const vendingMachine = await VendingMachine.deploy();
  
    // Wait for deployment to complete
    await vendingMachine.waitForDeployment();
  
    console.log("VendingMachine deployed to:", vendingMachine.target); // Use .target instead of .address
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  