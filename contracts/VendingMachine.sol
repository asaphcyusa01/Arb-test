// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VendingMachineV2
 * @dev Production-ready vending machine with enhanced security, gas optimization, and real-world features
 * @author Q100
 * @notice This contract implements a decentralized vending machine with comprehensive features
 */
contract VendingMachineV2 is
    ReentrancyGuard,
    Pausable,
    AccessControl,
    Initializable,
    UUPSUpgradeable
{
    // --- Constants ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    
    uint256 public constant MAX_ITEMS = 1000;
    uint256 public constant MAX_QUANTITY_PER_PURCHASE = 100;
    uint256 public constant MIN_PRICE = 0.0001 ether;
    uint256 public constant MAX_PRICE = 10 ether;
    uint256 public constant MAX_DISCOUNT = 50; // 50%
    uint256 public constant LOYALTY_THRESHOLD = 5; // purchases needed for loyalty
    
    // --- State Variables ---
    
    // Optimized Item struct
    struct Item {
        string name;
        uint256 price;  // Full slot for precise decimal math
        uint128 supply;
        uint128 maxSupply;
        uint64 lastRestocked;
        uint64 salesCount;
        bool isActive;
        string imageURI;
        string category;
    }
    
    // Packed UserProfile
    struct UserProfile {
    uint128 totalPurchases;
    uint128 totalSpent;
    uint64 lastPurchase;
    uint32 loyaltyPoints;
    uint32 pointsExpiry; // New expiration timestamp
    uint16 discountRate;
    uint8 loyaltyTier;
    bool isBlacklisted;
}
    
    // Compact PurchaseRecord
    struct PurchaseRecord {
        uint64 timestamp;
        uint64 blockNumber;
        uint32 itemId;
        uint32 quantity;
        uint128 amountPaid;
    }
    
    
    
    // Core state
    Item[] public items;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => PurchaseRecord[]) private purchaseHistory;
    
    // Financial tracking
    uint256 public totalRevenue;
    uint256 public totalItemsSold;
    uint256 public deploymentTimestamp;
    
    // New: Enhanced analytics
    mapping(string => uint256) public categorySales;
    mapping(uint256 => uint256) public dailyRevenue; // day => revenue
    mapping(uint256 => uint256) public monthlyRevenue; // month => revenue
    
    // New: Economic controls
    uint256 public minPurchaseAmount = 0.0001 ether;
    uint256 public maxPurchaseAmount = 5 ether;
    uint256 public transactionFee = 0; // basis points (100 = 1%)
    address public feeRecipient;
    
    // New: Emergency controls
    mapping(address => bool) public emergencyWithdrawers;
    uint256 public maxDailyWithdrawal = 50 ether;
    mapping(uint256 => uint256) public dailyWithdrawn; // day => amount
    
    // New: Rate limiting
    mapping(address => uint256) public lastPurchaseTime;
    uint256 public purchaseCooldown = 1 minutes;
    mapping(address => address) public paymentToken;

    struct LoyaltyTier {
        uint256 threshold;
        uint16 discount;
        uint256 pointsMultiplier;
    }
    LoyaltyTier[] public loyaltyTiers;
    
    // --- Events ---
    event ItemPurchased(
        address indexed buyer,
        uint256 indexed itemId,
        string itemName,
        uint256 quantity,
        uint256 totalPaid,
        uint256 loyaltyPointsEarned
    );
    
    event ItemAdded(
        uint256 indexed itemId,
        string name,
        uint256 price,
        uint256 supply,
        string category
    );
    
    event ItemRestocked(
        uint256 indexed itemId,
        uint256 addedQuantity,
        uint256 newSupply
    );
    
    event LoyaltyPointsEarned(
        address indexed user,
        uint256 points,
        uint256 totalPoints
    );
    
    event UserBlacklisted(address indexed user, bool status);
    event EmergencyWithdrawal(address indexed withdrawer, uint256 amount);
    event FeeUpdated(uint256 newFee);
    event PurchaseLimitUpdated(uint256 minAmount, uint256 maxAmount);
    
    // --- Modifiers ---
    
    modifier validItem(uint256 _itemId) {
        require(_itemId < items.length, "VM: Invalid item ID");
        require(items[_itemId].isActive, "VM: Item not active");
        _;
    }
    
    modifier notBlacklisted() {
        require(!userProfiles[msg.sender].isBlacklisted, "VM: User blacklisted");
        _;
    }
    
    modifier rateLimited() {
        require(
            block.timestamp >= lastPurchaseTime[msg.sender] + purchaseCooldown,
            "VM: Purchase too frequent"
        );
        _;
    }
    
    modifier validQuantity(uint256 _quantity) {
        require(_quantity > 0, "VM: Quantity must be positive");
        require(_quantity <= MAX_QUANTITY_PER_PURCHASE, "VM: Quantity too large");
        _;
    }
    
    modifier withinPurchaseLimits(uint256 _amount) {
        require(_amount >= minPurchaseAmount, "VM: Amount too small");
        require(_amount <= maxPurchaseAmount, "VM: Amount too large");
        _;
    }
    
    // --- Constructor & Initialization ---
    
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address _owner) public initializer {
        // Initialize loyalty tiers
        loyaltyTiers.push(LoyaltyTier(100, 1000, 1)); // Bronze
        loyaltyTiers.push(LoyaltyTier(500, 1500, 2)); // Silver
        loyaltyTiers.push(LoyaltyTier(1000, 2000, 3)); // Gold
        __ReentrancyGuard_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(ADMIN_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
        
        deploymentTimestamp = block.timestamp;
        feeRecipient = _owner;
        
        // Initialize with sample items
        _addItem("Premium Coffee", 0.001 ether, 50, 100, "Beverages", "ipfs://QmCoffee");
        _addItem("Energy Drink", 0.0015 ether, 30, 50, "Beverages", "ipfs://QmEnergy");
        _addItem("Protein Bar", 0.0008 ether, 75, 100, "Snacks", "ipfs://QmProtein");
    }
    
    // --- Core Functions ---
    
    // Add emergency state tracking
    enum EmergencyState { Operational, PartialPause, FullPause }
    EmergencyState public emergencyState = EmergencyState.Operational;
    
    event EmergencyStopActivated(address indexed admin, EmergencyState newState);
    
    // Add circuit breaker modifier
    modifier emergencyStopEnabled() {
        require(emergencyState == EmergencyState.Operational, "VM: Emergency stop active");
        _;
    }
    
    // Update function signatures to include modifier
    function purchaseItem(uint256 _itemId, uint256 _quantity, address tokenAddress)
        external
        nonReentrant
        whenNotPaused
        emergencyStopEnabled
        validItem(_itemId)
        notBlacklisted
        rateLimited
        validQuantity(_quantity)
    {
        Item storage item = items[_itemId];
        require(item.supply >= _quantity, "VM: Insufficient supply");
        
        uint256 totalPrice = _calculatePrice(_itemId, _quantity, msg.sender);
        
        if (tokenAddress == address(0)) {
            require(msg.value >= totalPrice, "VM: Insufficient ETH");
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.allowance(msg.sender, address(this)) >= totalPrice, "VM: Insufficient allowance");
            token.transferFrom(msg.sender, address(this), totalPrice);
            paymentToken[msg.sender] = tokenAddress;
        }
        
        // Update state
        item.supply -= _quantity;
        item.salesCount += _quantity;
        totalItemsSold += _quantity;
        
        // Update user profile and loyalty
        UserProfile storage profile = userProfiles[msg.sender];
        profile.totalPurchases += _quantity;
        profile.totalSpent += totalPrice;
        profile.lastPurchase = block.timestamp;
        
        // Calculate loyalty points (1 point per 0.001 ether spent)
        uint256 pointsEarned = totalPrice / 0.001 ether;
        profile.loyaltyPoints += pointsEarned;
        
        // Update loyalty discount based on points
        if (profile.loyaltyPoints >= 100 && profile.discountRate < 10) {
            profile.discountRate = 10; // 10% discount for 100+ points
        } else if (profile.loyaltyPoints >= 50 && profile.discountRate < 5) {
            profile.discountRate = 5; // 5% discount for 50+ points
        }
        
        // Record purchase
        purchaseHistory[msg.sender].push(PurchaseRecord({
            timestamp: block.timestamp,
            itemId: _itemId,
            quantity: _quantity,
            amountPaid: totalPrice,
            blockNumber: block.number
        }));
        
        // Update analytics
        uint256 today = block.timestamp / 1 days;
        uint256 month = block.timestamp / 30 days;
        dailyRevenue[today] += totalPrice;
        monthlyRevenue[month] += totalPrice;
        categorySales[item.category] += _quantity;
        
        // Handle fees
        uint256 fee = (totalPrice * transactionFee) / 10000;
        uint256 netRevenue = totalPrice - fee;
        totalRevenue += netRevenue;
        
        if (fee > 0 && feeRecipient != address(0)) {
            payable(feeRecipient).transfer(fee);
        }
        
        // Refund excess payment
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        
        // Update rate limiting
        lastPurchaseTime[msg.sender] = block.timestamp;
        
        emit ItemPurchased(msg.sender, _itemId, item.name, _quantity, totalPrice, pointsEarned);
        emit LoyaltyPointsEarned(msg.sender, pointsEarned, profile.loyaltyPoints);
    }
    
    function bulkPurchase(uint256[] calldata _itemIds, uint256[] calldata _quantities)
        external
        payable
        nonReentrant
        whenNotPaused
        emergencyStopEnabled
        notBlacklisted
        rateLimited
    {
        require(_itemIds.length == _quantities.length, "VM: Array length mismatch");
        require(_itemIds.length > 0 && _itemIds.length <= 20, "VM: Invalid array length");
        
        uint256 totalCost = 0;
        uint256 totalQty = 0;
        
        // Pre-validate all items and calculate total cost
        for (uint256 i = 0; i < _itemIds.length; i++) {
            require(_itemIds[i] < items.length, "VM: Invalid item ID");
            require(items[_itemIds[i]].isActive, "VM: Item not active");
            require(_quantities[i] > 0 && _quantities[i] <= MAX_QUANTITY_PER_PURCHASE, "VM: Invalid quantity");
            require(items[_itemIds[i]].supply >= _quantities[i], "VM: Insufficient supply");
            
            totalCost += _calculatePrice(_itemIds[i], _quantities[i], msg.sender);
            totalQty += _quantities[i];
        }
        
        require(totalCost >= minPurchaseAmount && totalCost <= maxPurchaseAmount, "VM: Amount out of range");
        require(msg.value >= totalCost, "VM: Insufficient payment");
        
        // Process all purchases
        uint256 totalPointsEarned = 0;
        for (uint256 i = 0; i < _itemIds.length; i++) {
            uint256 itemId = _itemIds[i];
            uint256 quantity = _quantities[i];
            uint256 itemCost = _calculatePrice(itemId, quantity, msg.sender);
            
            // Update item state
            items[itemId].supply -= quantity;
            items[itemId].salesCount += quantity;
            
            // Record individual purchase
            purchaseHistory[msg.sender].push(PurchaseRecord({
                timestamp: block.timestamp,
                itemId: itemId,
                quantity: quantity,
                amountPaid: itemCost,
                blockNumber: block.number
            }));
            
            // Update category sales
            categorySales[items[itemId].category] += quantity;
            
            uint256 pointsEarned = itemCost / 0.001 ether;
            totalPointsEarned += pointsEarned;
            
            emit ItemPurchased(msg.sender, itemId, items[itemId].name, quantity, itemCost, pointsEarned);
        }
        
        // Update user profile
        UserProfile storage profile = userProfiles[msg.sender];
        profile.totalPurchases += totalQty;
        profile.totalSpent += totalCost;
        profile.loyaltyPoints += totalPointsEarned;
        profile.lastPurchase = block.timestamp;
        
        // Update global state
        totalItemsSold += totalQty;
        
        // Update analytics
        uint256 today = block.timestamp / 1 days;
        uint256 month = block.timestamp / 30 days;
        dailyRevenue[today] += totalCost;
        monthlyRevenue[month] += totalCost;
        
        // Handle fees
        uint256 fee = (totalCost * transactionFee) / 10000;
        uint256 netRevenue = totalCost - fee;
        totalRevenue += netRevenue;
        
        if (fee > 0 && feeRecipient != address(0)) {
            payable(feeRecipient).transfer(fee);
        }
        
        // Refund excess
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        lastPurchaseTime[msg.sender] = block.timestamp;
        
        emit LoyaltyPointsEarned(msg.sender, totalPointsEarned, profile.loyaltyPoints);
    }
    
    // --- Admin Functions ---
    
    function addItem(
        string calldata _name,
        uint256 _price,
        uint256 _supply,
        uint256 _maxSupply,
        string calldata _category,
        string calldata _imageURI
    ) external onlyRole(ADMIN_ROLE) {
        require(items.length < MAX_ITEMS, "VM: Max items reached");
        require(bytes(_name).length > 0, "VM: Empty name");
        require(_price >= MIN_PRICE && _price <= MAX_PRICE, "VM: Price out of range");
        require(_supply <= _maxSupply, "VM: Supply exceeds max");
        
        _addItem(_name, _price, _supply, _maxSupply, _category, _imageURI);
    }
    
    // Add category tracking mapping
    mapping(bytes32 => uint256[]) private _categoryItems;
    
    // Modified _addItem function
    function _addItem(
        string memory _name,
        uint256 _price,
        uint256 _supply,
        uint256 _maxSupply,
        string memory _category,
        string memory _imageURI
    ) internal {
        uint256 itemId = items.length;
        bytes32 categoryHash = keccak256(bytes(_category));
        
        items.push(Item({
            name: _name,
            price: _price,
            supply: _supply,
            maxSupply: _maxSupply,
            isActive: true,
            imageURI: _imageURI,
            category: _category,
            lastRestocked: block.timestamp,
            salesCount: 0
        }));
        
        emit ItemAdded(items.length - 1, _name, _price, _supply, _category);
    }
    
    // Update all struct references with casting where needed
