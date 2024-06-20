// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// CuBitDAO Asset Ledger
// Author Sudato M O'Benshee w/ assistance from ChatGPT and OpenZeppelin library support
// Version 2.0.0x
// This contract enables the public display and ADMIN or OWNER update of the CuBitDAO Asset Ledger
// This contract performs almost no calculations. Substantive calculations should be done off-chain and uploaded to the Ledger.
// The decision to allow off-chain calculations was made by the DAO and Admin in 2024. This makes the contract more secure.
// version x temporarily removes interactions with any other contracts 
// version x also sets the ledger state to Transition
// version x also fixes the USD Deposit rate at 119.17 USD per CuBit

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Enum declaration for Ledger State
enum LedgerState {
    Transition, // zero
    LAOut,      // one
    REOut,      // two
    Stable      // three      
    // Add more states if needed
}

contract AssetLedgerV00_01 is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    // data structures

    // Constants
    uint256 public constant DECIMALS = 10**18; // Number of decimal places
    LedgerState public ledgerState;
    
    // State Variables
    address public ledger_Owner;
    address public ledger_Admin;
    string public ledger_nameAdmin;
    string public ledger_nameOwner;
    string public ledger_contactAdmin;
    uint256 public ledger_mintLimit;
    uint256 public valueCuBit;
    uint256 public inCirculationCuBit;
    uint256 public inReservesCuBit;
    uint256 public ledger_supplyCuBit;
    uint256 public dateUpdated;
    uint256 public dateLastAudit;
    string public locationLastAudit;
    string public nameAuditor;
    bool public proposalPresent;
    uint256 public proposalDate;
    string public proposalLocation;
    string public stringLedgerState;
    uint256 public assetsRE;
    uint256 public assetsLA;
    uint256 public assetsTotal;
    uint256 public depositsTotal;
    uint256 public ratioRE;
    uint256 public ratioLA;
    uint256 public rateDepositUSD;
    uint256 public rateRedemptionUSD;
    uint256 public spreadUSD;

    // Events
    event ValueChanged(uint256 newValue);
    event RateDepositUSDChanged(uint256 newRateDepositUSD, uint256 newRateRedemptionUSD);
    event LedgerStateChanged(LedgerState newState, string newStateString);
    event TotalDepositsChanged(uint256 newDepositsTotal, uint256 newInCirculationCuBit, uint256 newInReservesCuBit, uint256 newValueCuBit);
    event AssetsChanged(uint256 newAssetsTotal, uint256 newAssetsLA, uint256 newRatioLA, uint256 newAssetsRE, uint256 newRatioRE, uint256 newValueCuBit);
    event ProposalPresentChanged(bool newProposalPresent, string newProposalLocation, uint256 newProposalDate);
    event LocationLastAuditChanged(uint256 newDateLastAudit, string newLocationLastAudit);
    event ContactAdminChanged(string newContactAdmin);
    event SpreadUSDChanged(uint256 newSpread, uint256 rateRedemptionUSD);
    event SupplyCuBitUpdated(uint256 newSupply);

    // Modifiers
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == ledger_Owner || msg.sender == ledger_Admin, "Not authorized");
        _;
    }

    // Initialize the contract
    function initialize() public initializer {
        ledger_supplyCuBit = 15000000e18; // supply from the coin  
        inReservesCuBit = ledger_supplyCuBit; // all coins are in reserves
        inCirculationCuBit = 0; // no coins are in circulation
        assetsTotal = 0; // no assets
        assetsLA = 0; // no liquid assets
        assetsRE = 0; // no real estate assets
        ratioLA = 0; // no liquid assets
        ratioRE = 0; // no real estate assets
        depositsTotal = 0; // no deposits
        valueCuBit = 1e18; // value of 1 CuBit
        ledger_nameAdmin = "UREWPS, LLC";
        ledger_nameOwner = "CuBitDAO, LLC";
        ledger_contactAdmin = "UREWPS.com";
        ledger_mintLimit = 500000000e18; 
        rateDepositUSD = 11917e16; // 119.17 with 18 decimal places precision
        spreadUSD = 347e16; // 3.47% with 18 decimal places precision
        rateRedemptionUSD = rateDepositUSD - (spreadUSD * rateDepositUSD / DECIMALS); // USD received when redeeming 1 CuBit
        ledgerState = LedgerState.Transition;  // initialize as Transition
    }
    
    // Check for empty string
    function isEmpty(string memory str) internal pure returns (bool) {
        bytes memory bytesStr = bytes(str);
        return bytesStr.length == 0;
    }

    // Function to update dateUpdated to the current timestamp
    function changeDateUpdated() internal {
        dateUpdated = block.timestamp;
    }

    // Change value of CuBit routine is called when assets or circulation change
    function changeValueCuBit() internal returns (bool) {
        require(assetsTotal != 0, "Total Assets cannot be zero");
        require(inCirculationCuBit != 0, "CuBit in circulation cannot be zero");

        // Calculate new CuBit value
        valueCuBit = assetsTotal / inCirculationCuBit; 

        // Changes in value of CuBit require changes in the exchange rates
        changeRateDepositUSD();
        emit ValueChanged(valueCuBit);
        return true; // Indicate successful execution
    }

    // Update the rateDepositUSD and rateRedemptionUSD based on the current assetsTotal and inCirculationCuBit
    function changeRateDepositUSD() internal returns (bool) {
        rateDepositUSD = valueCuBit; 
        uint256 spreadAmount = rateDepositUSD * spreadUSD / DECIMALS;
        rateRedemptionUSD = rateDepositUSD - spreadAmount; // USD received when redeeming 1 CuBit
        changeDateUpdated();
        emit RateDepositUSDChanged(rateDepositUSD, rateRedemptionUSD);
        return true; // Indicate successful execution
    }

    // Change total deposits alters the CuBit in Circulation which, in turn,
    // alters the value of CuBit, deposits rate, and redemption rate
    function changeTotalDeposits(uint256 newDeposits) public onlyOwnerOrAdmin returns (bool) {
        require(newDeposits >= 0, "Invalid Deposits value");
        depositsTotal = newDeposits;
        inCirculationCuBit = depositsTotal / rateDepositUSD;
        inReservesCuBit = ledger_supplyCuBit - inCirculationCuBit;
        changeValueCuBit();
        changeDateUpdated();
        emit TotalDepositsChanged(depositsTotal, inCirculationCuBit, inReservesCuBit, valueCuBit);
        return true; // Indicate successful execution
    }

    // Change assets combined
    function changeAssets(uint256 newAssetsLA, uint256 newAssetsRE, uint256 newAssetsTotal) 
    public onlyOwnerOrAdmin returns (bool) {
        require(newAssetsTotal >= 0, "Total Assets must be > zero");
        require(newAssetsLA >= 0, "LA Assets must be > zero");
        require(newAssetsTotal == newAssetsLA + newAssetsRE, "Sum of RE and LA assets must equal Total Assets");
        assetsTotal = newAssetsTotal;
        assetsLA = newAssetsLA; 
        ratioLA = calculateRatio(assetsLA, assetsTotal);

        if (newAssetsRE > 0) {
            assetsRE = newAssetsRE;
            ratioRE = calculateRatio(assetsRE, assetsTotal);
        } else {
            ratioRE = 0;
        }
        changeValueCuBit();
        changeDateUpdated();
        emit AssetsChanged(assetsTotal, assetsLA, ratioLA, assetsRE, ratioRE, valueCuBit);
        return true;
    }

    // Function to calculate asset ratio
    function calculateRatio(uint256 assetAmount, uint256 totalAssets) internal pure returns (uint256) {
        require(totalAssets > 0, "Total assets must be greater than zero");
        require(assetAmount <= totalAssets, "Assets in ratio cannot exceed total assets");
        return (assetAmount * DECIMALS) / totalAssets;
    }

    // Updates the USD spread value used for USD deposits and redemptions
    function changeSpreadUSD(uint256 newSpread) public onlyOwnerOrAdmin returns (bool) {
        require(newSpread > 0, "Spread amount must be greater than zero");
        spreadUSD = newSpread;
        uint256 spreadAmount = (rateDepositUSD * spreadUSD) / DECIMALS;
        rateRedemptionUSD = rateDepositUSD - spreadAmount; // USD received when redeeming 1 CuBit
        changeDateUpdated();
        emit SpreadUSDChanged(spreadUSD, rateRedemptionUSD);
        return true; // Indicate successful execution
    }

    // Functions to modify proposal information
    function changeProposal(bool newProposalPresent, string memory newProposalLocation, uint256 newProposalDate) 
    public onlyOwnerOrAdmin returns (bool) {
        if (!newProposalPresent) {
            proposalPresent = false;
            proposalLocation = "";
            proposalDate = 0;
        } else {
            require(newProposalDate >= proposalDate, "New proposal date cannot be older than current proposal date");
            proposalDate = newProposalDate;
            require(bytes(newProposalLocation).length > 0, "Proposal location cannot be empty");
            proposalLocation = newProposalLocation;
        }
        changeDateUpdated();
        emit ProposalPresentChanged(proposalPresent, proposalLocation, proposalDate);
        return true; // Indicate successful execution
    }

    // Functions to modify audit information
    function changeAudit(uint256 newDateLastAudit, string memory newLocationLastAudit, string memory newAuditor) 
    public onlyOwnerOrAdmin returns (bool) {
        require(newDateLastAudit > 0, "New audit date cannot be empty");
        require(newDateLastAudit >= dateLastAudit, "New audit date cannot be older than the last audit.");
        dateLastAudit = newDateLastAudit;

        if (!isEmpty(newLocationLastAudit)) {
            locationLastAudit = newLocationLastAudit;   
        }     

        if (!isEmpty(newAuditor)) {
            nameAuditor = newAuditor;
        }
        changeDateUpdated();
        emit LocationLastAuditChanged(dateLastAudit, locationLastAudit);
        return true; // Indicate successful execution
    }

    // Function to change the contact admin
    function changeContactAdmin(string memory newContactAdmin) public onlyOwnerOrAdmin returns (bool) {
        require(!isEmpty(newContactAdmin), "Contact Admin cannot be empty");
        ledger_contactAdmin = newContactAdmin;
        changeDateUpdated();
        emit ContactAdminChanged(ledger_contactAdmin);
        return true; // Indicate successful execution
    }

    // Functions to view the Ledger in parts
    function viewLedgerPart1() public view returns (
        string memory, string memory, string memory, uint256,
        uint256, uint256, uint256, uint256
    ) {
        return (
            ledger_nameAdmin, ledger_nameOwner, ledger_contactAdmin, dateUpdated, 
            ledger_mintLimit, valueCuBit, inCirculationCuBit, inReservesCuBit
        );
    }

    function viewLedgerPart2() public view returns (
        uint256, uint256, string memory, string memory,
        bool, uint256, string memory
    ) {
        return (
            ledger_supplyCuBit, dateLastAudit, locationLastAudit, nameAuditor,
            proposalPresent, proposalDate, proposalLocation
        );
    }

    function viewLedgerPart3() public view returns (
        LedgerState, uint256, uint256,
        uint256, uint256,
        uint256, uint256,
        uint256, uint256, uint256 
    ) {
        return (
            ledgerState, assetsRE, assetsLA,
            assetsTotal, depositsTotal, 
            ratioRE, ratioLA,
            rateDepositUSD, rateRedemptionUSD, spreadUSD 
        );
    }

    // Authorization function    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwnerOrAdmin  {
    }

    // Function to update ledger_supplyCuBit from CuBitTokenv01.sol
    function updateSupplyCuBit(uint256 totalSupply) public {
        ledger_supplyCuBit = totalSupply;
        emit SupplyCuBitUpdated(ledger_supplyCuBit);
    }
    
    // inserted during testing
    function setOwner(address newOwner) public onlyOwnerOrAdmin {
        ledger_Owner = newOwner;
    }
    
    function getLedgerState() public view returns (LedgerState) {
        return ledgerState;
    }
}

