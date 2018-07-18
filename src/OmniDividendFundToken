pragma solidity ^0.4.24;
import "AuthenticationManager.sol";
import "IcoPhaseManagement.sol";
import "SafeMath.sol";


/* The OMNI itself is a simple extension of the ERC20 that allows for granting other ODFT contracts special rights to act on behalf of all transfers. */
contract OmniDividendFundToken {
    using SafeMath for uint256;

    mapping (address => uint256) balances;                      /* Map all our our balances for issued tokens */
    mapping (address => mapping (address => uint256)) allowed;  /* Map between users and their approval addresses and amounts */
    
    mapping (address => bool) tokenHolderAddresses;             /* Map whether an address is currently holding tokens or not */
    mapping (address => uint) tokenHolderArrayPosition;         /* Map the allTokenHolders[] array position in which the address currently resides to the address*/
    address[] allTokenHolders;                                  /* List of all token holders */

    string  public name;                                        /* The name of the contract token*/
    string  public symbol;                                      /* The symbol for the contract token*/
    uint8   public decimals;                                    /* How many DPs are in use in this contract token*/
    uint256 totalSupplyAmount = 0;                              /* Defines the current supply of the token in its own units */

    address public icoContractAddress;                          /* Defines the address of the ICO contract which is the only contract permitted to mint tokens. */
    bool    public isClosed;                                    /* Defines whether or not the fund is closed. */

    IcoPhaseManagement    icoPhaseManagement;                   /* Defines the contract handling the ICO phase. */
    AuthenticationManager authenticationManager;                /* Defines the admin contract we interface with for credentails. */

    // Following two events required for ERC20 standard compliant token
    event Transfer(address indexed from, address indexed to, uint256 value);            /* Our transfer event to fire whenever we shift OMNI around */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);   /* Our approval event when one user approves another to control */
    event FundClosed();                                                                 /* Fired when the fund is eventually closed. */

    //CONSTRUCTOR
    /* Create a new instance of this fund with links to other contracts that are required. */
    constructor(address _icoContractAddress, address _authenticationManagerAddress) public {
        // Setup token information
        name = "Omni Dividend Fund Token";
        symbol = "XDIV";
        decimals = 6;

        /* Setup access to our other contracts and validate their versions */
        icoPhaseManagement    = IcoPhaseManagement(_icoContractAddress);              if (icoPhaseManagement.contractVersion()    != 300201807150800) revert();
        authenticationManager = AuthenticationManager(_authenticationManagerAddress); if (authenticationManager.contractVersion() != 100201807150800) revert();
        
        /* Store our special addresses */
        icoContractAddress = _icoContractAddress;
        
        if(allTokenHolders.length == 0) allTokenHolders.length++; // Initially increasing array to reserve position 0
    }

    //Modifier block
    modifier onlyPayloadSize(uint numwords) { assert(msg.data.length == numwords * 32 + 4); _; } 
    modifier accountReaderOnly { if (!authenticationManager.isCurrentAccountReader(msg.sender)) revert(); _; } /* This modifier allows a method to only be called by account readers */
    modifier fundSendablePhase {
        if (icoPhaseManagement.icoPhase())     revert();    // If it's in ICO phase, forbid it
        if (icoPhaseManagement.icoAbandoned()) revert();    // If it's abandoned, forbid it
        _;                                                  // We're good, funds can now be transferred
    }

    function tokenHolderCount() accountReaderOnly constant public returns (uint256) { return allTokenHolders.length; }              /* Returns the total number of holders of this currency. */
    function tokenHolder(uint256 _index) accountReaderOnly constant public returns (address) { return allTokenHolders[_index]; }    /* Gets the token holder at the specified index. */
    function contractVersion() pure public returns(uint256) { return 500201807150800; }                                             /* Gets the contract version for validation - OMNI contract identifies as 500YYYYMMDDHHMM */
    
    //Following six functions required for ERC20 standard compliant token
    /*-------
    totalSupply()                                               - Gets the total supply available of this token
    balanceOf(address _owner)                                   - Gets the balance of a specified account
    allowance(address _owner, address _spender)                 - Gets the current allowance that has been approved for the specified spender of the owner address
    transfer(address _to, uint256 _amount)                      - Transfer the balance from owner's account to another account
    approve(address _spender, uint256 _amount)                  - Adds an approval for the specified account to spend money of the message sender up to the defined limit
    transferFrom(address _from, address _to, uint256 _amount)   - Transfer funds between two addresses that are not the current msg.sender - this requires approval to have been set separately and follows standard ERC20 guidelines
    -------*/
    function totalSupply() constant public returns (uint256)                                            { return totalSupplyAmount; }
    function balanceOf(address _owner) constant public returns (uint256 balance)                        { return balances[_owner]; }
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining)    { return allowed[_owner][_spender]; }
    function transfer(address _to, uint256 _amount) fundSendablePhase onlyPayloadSize(2) public returns (bool) {
        if (balances[msg.sender] < _amount || balances[_to].add(_amount) < balances[_to]) return false; /* Check if sender has balance and for overflows */

        bool isRecipientNew = balances[_to] < 1; /* Do a check to see if they are new, if so we'll want to add it to our array */

        /* Add and subtract new balances */
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        /* Consolidate arrays if they are new or if sender now has empty balance */
        if (isRecipientNew) tokenOwnerAdd(_to);
        if (balances[msg.sender] == 0) tokenOwnerRemove(msg.sender);

        emit Transfer(msg.sender, _to, _amount); /* Fire notification event */
        return true;
    }    
    function approve(address _spender, uint256 _amount) fundSendablePhase onlyPayloadSize(2) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }    
    function transferFrom(address _from, address _to, uint256 _amount) fundSendablePhase onlyPayloadSize(3) public returns (bool) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]) {
            bool isNew = balances[_to] == 0;
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            if (isNew)
                tokenOwnerAdd(_to);
            if (balances[_from] == 0)
                tokenOwnerRemove(_from);
            emit Transfer(_from, _to, _amount);
            return true;
        }
        return false;
    }

    /* If the specified address is not in our owner list, add them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerAdd(address _address) internal {
        if(tokenHolderAddresses[_address]) revert(); //Fail if address already possesses tokens
        
        /* They don't seem to exist, so let's add them */
        allTokenHolders.length++;                                               // Increase array size
        allTokenHolders[allTokenHolders.length - 1] = _address;                 // Add address to array position just created
        tokenHolderArrayPosition[_address] = allTokenHolders.length - 1;        // Assign array position to token holder address/position mapping
        tokenHolderAddresses[_address] = true;                                  // Set address as a valid token holder
    }

    /* If the specified address is in our owner list, remove them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerRemove(address _address) internal {
        if(!tokenHolderAddresses[_address]) revert(); //Fail if address does not possess tokens
        
        // Array management
        // We'll shrink the allTokenHolders array by copying the last entry in the array 
        // to the position of the token holder we're removing, then remove the address
        // we've copied from the end of the array. We'll then update the mapping of the
        // address we moved with it's new position in the array.
        
        // Previously, a loop was used to perform this management, and resulted
        // in ever increasing gas costs as the array size grew
        
        uint tempPos;                                                               // tempPos variable used for array position shuffling of addresses
        tempPos = tokenHolderArrayPosition[_address];                               // we assign the array position of the adress we are removing to the temp variable
        allTokenHolders[tempPos] = allTokenHolders[allTokenHolders.length - 1];     // assign the address at the end of the array to the position of the address we're removing
        tokenHolderArrayPosition[_address] = 0;                                     // setting the array position of the address we're removing to 0. position 0 is reserved for addresses that do not hold tokens.
        tokenHolderArrayPosition[allTokenHolders[tempPos]] = tempPos;               // setting the array position of the address we just moved to original position of the address we removed
        tokenHolderAddresses[_address] = false;                                     // set the address to false to reflect that is no longer holds tokens
        allTokenHolders.length--;                                                   // decrease the array size, removing the original entry of the address we moved
    }

    /* Mint new tokens - this can only be done by special callers (i.e. the ICO management) during the ICO phase. */
    function mintTokens(address _address, uint256 _amount) public onlyPayloadSize(2) {
        if (msg.sender != icoContractAddress || !icoPhaseManagement.icoPhase()) revert(); /* Ensure we are the ICO contract calling */

        /* Mint the tokens for the new address*/
        bool isNew = balances[_address] == 0;
        totalSupplyAmount = totalSupplyAmount.add(_amount);
        balances[_address] = balances[_address].add(_amount);
        if (isNew)
            tokenOwnerAdd(_address);
        emit Transfer(0, _address, _amount);
    }
}
