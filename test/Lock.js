// This file contains automated tests for the `Lock.sol` smart contract.
// Tests are written using Mocha (a JavaScript test framework) and Chai (an assertion library).
// Hardhat integrates these tools and provides `ethers.js` for interacting with contracts during tests.

// --- Import necessary helpers and assertion tools ---

// `time`: A Hardhat Network helper for manipulating blockchain time (e.g., advancing time).
// `loadFixture`: A Hardhat Network helper to run a setup function once and reuse its state for multiple tests.
// This speeds up tests by avoiding redundant deployments.
const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

// `anyValue`: A Chai Matcher from Hardhat to check if an event argument has any value (useful when the exact value is dynamic or unknown).
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

// `expect`: The core assertion function from the Chai library.
const { expect } = require("chai");

// `describe` is a Mocha function to group related tests. 
// The first argument is a description of the group (e.g., "Lock contract tests").
// The second argument is a callback function containing the tests or nested `describe` blocks.
describe("Lock Contract Tests", function () {
  // --- Fixture Definition ---
  // A fixture is an async function that sets up the initial state for tests.
  // This typically involves deploying the contract and setting up any necessary conditions.
  // `deployOneYearLockFixture` will deploy the Lock contract with a 1-year lock time and 1 Gwei.
  async function deployOneYearLockFixture() {
    // Define constants for time and currency to make the code more readable.
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60; // Seconds in a year
    const ONE_GWEI = 1_000_000_000; // 1 Gwei in Wei (smallest unit of Ether)

    // Set the amount to be locked in the contract.
    const lockedAmount = ONE_GWEI;

    // Calculate the `unlockTime`. It should be in the future.
    // `time.latest()` gets the timestamp of the latest mined block in Hardhat Network.
    // We add ONE_YEAR_IN_SECS to set the unlock time one year from the current latest block time.
    const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

    // Get signers (accounts) from Hardhat Network. 
    // `ethers.getSigners()` is a Hardhat/ethers.js helper that returns an array of account objects.
    // The first signer (`owner`) will deploy the contract by default and become its owner.
    // `otherAccount` can be used to test interactions from non-owner accounts.
    const [owner, otherAccount] = await ethers.getSigners(); // `ethers` is globally available in Hardhat tests

    // Get the contract factory for "Lock". A ContractFactory is an abstraction to deploy new smart contracts.
    const LockFactory = await ethers.getContractFactory("Lock");
    // Deploy the contract. Pass `unlockTime` as a constructor argument.
    // Send `lockedAmount` of Ether with the deployment transaction using the `value` option.
    // This Ether will be stored in the contract, as the constructor is `payable`.
    const lockContract = await LockFactory.deploy(unlockTime, { value: lockedAmount });

    // Return all necessary variables for the tests.
    // These can be accessed by tests that use this fixture via `await loadFixture(deployOneYearLockFixture)`.
    return { lockContract, unlockTime, lockedAmount, owner, otherAccount };
  }

  // --- Test Group: Deployment ---
  // This `describe` block groups tests related to the contract's deployment and initial state.
  describe("Deployment Verification", function () {
    // `it` defines an individual test case.
    // The first argument is a description of what the test should do.
    // The second argument is an async function containing the test logic.
    it("Should set the correct unlockTime upon deployment", async function () {
      // Load the fixture. This deploys the contract and returns the setup variables.
      const { lockContract, unlockTime } = await loadFixture(deployOneYearLockFixture);

      // Call the `unlockTime()` public getter function on the deployed contract.
      // `expect` is used to make an assertion.
      // `to.equal()` checks if the actual value (from `lockContract.unlockTime()`) equals the expected `unlockTime`.
      expect(await lockContract.unlockTime()).to.equal(unlockTime);
    });

    it("Should set the correct owner upon deployment", async function () {
      const { lockContract, owner } = await loadFixture(deployOneYearLockFixture);
      // Check if the contract's `owner()` matches the address of the `owner` account from the fixture.
      expect(await lockContract.owner()).to.equal(owner.address);
    });

    it("Should receive and store the correct amount of Ether upon deployment", async function () {
      const { lockContract, lockedAmount } = await loadFixture(
        deployOneYearLockFixture
      );
      // `ethers.provider.getBalance(address)` gets the Ether balance of an address.
      // `lockContract.target` is the address of the deployed contract.
      // Check if the contract's balance equals the `lockedAmount` sent during deployment.
      expect(await ethers.provider.getBalance(lockContract.target)).to.equal(
        lockedAmount
      );
    });

    it("Should REVERT if deployment unlockTime is not in the future", async function () {
      // This test checks a specific failure case, so we don't use the fixture which sets a valid future time.
      const latestBlockTimestamp = await time.latest(); // Get current block time
      const LockFactory = await ethers.getContractFactory("Lock");
      
      // Attempt to deploy the contract with an `unlockTime` that is not in the future (i.e., current time).
      // `expect(...).to.be.revertedWith("error message")` checks if the transaction reverts with a specific error message.
      // This is how you test `require` statements in your Solidity code.
      await expect(LockFactory.deploy(latestBlockTimestamp, { value: 1 })).to.be.revertedWith(
        "Unlock time should be in the future" // This message must match the one in Lock.sol's constructor
      );
    });
  });

  // --- Test Group: Withdrawals ---
  // This `describe` block groups tests related to the `withdraw` function.
  describe("Withdrawal Functionality", function () {
    // Nested `describe` for validation tests of the withdraw function.
    describe("Access Control and Timing Validations", function () {
      it("Should REVERT withdrawal if called before unlockTime", async function () {
        const { lockContract } = await loadFixture(deployOneYearLockFixture);
        // Attempt to call `withdraw()` immediately after deployment (before `unlockTime`).
        // Expect it to revert with the specified error message from the contract's `require` statement.
        await expect(lockContract.withdraw()).to.be.revertedWith("You can't withdraw yet");
      });

      it("Should REVERT withdrawal if called by an account other than the owner", async function () {
        const { lockContract, unlockTime, otherAccount } = await loadFixture(
          deployOneYearLockFixture
        );

        // Advance blockchain time to or past the `unlockTime` using the `time.increaseTo` helper.
        await time.increaseTo(unlockTime);

        // Attempt to call `withdraw()` from `otherAccount` (not the owner).
        // `lockContract.connect(signer)` returns a contract instance connected to a different signer.
        await expect(lockContract.connect(otherAccount).withdraw()).to.be.revertedWith("You aren't the owner");
      });

      it("Should NOT REVERT withdrawal if unlockTime has arrived and called by the owner", async function () {
        const { lockContract, unlockTime } = await loadFixture(
          deployOneYearLockFixture
        );

        // Advance time to `unlockTime`.
        await time.increaseTo(unlockTime);

        // Call `withdraw()` from the owner's account (default signer for `lockContract`).
        // `not.to.be.reverted` checks that the transaction does NOT revert.
        await expect(lockContract.withdraw()).not.to.be.reverted;
      });
    });

    // Nested `describe` for testing events emitted by the withdraw function.
    describe("Event Emission", function () {
      it("Should emit a 'Withdrawal' event on successful withdrawal", async function () {
        const { lockContract, unlockTime, lockedAmount } = await loadFixture(
          deployOneYearLockFixture
        );

        // Advance time to enable withdrawal.
        await time.increaseTo(unlockTime);

        // `to.emit(contract, "EventName")` checks if an event is emitted by the contract.
        // `.withArgs(arg1, arg2, ...)` checks if the event was emitted with specific arguments.
        // `anyValue` (from `@nomicfoundation/hardhat-chai-matchers/withArgs`) is used here because 
        // the second argument of the Withdrawal event (`when`) is `block.timestamp`, which is dynamic.
        // We care that the event is emitted with the correct `lockedAmount` and some timestamp.
        await expect(lockContract.withdraw())
          .to.emit(lockContract, "Withdrawal")
          .withArgs(lockedAmount, anyValue); // Check amount; `when` can be any value (block.timestamp)
      });
    });

    // Nested `describe` for testing Ether transfers during withdrawal.
    describe("Ether Transfer Verification", function () {
      it("Should transfer the locked funds to the owner upon successful withdrawal", async function () {
        const { lockContract, unlockTime, lockedAmount, owner } = await loadFixture(
          deployOneYearLockFixture
        );

        // Advance time to enable withdrawal.
        await time.increaseTo(unlockTime);

        // `changeEtherBalances` is a Chai matcher (provided by `hardhat-chai-matchers` via `hardhat-toolbox`).
        // It checks how the Ether balances of specified accounts change after a transaction.
        // `[owner, lockContract]` is an array of accounts/contracts whose balances we're checking.
        // `[lockedAmount, -lockedAmount]` is an array of expected balance changes:
        //   - Owner's balance should increase by `lockedAmount`.
        //   - Contract's (`lockContract`) balance should decrease by `lockedAmount` (i.e., change by `-lockedAmount`).
        await expect(lockContract.withdraw()).to.changeEtherBalances(
          [owner, lockContract], // Accounts/contracts to check balances of
          [lockedAmount, -lockedAmount] // Expected changes in balance for each account/contract
        );
      });
    });
  });
});

// To run these tests, use the command from your project root:
// npx hardhat test
// 
// To run only this specific test file:
// npx hardhat test ./test/Lock.js
//
// For more information on testing with Hardhat, see:
// https://hardhat.org/hardhat-runner/docs/guides/test-contracts
