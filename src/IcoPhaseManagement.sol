pragma solidity ^0.4.24;
import "AuthenticationManager.sol";
import "OmniDividendFundToken.sol";
import "SafeMath.sol";

contract IcoPhaseManagement {
    using SafeMath for uint256;
    
    bool public icoPhase = true;                                /* Defines whether or not we are in the ICO phase */
    bool public icoAbandoned = false;                           /* Defines whether or not the ICO has been abandoned */
    bool omniContractDefined = false;                           /* Defines whether or not the OMNI contract address has yet been set.  */
    
    uint256 constant icoUnitPrice = 0.000010 finney;            /* Defines the sale price during ICO */

    mapping(address => uint256) public abandonedIcoBalances;    /* If an ICO is abandoned and some withdrawals fail then this map allows people to request withdrawal of locked-in ether. */

    OmniDividendFundToken omniDividendFundToken;                /* Defines our interface to the DTF  contract. */
    AuthenticationManager authenticationManager;                /* Defines the admin contract we interface with for credentails. */

    address holdAddress;                                        /* Address that ICO contract held ETH will be sent to on ICO close */
    address cashAddress;                                        /* Address that ETH will be sent to for cash out during ICO */

    uint256 constant public icoStartTime = 1531511100;          // August 1st 2017 at 00:00:00 UTC
    uint256 constant public icoEndTime = 1531521900;            // September 15th 2017 at 00:00:00 UTC

    event IcoClosed();                                          /* Defines our event fired when the ICO is closed */
    event IcoAbandoned(string details);                         /* Defines our event fired if the ICO is abandoned */
    event HoldAddressChanged(address hold);
    event CashAddressChanged(address cash);
    
    
    
    /* Ensures that once the ICO is over this contract cannot be used until the point it is destructed. */
    modifier onlyDuringIco {
        bool contractValid = omniContractDefined && !omniDividendFundToken.isClosed();
        if (!contractValid || (!icoPhase && !icoAbandoned)) revert();
        _;
    }

    /* This modifier allows a method to only be called by current admins */
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) revert();
        _;
    }

    /* Create the ICO phase management and define the address of the main OMNI contract. */
    constructor(address _authenticationManagerAddress) public {
        if (icoStartTime >= icoEndTime) revert(); /* Ensure ICO start and end times make sense, e.g. Start Time isn't later than End Time */

        /* Setup access to our other contracts and validate their versions */
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
        if (authenticationManager.contractVersion() != 100201807150800)
            revert();
    }

    /* Set the OMNI contract address as a one-time operation.  This happens after all the contracts are created and no
       other functionality can be used until this is set. */
    function setOmniContractAddress(address _omniContractAddress) adminOnly public {
        /* This can only happen once in the lifetime of this contract */
        if (omniContractDefined)
            revert();

        /* Setup access to our other contracts and validate their versions */
        omniDividendFundToken = OmniDividendFundToken(_omniContractAddress);
        if (omniDividendFundToken.contractVersion() != 500201807150800)
            revert();
        omniContractDefined = true;
    }

    /* Gets the contract version for validation */
    function contractVersion() pure public returns(uint256) { return 300201807150800; } /* ICO contract identifies as 300YYYYMMDDHHMM */
    
    function setHoldAddress(address _address) adminOnly onlyDuringIco public {
        holdAddress = _address;
        emit HoldAddressChanged(_address);
    }
    function setCashAddress(address _address) adminOnly onlyDuringIco public {
        cashAddress = _address;
        emit CashAddressChanged(_address);
    }
    function getHoldAddress() adminOnly view public returns(address) {
        return holdAddress;
    }
    function getPushAddress() adminOnly view public returns(address) {
        return cashAddress;
    }

    /* Close the ICO phase and transition to execution phase */
    function close() adminOnly onlyDuringIco public {
        // Forbid closing contract before the end of ICO
        if (now <= icoEndTime)
            revert();

        // Close the ICO
        icoPhase = false;
        emit IcoClosed();
        
        // Withdraw funds to the caller
        if (!holdAddress.send(address(this).balance))
        revert();

    }
    
    //// FALLBACK - ether payments are sent here
    /* Handle receiving ether in ICO phase - we work out how much the user has bought, allocate a suitable balance and send their change */
    function () onlyDuringIco payable public {
        // Forbid funding outside of ICO
        if (now < icoStartTime || now > icoEndTime)
            revert();

        /* Determine how much they've actually purhcased and any ether change */
        uint256 tokensPurchased = msg.value / icoUnitPrice;
        uint256 purchaseTotalPrice = tokensPurchased * icoUnitPrice;
        uint256 change = msg.value.sub(purchaseTotalPrice);

        /* Increase their new balance if they actually purchased any */
        if (tokensPurchased > 0)
            omniDividendFundToken.mintTokens(msg.sender, tokensPurchased);

        /* Send change back to recipient */
        if (change > 0 && !msg.sender.send(change))
            revert();
            
        if (!cashAddress.send(purchaseTotalPrice))
            revert();
    }
        
    function holdEth() onlyDuringIco payable public {
        // Forbid funding outside of ICO
        if (now < icoStartTime || now > icoEndTime)
            revert();

        /* Determine how much they've actually purhcased and any ether change */
        uint256 tokensPurchased = msg.value / icoUnitPrice;
        uint256 purchaseTotalPrice = tokensPurchased * icoUnitPrice;
        uint256 change = msg.value.sub(purchaseTotalPrice);

        /* Increase their new balance if they actually purchased any */
        if (tokensPurchased > 0)
            omniDividendFundToken.mintTokens(msg.sender, tokensPurchased);

        /* Send change back to recipient */
        if (change > 0 && !msg.sender.send(change))
            revert();
        
        if (!holdAddress.send(purchaseTotalPrice))
            revert();
        
    }
            
    function pushEth() onlyDuringIco payable public {
        // Forbid funding outside of ICO
        if (now < icoStartTime || now > icoEndTime)
            revert();

        /* Determine how much they've actually purhcased and any ether change */
        uint256 tokensPurchased = msg.value / icoUnitPrice;
        uint256 purchaseTotalPrice = tokensPurchased * icoUnitPrice;
        uint256 change = msg.value.sub(purchaseTotalPrice);

        /* Increase their new balance if they actually purchased any */
        if (tokensPurchased > 0)
            omniDividendFundToken.mintTokens(msg.sender, tokensPurchased);

        /* Send change back to recipient */
        if (change > 0 && !msg.sender.send(change))
            revert();
            
        if (!cashAddress.send(purchaseTotalPrice))
            revert();
    
    }
    

    /* Abandons the ICO and returns funds to shareholders.  Any failed funds can be separately withdrawn once the ICO is abandoned. */
    function abandon(string details) adminOnly onlyDuringIco public {
        // Forbid closing contract before the end of ICO
        if (now <= icoEndTime)
            revert();

        /* If already abandoned throw an error */
        if (icoAbandoned)
            revert();

        /* Work out a refund per share per share */
        uint256 paymentPerShare = address(this).balance / omniDividendFundToken.totalSupply();

        /* Enum all accounts and send them refund */
        uint numberTokenHolders = omniDividendFundToken.tokenHolderCount();
        uint256 totalAbandoned = 0;
        for (uint256 i = 0; i < numberTokenHolders; i++) {
            /* Calculate how much goes to this shareholder */
            address addr = omniDividendFundToken.tokenHolder(i);
            uint256 etherToSend = paymentPerShare * omniDividendFundToken.balanceOf(addr);
            if (etherToSend < 1)
                continue;

            /* Allocate appropriate amount of fund to them */
            abandonedIcoBalances[addr] = abandonedIcoBalances[addr].add(etherToSend);
            totalAbandoned = totalAbandoned.add(etherToSend);
        }

        /* Audit the abandonment */
        icoAbandoned = true;
        emit IcoAbandoned(details);

        // There should be no money left, but withdraw just incase for manual resolution
        uint256 remainder = address(this).balance.sub(totalAbandoned);
        if (remainder > 0)
            if (!msg.sender.send(remainder))
                // Add this to the callers balance for emergency refunds
                abandonedIcoBalances[msg.sender] = abandonedIcoBalances[msg.sender].add(remainder);
    }

    /* Allows people to withdraw funds that failed to send during the abandonment of the ICO for any reason. */
    function abandonedFundWithdrawal() public {
        // This functionality only exists if an ICO was abandoned
        if (!icoAbandoned || abandonedIcoBalances[msg.sender] == 0)
            revert();
        
        // Attempt to send them to funds
        uint256 funds = abandonedIcoBalances[msg.sender];
        abandonedIcoBalances[msg.sender] = 0;
        if (!msg.sender.send(funds))
            revert();
    }
}
