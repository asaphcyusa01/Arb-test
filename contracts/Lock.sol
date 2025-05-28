// SPDX-License-Identifier: UNLICENSED
// This line specifies the license for the contract. UNLICENSED means it's not open source by default.
// For educational projects, you might consider a permissive license like MIT.

// This line declares the version of the Solidity compiler to be used.
// `^0.8.28` means it will use compiler version 0.8.28 or any later patch version (e.g., 0.8.29) but not 0.9.0 or higher.
pragma solidity ^0.8.28;

// Hardhat's console.log functionality can be very useful for debugging your contracts during development.
// To use it, you would uncomment the line below.
// import "hardhat/console.sol";

/**
 * @title Lock
 * @dev This contract demonstrates a basic time-locked wallet.
 * Ether sent to this contract can only be withdrawn by the owner after a specified unlock time has passed.
 * This is a common example provided by Hardhat to illustrate basic contract functionality.
 */
contract Lock {
    // --- State Variables ---
    // State variables are stored permanently on the blockchain.

    // `unlockTime`: A timestamp (seconds since Unix epoch) representing when the funds can be withdrawn.
    // `public` makes this variable readable from outside the contract (e.g., from a DApp or another contract).
    uint public unlockTime;

    // `owner`: The Ethereum address of the account that deployed the contract and is allowed to withdraw funds.
    // `payable` means this address can receive Ether.
    // `public` makes it readable from outside.
    address payable public owner;

    // --- Events ---
    // Events are a way for contracts to log information on the blockchain that external applications (like DApps) can listen to.

    /**
     * @dev Emitted when funds are successfully withdrawn from the contract.
     * @param amount The amount of Ether (in Wei) that was withdrawn.
     * @param when The timestamp (block.timestamp) when the withdrawal occurred.
     */
    event Withdrawal(uint amount, uint when);

    // --- Constructor ---
    // The constructor is a special function that is executed only once when the contract is deployed.
    // It's used to initialize the contract's state.

    /**
     * @dev Sets the unlock time and the owner of the contract.
     * @param _unlockTime The timestamp (in seconds since Unix epoch) when the funds should become withdrawable.
     * The `payable` keyword here means that the constructor can receive Ether when the contract is deployed.
     * Any Ether sent during deployment will be stored in the contract's balance.
     */
    constructor(uint _unlockTime) payable {
        // `require` is used for input validation. If the condition is false, the transaction reverts (fails).
        // This check ensures that the `_unlockTime` is in the future relative to the deployment time (`block.timestamp`).
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future" // Error message if the condition is false.
        );

        // Set the `unlockTime` state variable to the value provided during deployment.
        unlockTime = _unlockTime;
        // Set the `owner` state variable to the address that deployed the contract (`msg.sender`).
        // `msg.sender` is a global variable in Solidity that always refers to the address that called the current function.
        // `payable(msg.sender)` converts the address to a payable address type.
        owner = payable(msg.sender);
    }

    // --- Functions ---

    /**
     * @dev Allows the owner to withdraw the entire balance of the contract after the `unlockTime` has passed.
     * This function is `public`, meaning it can be called externally (e.g., by the owner through a DApp).
     */
    function withdraw() public {
        // For debugging: You can print values to the Hardhat console during testing.
        // To use this, you also need to uncomment the `import "hardhat/console.sol";` line at the top.
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        // First `require` check: Ensure the current time (`block.timestamp`) is greater than or equal to the `unlockTime`.
        // If not, the funds are still locked, and the transaction will revert.
        require(block.timestamp >= unlockTime, "You can't withdraw yet");

        // Second `require` check: Ensure that the address calling this function (`msg.sender`) is the `owner`.
        // This prevents anyone other than the owner from withdrawing the funds.
        require(msg.sender == owner, "You aren't the owner");

        // Emit the `Withdrawal` event to log this action on the blockchain.
        // `address(this).balance` refers to the total Ether balance currently held by this contract.
        emit Withdrawal(address(this).balance, block.timestamp);

        // Transfer the entire balance of the contract to the `owner`.
        // `owner.transfer()` is a built-in function to send Ether. If the transfer fails, it will revert the transaction.
        // It's generally recommended to use `call` with re-entrancy guards for more complex interactions,
        // but `transfer` is fine for simple cases like this.
        owner.transfer(address(this).balance);
    }

    // --- Fallback/Receive Functions (Optional but good practice to understand) ---
    // Although not strictly necessary for this simple Lock contract, it's good to know about these.

    // A `receive` function is executed if Ether is sent to the contract without any data (e.g., a simple transfer).
    // It must be marked `external payable`.
    // receive() external payable {
    //     // You could, for example, emit an event here if you want to track direct Ether deposits.
    //     // emit EtherReceived(msg.sender, msg.value);
    // }

    // A `fallback` function is executed if the contract is called with a function signature that doesn't match any existing functions,
    // or if Ether is sent without data and no `receive` function exists.
    // It can be `payable` if you want it to accept Ether.
    // fallback() external payable {
    //     // Handle unexpected calls or Ether transfers.
    //     // emit EtherReceived(msg.sender, msg.value); // Example
    // }
}