function restockItem(uint256 _itemId, uint256 _quantity) external onlyRole(OPERATOR_ROLE) {
    Item storage item = items[_itemId];
    item.supply = uint128(uint256(item.supply) + _quantity);
    item.lastRestocked = uint64(block.timestamp);
}
    
    // Batch price update
    function batchUpdatePrices(uint256[] calldata _itemIds, uint256[] calldata _newPrices) 
        external 
        onlyRole(ADMIN_ROLE)
    {
        require(_itemIds.length == _newPrices.length, "VM: Array length mismatch");
        require(_itemIds.length <= 50, "VM: Batch too large");
        
        for (uint256 i = 0; i < _itemIds.length; i++) {
            require(_itemIds[i] < items.length, "VM: Invalid item ID");
            require(_newPrices[i] >= MIN_PRICE && _newPrices[i] <= MAX_PRICE, "VM: Price out of range");
            items[_itemIds[i]].price = _newPrices[i];
        }
    }
    
    // Batch restock
    function batchRestockItems(
        uint256[] calldata _itemIds,
        uint256[] calldata _quantities
    ) external onlyRole(OPERATOR_ROLE) {
        require(_itemIds.length == _quantities.length, "VM: Array length mismatch");
        require(_itemIds.length <= 100, "VM: Batch too large");
    
        for (uint256 i = 0; i < _itemIds.length; i++) {
            Item storage item = items[_itemIds[i]];
            require(item.supply + _quantities[i] <= item.maxSupply, "VM: Exceeds max supply");
            item.supply += uint128(_quantities[i]);
            item.lastRestocked = uint64(block.timestamp);
        }
    }
    
    // Batch toggle activation
    function batchToggleActive(uint256[] calldata _itemIds, bool[] calldata _statuses)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(_itemIds.length == _statuses.length, "VM: Array length mismatch");
        
        for (uint256 i = 0; i < _itemIds.length; i++) {
            require(_itemIds[i] < items.length, "VM: Invalid item ID");
            items[_itemIds[i]].isActive = _statuses[i];
        }
    }
    
    function blacklistUser(address _user, bool _status) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        userProfiles[_user].isBlacklisted = _status;
        emit UserBlacklisted(_user, _status);
    }
    
    function updateTransactionFee(uint256 _newFee) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        require(_newFee <= 1000, "VM: Fee too high"); // Max 10%
        transactionFee = _newFee;
        emit FeeUpdated(_newFee);
    }
    
    function updatePurchaseLimits(uint256 _minAmount, uint256 _maxAmount) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        require(_minAmount < _maxAmount, "VM: Invalid limits");
        minPurchaseAmount = _minAmount;
        maxPurchaseAmount = _maxAmount;
        emit PurchaseLimitUpdated(_minAmount, _maxAmount);
    }
    
    // --- Emergency Functions ---
    
    function emergencyWithdraw(uint256 _amount, address tokenAddress) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        if(tokenAddress != address(0)) {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(msg.sender, _amount);
        } else {
        uint256 today = block.timestamp / 1 days;
        require(
            dailyWithdrawn[today] + _amount <= maxDailyWithdrawal,
            "VM: Daily limit exceeded"
        );
        
        dailyWithdrawn[today] += _amount;
        payable(msg.sender).transfer(_amount);
        }
        
        emit EmergencyWithdrawal(msg.sender, _amount);
    }
    
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    // --- View Functions ---
    
    function _calculatePrice(uint256 _itemId, uint256 _quantity, address _buyer) 
        internal 
        view 
        returns (uint256) 
    {
        uint256 basePrice = items[_itemId].price * _quantity;
        uint256 discount = userProfiles[_buyer].discountRate;
        
        if (discount > 0) {
            uint256 discountAmount = (basePrice * discount) / 100;
            return basePrice - discountAmount;
        }
        
        return basePrice;
    }
    
    function getPurchaseHistory(address _user, uint256 _offset, uint256 _limit)
        external
        view
        returns (PurchaseRecord[] memory)
    {
        require(
            msg.sender == _user || hasRole(ADMIN_ROLE, msg.sender),
            "VM: Not authorized"
        );
        
        PurchaseRecord[] storage history = purchaseHistory[_user];
        if (_offset >= history.length) {
            return new PurchaseRecord[](0);
        }
        
        uint256 end = _offset + _limit;
        if (end > history.length) {
            end = history.length;
        }
        
        PurchaseRecord[] memory result = new PurchaseRecord[](end - _offset);
        for (uint256 i = _offset; i < end; i++) {
            result[i - _offset] = history[i];
        }
        
        return result;
    }
    
    // Optimized getItemsByCategory
    function getBulkCategoryItems(string[] calldata _categories)
        external
        view
        returns (uint256[][] memory)
    {
        uint256[][] memory result = new uint256[][](_categories.length);
        for (uint256 i = 0; i < _categories.length; i++) {
            bytes32 categoryHash = keccak256(bytes(_categories[i]));
            result[i] = _categoryItems[categoryHash];
        }
        return result;
    }
    
    function getAnalytics() 
        external 
        view 
        onlyRole(ADMIN_ROLE) 
        returns (
            uint256 totalItems,
            uint256 activeItems,
            uint256 totalSold,
            uint256 totalRev,
            uint256 contractBalance,
            uint256 uniqueUsers
        ) 
    {
        uint256 active = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (items[i].isActive) active++;
        }
        
        return (
            items.length,
            active,
            totalItemsSold,
            totalRevenue,
            address(this).balance,
            0 // Would need to implement user counting
        );
    }
    
    // --- Upgrade Functions ---
    
    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyRole(UPGRADER_ROLE) 
    {}
    
    // --- Fallback ---
    
    receive() external payable {
        // Accept direct ETH deposits
    }
}

