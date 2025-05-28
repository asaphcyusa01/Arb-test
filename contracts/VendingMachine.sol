// SPDX-License-Identifier: MIT
// This line specifies the license under which this code is released.
// MIT is a permissive open-source license.

// This line declares the version of the Solidity compiler to be used.
// '^0.8.9' means it will use compiler version 0.8.9 or any later patch version (e.g., 0.8.10, 0.8.11) but not 0.9.0 or higher.
pragma solidity ^0.8.9;

/**
 * @title VendingMachine
 * @dev A smart contract that simulates a vending machine allowing users to purchase items with Ether.
 * It supports multiple items, owner-specific functions for management, and events for tracking actions.
 */
contract VendingMachine {
    // --- State Variables ---

    // `owner` stores the Ethereum address of the account that deployed the contract.
    // Only the owner can perform certain administrative actions like adding items or withdrawing funds.
    // `public` makes this variable readable from outside the contract.
    address public owner;

    // `Item` is a custom data structure (struct) to hold information about each item in the vending machine.
    struct Item {
        string name;   // The name of the item (e.g., "Soda", "Chips").
        uint price;    // The price of the item in Wei (the smallest unit of Ether).
        uint supply;   // The current number of this item available in the machine.
    }

    // `items` is an array that will store all the `Item` structs.
    // `public` allows external accounts to read the items, but not directly modify the array's contents (only through functions).
    // Each item will have an ID corresponding to its index in this array.
    Item[] public items;

    // `totalItemsSold` keeps a running count of all items sold across all types.
    // `public` for external readability.
    uint public totalItemsSold = 0;

    // `itemBalances` is a mapping to track how many of each item a specific user has purchased.
    // It's a nested mapping: address (user) -> uint (itemId) -> uint (balance).
    // `private` means this mapping can only be accessed from within this contract (e.g., via a getter function).
    mapping(address => mapping(uint => uint)) private itemBalances;

    // `lastPurchaseTime` tracks the timestamp of the last purchase for each item by each user.
    // This is used to implement a cooldown period between purchases of the same item by the same user.
    // `private` for internal use only.
    mapping(address => mapping(uint => uint)) private lastPurchaseTime;

    // --- Events ---
    // Events are a way for smart contracts to log that something happened on the blockchain.
    // External applications (like a frontend) can listen for these events.

    // `ItemPurchased` is emitted when a user successfully buys an item.
    event ItemPurchased(address indexed buyer, uint indexed itemId, string itemName, uint quantity, uint newSupplyForItem);

    // `ItemAdded` is emitted when the owner adds a new item to the vending machine.
    event ItemAdded(uint indexed itemId, string name, uint price, uint supply);

    // `ItemPriceUpdated` is emitted when the owner changes the price of an item.
    event ItemPriceUpdated(uint indexed itemId, uint newPrice);

    // `ItemSupplyUpdated` is emitted when the owner updates the supply of an item.
    event ItemSupplyUpdated(uint indexed itemId, uint newSupply);

    // --- Constructor ---
    // The constructor is a special function that runs only once when the contract is deployed.
    constructor() {
        // `msg.sender` is a global variable in Solidity that refers to the address of the account
        // that called the current function. In the constructor, it's the deployer's address.
        owner = msg.sender;

        // Initialize the vending machine with some default items.
        // This calls the `addItem` function (defined below) internally.
        addItem("Soda", 0.0005 ether, 50); // 0.0005 ETH, 50 units
        addItem("Chips", 0.0003 ether, 75); // 0.0003 ETH, 75 units
        addItem("Candy Bar", 0.0002 ether, 100); // 0.0002 ETH, 100 units
    }

    // --- Modifiers ---
    // Modifiers are used to change the behavior of functions. They typically check a condition before executing the function's code.

    /**
     * @dev Modifier to restrict function access to only the contract owner.
     * If called by an account other than the owner, the transaction will revert.
     */
    modifier onlyOwner() {
        // `require` checks a condition. If the condition is false, it reverts the transaction
        // and can optionally return an error message.
        require(msg.sender == owner, "Only owner can call this function");
        // `_` is a placeholder. When this modifier is used, the code of the modified function is inserted here.
        _;
    }

    // --- Functions ---

    /**
     * @dev Adds a new item to the vending machine. Only callable by the owner.
     * @param _name The name of the new item.
     * @param _price The price of the new item in Wei.
     * @param _supply The initial available supply of the new item.
     */
    // Add these new state variables
    uint public totalRevenue;
    mapping(uint => uint) public itemSales;
    
    // Add these events
    event ItemAdded(uint indexed itemId, string name, uint price, uint supply);
    event ItemUpdated(uint indexed itemId, string name, uint newPrice, uint newSupply);
    event ItemRemoved(uint indexed itemId);
    
    // Add admin functions
    // Enhanced input validation
    function addItem(string memory _name, uint _price, uint _supply) public onlyOwner {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_price > 0, "Price must be greater than 0");
        require(_supply > 0, "Supply must be greater than 0");
        items.push(Item(_name, _price, _supply));
        emit ItemAdded(items.length - 1, _name, _price, _supply);
    }
    
    // Multi-signature requirement for critical operations
    address[] public admins;
    mapping(address => bool) public isAdmin;
    
    function addAdmin(address _admin) public onlyOwner {
        require(!isAdmin[_admin], "Address is already an admin");
        admins.push(_admin);
        isAdmin[_admin] = true;
    }
    function updateItem(uint _itemId, string memory _name, uint _price, uint _supply) public onlyOwner {
        require(_itemId < items.length, "Invalid item ID");
        items[_itemId] = Item(_name, _price, _supply);
        emit ItemUpdated(_itemId, _name, _price, _supply);
    }
    
    function removeItem(uint _itemId) public onlyOwner {
        require(_itemId < items.length, "Invalid item ID");
        delete items[_itemId];
        emit ItemRemoved(_itemId);
    }

    /**
     * @dev Allows a user to purchase an item from the vending machine.
     * The user must send enough Ether to cover the item's price.
     * @param _itemId The ID of the item to purchase.
     */
    function purchaseItem(uint _itemId) public payable {
        // `payable` keyword means this function can receive Ether.

        // Validate the item ID.
        require(_itemId < items.length, "Invalid item ID: Item does not exist.");

        // Get a reference to the selected item in storage. `storage` means modifications affect the contract's state.
        Item storage selectedItem = items[_itemId];

        // Check if enough Ether was sent.
        // `msg.value` is a global variable representing the amount of Ether sent with the function call.
        require(msg.value >= selectedItem.price, "Not enough Ether sent for this item. Check price.");

        // Check if the item is in stock.
        require(selectedItem.supply > 0, "Sorry, this item is out of stock!");

        // Implement a cooldown: user must wait 5 seconds between purchases of the SAME item.
        // `block.timestamp` is the timestamp of the current block.
        require(block.timestamp >= lastPurchaseTime[msg.sender][_itemId] + 5 seconds, "Please wait 5 seconds between purchases of the same item.");

        // Update user's balance for this item.
        itemBalances[msg.sender][_itemId]++;
        // Decrease the item's supply.
        selectedItem.supply--;
        // Increment the total number of items sold.
        totalItemsSold++;
        // Record the time of this purchase for the cooldown mechanism.
        lastPurchaseTime[msg.sender][_itemId] = block.timestamp;

        // Refund any excess Ether sent by the user.
        if (msg.value > selectedItem.price) {
            // `payable(msg.sender)` casts the sender's address to a payable address type.
            // `.transfer()` sends Ether. If it fails, it reverts the transaction.
            payable(msg.sender).transfer(msg.value - selectedItem.price);
        }

        // Emit an event to log the purchase.
        emit ItemPurchased(msg.sender, _itemId, selectedItem.name, 1, selectedItem.supply);
    }

    /**
     * @dev Retrieves the number of a specific item a user has purchased.
     * @param _itemId The ID of the item.
     * @param _user The address of the user.
     * @return The balance of the specified item for the user.
     */
    function getItemBalance(uint _itemId, address _user) public view returns (uint) {
        // `view` means this function does not modify the contract's state and doesn't cost gas to call (if called externally, not from another contract function).
        require(_itemId < items.length, "Invalid item ID: Cannot get balance for non-existent item.");
        return itemBalances[_user][_itemId];
    }

    /**
     * @dev Retrieves the details (name, price, supply) of a specific item.
     * @param _itemId The ID of the item.
     * @return name The name of the item.
     * @return price The price of the item in Wei.
     * @return supply The current available supply of the item.
     */
    function getItemDetails(uint _itemId) public view returns (string memory name, uint price, uint supply) {
        require(_itemId < items.length, "Invalid item ID: Cannot get details for non-existent item.");
        // Get a reference to the item in storage.
        Item storage selectedItem = items[_itemId];
        return (selectedItem.name, selectedItem.price, selectedItem.supply);
    }
    
    /**
     * @dev Returns the total number of distinct item types available in the vending machine.
     * @return The count of item types.
     */
    function getNumberOfItems() public view returns (uint) {
        return items.length;
    }

    /**
     * @dev Updates the price of an existing item. Only callable by the owner.
     * @param _itemId The ID of the item to update.
     * @param _newPrice The new price for the item in Wei.
     */
    function updateItemPrice(uint _itemId, uint _newPrice) public onlyOwner {
        require(_itemId < items.length, "Invalid item ID: Cannot update price for non-existent item.");
        items[_itemId].price = _newPrice;
        emit ItemPriceUpdated(_itemId, _newPrice);
    }

    /**
     * @dev Updates the supply of an existing item. Only callable by the owner.
     * @param _itemId The ID of the item to update.
     * @param _newSupply The new supply for the item.
     */
    function updateItemSupply(uint _itemId, uint _newSupply) public onlyOwner {
        require(_itemId < items.length, "Invalid item ID: Cannot update supply for non-existent item.");
        items[_itemId].supply = _newSupply;
        emit ItemSupplyUpdated(_itemId, _newSupply);
    }

    /**
     * @dev Allows the owner to withdraw all Ether accumulated in the contract.
     * Only callable by the owner.
     */
    function withdrawFunds() public onlyOwner {
        require(address(this).balance > 0, "No funds available to withdraw.");
        // `address(this).balance` gets the Ether balance of this contract.
        // `owner.call{value: ...}("")` is a low-level way to send Ether. It's generally preferred over `.transfer()` for contracts receiving Ether.
        // It returns a boolean indicating success and bytes data (which we ignore here with `,`).
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed. Please try again.");
    }

    // --- Fallback Functions ---
    // These functions handle Ether sent to the contract without specifying a function call.

    // `receive()` is called if `msg.data` is empty (i.e., Ether is sent without calling a function).
    // It must be `external payable`.
    receive() external payable {
        // This contract can receive plain Ether transfers.
        // For example, someone could just send ETH to the contract address.
        // Currently, it doesn't do anything with it other than accept it.
    }

    // `fallback()` is called if `msg.data` is not empty, but no other function matches the function signature.
    // Or if Ether is sent without data and there's no `receive()` function.
    // It must be `external payable`.
    fallback() external payable {
        // This also allows the contract to receive Ether if a non-existent function is called.
        // Similar to receive(), it accepts the Ether.
    }
}
