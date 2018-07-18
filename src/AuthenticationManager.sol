pragma solidity ^0.4.24;

/* The authentication manager details user accounts that have access to certain priviledges and keeps a permanent ledger of who has and has had these rights. */
contract AuthenticationManager {
    
    /* Map addresses to current admins and account readers, and current or past admins/account readers for audit purposes*/
    mapping (address => bool) adminAddresses;
    mapping (address => bool) adminCurrentOrPast;
    mapping (address => bool) accountReaderAddresses;
    mapping (address => bool) accountReaderCurrentOrPast;
    
    /* Details of all admins and account readers that have ever existed for auditing purposes */
    mapping (address => uint) adminAuditPosition;
    mapping (address => uint) accountReaderAuditPosition;
    address[] adminAudit;
    address[] accountReaderAudit;

    event AdminAdded(address addedBy, address admin);                   /* Fired whenever an admin is added to the contract.     */
    event AdminRemoved(address removedBy, address admin);               /* Fired whenever an admin is removed from the contract. */
    event AccountReaderAdded(address addedBy, address account);         /* Fired whenever an account-reader contract is added.   */
    event AccountReaderRemoved(address removedBy, address account);     /* Fired whenever an account-reader contract is removed. */

    // CONSTRUCTOR
    /* When this contract is first setup we use the creator as the first admin */
    constructor() public {
        if(adminAudit.length == 0) adminAudit.length++;                 // initially incrementing this array to reserve position 0
        if(accountReaderAudit.length == 0) accountReaderAudit.length++; // initially incrementing this array to reserve position 0
        
        adminAddresses[msg.sender] = true;
        adminCurrentOrPast[msg.sender] = true;
        emit AdminAdded(0, msg.sender);
        adminAudit.length++; // set up contract creator as admin in array position 1
        adminAudit[adminAudit.length - 1] = msg.sender;
        adminAuditPosition[msg.sender] = adminAudit.length - 1;
    }

    /* Contract version is used for validation and permissions purposes by other contracts*/
    function contractVersion() pure public returns(uint256) { return 100201807150800; }     // Admin contract identifies as 100YYYYMMDDHHMM

    /* Function block returns bool of whether or not any given address is an admin, an account reader, or has been either in the past*/
    function isCurrentAdmin(address _address) constant public returns (bool)                { return adminAddresses[_address]; }
    function isCurrentOrPastAdmin(address _address) constant public returns (bool)          { return adminCurrentOrPast[_address]; }
    function isCurrentAccountReader(address _address) constant public returns (bool)        { return accountReaderAddresses[_address]; }
    function isCurrentOrPastAccountReader(address _address) constant public returns (bool)  { return accountReaderCurrentOrPast[_address]; }
    
       /* Adds a user to our list of admins */
    function addAdmin(address _address) public {
        if (!isCurrentAdmin(msg.sender)) revert();  /* Ensure we're an admin */
        if (adminAddresses[_address])    revert();  // Fail if this account is already admin
        
        // Add the user
        emit AdminAdded(msg.sender, _address);
        adminAudit.length++;
        adminAudit[adminAudit.length - 1] = _address;
        if(!adminCurrentOrPast[_address]) adminAuditPosition[_address] = adminAudit.length - 1; //Check to ensure we don't keep adding the same address to the list
        adminAddresses[_address] = true;
        adminCurrentOrPast[_address] = true;
    }

    /* Removes a user from our list of admins but keeps them in the history audit */
    function removeAdmin(address _address) public {
        if (!isCurrentAdmin(msg.sender)) revert();  /* Ensure we're an admin */
        if (_address == msg.sender)      revert();  /* Don't allow removal of self */
        if (!adminAddresses[_address])   revert();  // Fail if provided account is already non-admin
            

        /* Remove this admin user */
        adminAddresses[_address] = false;
        emit AdminRemoved(msg.sender, _address);
    }

    /* Adds a user/contract to our list of account readers */
    function addAccountReader(address _address) public{
        if (!isCurrentAdmin(msg.sender))      revert();  /* Ensure we're an admin */
        if (accountReaderAddresses[_address]) revert();  // Fail if this account is already in the list
        
        // Add the user
        emit AccountReaderAdded(msg.sender, _address);
        accountReaderAudit.length++;
        accountReaderAudit[accountReaderAudit.length - 1] = _address;
        if(!accountReaderCurrentOrPast[_address]) accountReaderAuditPosition[_address] = accountReaderAudit.length - 1; //Check to ensure we don't keep adding the same address to the list
        accountReaderAddresses[_address] = true;
        accountReaderCurrentOrPast[_address] = true;
    }

    /* Removes a user/contracts from our list of account readers but keeps them in the history audit */
    function removeAccountReader(address _address) public {
        if (!isCurrentAdmin(msg.sender))        revert(); /* Ensure we're an admin */
        if (!accountReaderAddresses[_address])  revert(); // Fail if this account is already not in the list

        /* Remove this account reader user */
        accountReaderAddresses[_address] = false;
        emit AccountReaderRemoved(msg.sender, _address);
    }
}
