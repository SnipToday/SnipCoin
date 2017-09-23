pragma solidity ^0.4.15;

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 );

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract StandardToken is Token {
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

// Based on TokenFactory(https://github.com/ConsenSys/Token-Factory)

contract SnipCoin is StandardToken {
    /* Public variables of the token */

    string public constant name = "SnipCoin";       // Token name
    string public symbol = "SNIP";          // Token identifier
    uint8 public constant decimals = 18;          // Decimal points for token
    uint public totalEthReceivedInWei; // The total amount of Ether received during the sale in WEI
    uint public totalUsdReceived; // The total amount of Ether received during the sale in USD terms
    string public version = "1.0"; // Code version
    address public saleWalletAddress;  // The wallet address where the Ether from the sale will be stored
    
    mapping (address => bool) uncappedBuyerList; // The list of buyers allowed to participate in the sale without a cap
    mapping (address => bool) cappedBuyerList;   // The list of buyers allowed to participate in the sale

    uint public snipCoinToEtherExchangeRate = 300000; // This is the ratio of SnipCoin to Ether, could be updated by the owner
    bool public isSaleOpen = false; // This opens and closes upon external command
    uint public ethToUsdExchangeRate = 285; // Number of USD in one Eth
    
    address private contractOwner;  // Address of the contract owner
    // Address of an additional account to manage the sale without risk to the tokens or eth. Change before the sale
    address private accountWithUpdatePermissions = 0x686f152daD6490DF93B267E319f875A684Bd26e2;

    uint private constant DECIMALS_MULTIPLIER = 10**uint(decimals);    // Multiplier for the decimals
    uint private constant WEI_IN_ETHER = 1000 * 1000 * 1000 * 1000 * 1000 * 1000; // Number of wei in 1 eth
    uint public constant SALE_CAP_IN_USD = 8000000;  // The total sale cap in USD
    uint public constant MINIMUM_PURCHASE_IN_USD = 50;  // It is impossible to purchase tokens for more than $50 in the sale.
    uint public constant USD_PURCHASE_AMOUNT_REQUIRING_ID = 4500;  // Above this purchase amount an ID is required.

    function initializeSaleWalletAddress()
    {
        saleWalletAddress = 0x686f152daD6490DF93B267E319f875A684Bd26e2; // Change before the sale
    }

    function initializeEthReceived()
    {
        totalEthReceivedInWei = 14500 * WEI_IN_ETHER; // Ether received before public sale. Verify this figure before the sale starts.
    }

    function initializeUsdReceived()
    {
        totalUsdReceived = 4000000; // USD received before public sale. Verify this figure before the sale starts.
    }

    function getBalance(address addr) returns(uint)
    {
        return balances[addr];
    }

    function getWeiToUsdExchangeRate() returns(uint)
    {
        return WEI_IN_ETHER / ethToUsdExchangeRate; // Returns how much Wei one USD is worth
    }

    function updateEthToUsdExchangeRate(uint newEthToUsdExchangeRate)
    {
        require((msg.sender == contractOwner) || (msg.sender == accountWithUpdatePermissions)); // Verify ownership
        ethToUsdExchangeRate = newEthToUsdExchangeRate; // Change exchange rate to new value, influences the counter of when the sale is over.
    }

    function updateSnipCoinToEtherExchangeRate(uint newSnipCoinToEtherExchangeRate)
    {
        require((msg.sender == contractOwner) || (msg.sender == accountWithUpdatePermissions)); // Verify ownership
        snipCoinToEtherExchangeRate = newSnipCoinToEtherExchangeRate; // Change the exchange rate to new value, influences tokens received per purchase
    }

    function openOrCloseSale(bool saleCondition)
    {
        require((msg.sender == contractOwner) || (msg.sender == accountWithUpdatePermissions)); // Verify ownership
        isSaleOpen = saleCondition; // Decide if the sale should be open or closed (default: closed)
    }

    function addAddressToCappedAddresses(address addr)
    {
        require((msg.sender == contractOwner) || (msg.sender == accountWithUpdatePermissions)); // Verify ownership
        cappedBuyerList[addr] = true; // Allow a certain address to purchase SnipCoin up to the cap (<4500)
    }

    function addAddressToUncappedAddresses(address addr)
    {
        require((msg.sender == contractOwner) || (msg.sender == accountWithUpdatePermissions)); // Verify ownership
        uncappedBuyerList[addr] = true; // Allow a certain address to purchase SnipCoin above the cap (>=$4500)
    }

    function SnipCoin()
    {
        initializeSaleWalletAddress();
        initializeEthReceived();
        initializeUsdReceived();

        contractOwner = msg.sender; // The creator of the contract is its owner
        totalSupply = 10000000000 * DECIMALS_MULTIPLIER;      // In total, 10 billion tokens
        balances[msg.sender] = totalSupply;        // Initially give owner all of the tokens 
    }

    function verifySaleNotOver()
    {
        require(isSaleOpen);
        require(totalUsdReceived < SALE_CAP_IN_USD); // Make sure that sale isn't over
    }

    function verifyBuyerCanMakePurchase() payable
    {
        uint purchaseValueInUSD = uint(msg.value / getWeiToUsdExchangeRate()); // The USD worth of tokens sold

        require(purchaseValueInUSD > MINIMUM_PURCHASE_IN_USD); // Minimum transfer is of $50

        uint EFFECTIVE_MAX_CAP = SALE_CAP_IN_USD + 1000;  // This allows for the end of the sale by passing $8M and reaching the cap
        require(EFFECTIVE_MAX_CAP - totalUsdReceived > purchaseValueInUSD); // Make sure that there is enough usd left to buy.
        
        if (purchaseValueInUSD >= USD_PURCHASE_AMOUNT_REQUIRING_ID) // Check if buyer is on uncapped white list
        {
            require(uncappedBuyerList[msg.sender]);
        }
        if (purchaseValueInUSD < USD_PURCHASE_AMOUNT_REQUIRING_ID) // Check if buyer is on capped white list
        {
            require(cappedBuyerList[msg.sender] || uncappedBuyerList[msg.sender]);
        }
    }

    function () payable
    {
        verifySaleNotOver();
        verifyBuyerCanMakePurchase();

        saleWalletAddress.transfer(msg.value); // Transfer ether to safe sale address
        transferFrom(contractOwner, msg.sender, uint(snipCoinToEtherExchangeRate * msg.value / WEI_IN_ETHER)); // Send tokens to buyer according to ratio
        totalEthReceivedInWei = totalEthReceivedInWei + msg.value; // total eth received counter
        totalUsdReceived = totalUsdReceived + msg.value / getWeiToUsdExchangeRate(); // total usd received counter
    }
}