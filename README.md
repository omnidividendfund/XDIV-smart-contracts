# The Omni Dividend Fund (XDIV)
The Omni Dividend fund is an investment fund that seeks to build the most secure and easy-to-invest product by providing income each month from cryptocurrency investments and trading various market assets. The fund seeks to maximize portability and anonymity via our private blockchain token, XDIV.

The smart contracts that back XDIV all expose different features.  Core functionality is deployed at the start of XDIV's lifecycle, with thought given to adding additional contracts to extend functionality moving forward.

# Contracts
Three contracts are currently used to form XDIV.  It is planned to add additional future contracts, specifically automation contracts for dividend management.  These will integrate via the authentication manager and XDIV token contracts.

All contracts return a contract version in the format ###YYYYMMDDHHmmSS where ### is a unique number for a particular contract.  This allows other contracts and calling applications to ensure the address specified is correct and that the calling code will support execution.

The contracts use some basic code protections that are commonplace including SafeMath and checking for payload underflow which has been used to hijack balances from exchanges.

Multiple contracts have been used, rather than a monolith, so that everything is easier to test and so that if any individual piece of the puzzle becomes broken it will be easier to work around or redeploy individual contracts at a future date (depending on the specific issue).

## Authentication Manager
The authentication manager is responsible for manager user and contract rights to all other contracts.  Two classes of authentication exist - admin users and account readers.

Admin users get some special priviledges depending on the contract - this could be ending the ICO and withdrawing funds, for example.  By default the creating user is assigned admin rights.

Account readers are a special type of contract that get slightly higher rights on the main XDIV token contract.  They get a full list of all current account holders without needing to go through the blockchain to work it out.  This allows things like paying dividends or voting to be a lot easier.

In addition to add and remove methods to allow admins or account readers to be updated this contract provides the ability to check whether an address has had rights at any point in the past.  There are methods provided for this (isCurrentOrPastAdmin / isCurrentOrPastAccountReader) as well as events that are fired whenever authentication rights are changed.

## ICO Phase Management

The ICO Phase Manage contract is the main point of interaction during the ICO.  People send money here and this contract has a special priviledge to mint coins.  It only allows coins to be created during the timeframe specified for the ICO (Aug 1st for 45 days).

Please note there are two ways ether send to the contract is handled and three ways to interact / send ether to this contract.

1. Sending ether to the contract with no specification will mint tokens via the fallback function. The ether sent to the fallback funtion will be sent to a secure hardware wallet address to be converted that day to USD, which will be added to fund's NAV.

2. Sending ether to the contract's holdEther() function will mint tokens and the ether will be sent to an hardware wallet address that will hold the ether until the ICO closes. Once the ICO closes, the ether will be converted to USD and added to the fund's NAV.

3. Sending ether to the contract's cashEther() function works the same way as sending it to the contract's fallback funtion. The ether will be sent to a secure hardware wallet address to be converted that day to USD, which will be added to fund's NAV.

Once the ICO phase finishes (September 15th 2017 00:00 GMT) the ICO can either be closed or abandoned.  Closing an ICO marks to other contracts that we're in the trading phase for the fund and withdraws all the deposited ether to the admin.  Abandoning the ICO results in all the funds being made available to the original investor.  They can access their funds by calling the abandonedFundWithdrawal() method.

## Omni Dividend Fund Token (XDIV)

This is the main ERC-20 compliant token for Omni Dividend Fund.  It is a standard ERC-20 compliant token with a couple of add-ons.

The first difference over a standard ERC-20 token is that XDIV is aware of the ICO Phase Management contract.  It uses this to ensure XDIVs can only be sent when the ICO is over and closed successfully as well as allowing the ICO contract access to a mintTokens() method that only it can call and only during the ICO phase.

The second difference is that an array in addition to a map is created of all account holders.  This is used so that other contracts with account reader priviledges (such as ICO Phase Management and likely future Dividend Manager) have full access to holder information in an easy way.

# Deployment

Once built we deploy the contracts in a specific order:

1. Authentication Manager
2. ICO Phase Management (passing in authentication manager address in constructor)
3. Smart Investment Fund Token (passing in ICO phase management and authentication manager addresses in constructor)

We then perform a couple more post-deploy steps:

4. Add ICO Phase Management as an account reader in Authentication Manager
5. Set the SIFT contract address in the ICO Phase Management contract
6. Set the address for the holdEther() function
7. Set the address for the cashEther() function

# Validation

All our contracts are publicly deployed and their source can be verified by etherscan.  Full details of the deployed contracts can be found below.


| Contract | Address | Source | Validate |
|:---------|:--------|:-------|:---------|
| Authentication Manager | ((INSERT)) | ((INSERT)) | ((INSERT)) |
| ICO Phase Management | ((INSERT)) | ((INSERT)) | ((INSERT)) |
| Smart Investment Fund Token | ((INSERT)) | ((INSERT)) | ((INSERT)) |
| Dividend Manager | ((INSERT)) | ((INSERT)) | ((INSERT)) |
| Transparency Relayer | ((INSERT)) | ((INSERT)) | ((INSERT)) |

All contracts are built against SafeMath which can be found at https://git.io/vQNpw and the code for which is included in the validate links above.