// Add emergency control functions
function activateFullEmergencyStop() external onlyRole(ADMIN_ROLE) {
    emergencyState = EmergencyState.FullPause;
    _pause(); // Automatically pause contract
    emit EmergencyStopActivated(msg.sender, EmergencyState.FullPause);
}

function activatePartialEmergency() external onlyRole(ADMIN_ROLE) {
    emergencyState = EmergencyState.PartialPause;
    emit EmergencyStopActivated(msg.sender, EmergencyState.PartialPause);
}

function resumeNormalOperations() external onlyRole(ADMIN_ROLE) {
    emergencyState = EmergencyState.Operational;
    _unpause();
    emit EmergencyStopActivated(msg.sender, EmergencyState.Operational);
}

// Add nonce tracking
mapping(address => uint256) public nonces;

event NonceUsed(address indexed user, uint256 nonce);

// Create modifier for signature verification
modifier withSignature(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 nonce
) {
    bytes32 ethSignedHash = keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
    
    require(ecrecover(ethSignedHash, v, r, s) == msg.sender, "VM: Invalid signature");
    require(nonces[msg.sender] < nonce, "VM: Replayed transaction");
    nonces[msg.sender] = nonce;
    emit NonceUsed(msg.sender, nonce);
    _;
}

// Update purchase functions with signature verification
function purchaseItem(uint256 _itemId, uint256 _quantity, uint256 nonce, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    external
    payable
    withSignature(hash, v, r, s, nonce)
    validItem(_itemId)
    notBlacklisted
    rateLimited
    validQuantity(_quantity)
{
    require(
        hash == keccak256(abi.encode(_itemId, _quantity, nonce)),
        "VM: Hash mismatch"
    );
    
    // Actual purchase execution happens here
    _processPurchase(_itemId, _quantity); // Internal function call
}

function bulkPurchase(uint256[] calldata _itemIds, uint256[] calldata _quantities, uint256 nonce, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    external
    payable
    withSignature(hash, v, r, s, nonce)
    validItem(_itemId)
    notBlacklisted
    rateLimited
{
    require(
        hash == keccak256(abi.encode(_itemIds, _quantities, nonce)),
        "VM: Hash mismatch"
    );
    // Existing bulk purchase logic
}