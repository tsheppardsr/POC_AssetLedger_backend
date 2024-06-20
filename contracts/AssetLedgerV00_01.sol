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
import "@openzeppelin/hardhat-upgrades/contracts-upgradeable/utils/SafeMathUpgradeable.sol";

// Enum declaration for Ledger State
enum LedgerState {
    Transition,
    LAOut,
    REOut,
    Stable
}

contract AssetLedgerV00_01 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public constant DECIMALS = 10**18;
    LedgerState public ledgerState;

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

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == ledger_Owner || msg.sender == ledger_Admin, "Not authorized");
        _;
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        ledger_Owner = initialOwner;
        ledger_supplyCuBit = 15000000e18;
        inReservesCuBit = ledger_supplyCuBit;
        inCirculationCuBit = 0;
        assetsTotal = 0;
        assetsLA = 0;
        assetsRE = 0;
        ratioLA = 0;
        ratioRE = 0;
        depositsTotal = 0;
        valueCuBit = 1e18;
        ledger_nameAdmin = "UREWPS, LLC";
        ledger_nameOwner = "CuBitDAO, LLC";
        ledger_contactAdmin = "UREWPS.com";
        ledger_mintLimit = 500000000e18;
        rateDepositUSD = 11917e16;
        spreadUSD = 347e16;

        // Debugging logs
        require(spreadUSD > 0, "SpreadUSD must be greater than zero");
        require(rateDepositUSD > 0, "RateDepositUSD must be greater than zero");

        uint256 spreadAmount = spreadUSD.mul(rateDepositUSD).div(DECIMALS);
        require(rateDepositUSD >= spreadAmount, "RateDepositUSD must be greater than spread amount");

        rateRedemptionUSD = rateDepositUSD.sub(spreadAmount);
        require (rateRedemptionUSD > 0, "RateRedemptionUSD must be greater than zero");
        require (rateRedemptionUSD < rateDepositUSD, "RateRedemptionUSD must be less than RateDepositUSD");
        ledgerState = LedgerState.Transition;

        // Debugging logs
        emit SpreadUSDChanged(spreadUSD, rateRedemptionUSD);
        emit TotalDepositsChanged(depositsTotal, inCirculationCuBit, inReservesCuBit, valueCuBit);
    }

    function isEmpty(string memory str) internal pure returns (bool) {
        bytes memory bytesStr = bytes(str);
        return bytesStr.length == 0;
    }

    function changeDateUpdated() internal {
        dateUpdated = block.timestamp;
    }

    function changeValueCuBit() internal returns (bool) {
        require(assetsTotal != 0, "Total Assets cannot be zero");
        require(inCirculationCuBit != 0, "CuBit in circulation cannot be zero");

        valueCuBit = assetsTotal.div(inCirculationCuBit);

        changeRateDepositUSD(uint256 rateDepositUSD);
        emit ValueChanged(rateDepositUSD);
        return true;
    }

    function changeRateDepositUSD(uint256 _rateDepositUSD) internal returns (bool) {
        rateDepositUSD = _rateDepositUSD.mul(DECIMALS);
        uint256 spreadAmount = rateDepositUSD.mul(spreadUSD).div(DECIMALS);
        rateRedemptionUSD = rateDepositUSD.sub(spreadAmount);
        changeDateUpdated();
        emit RateDepositUSDChanged(rateDepositUSD, rateRedemptionUSD);
        return true;
    }

    function changeTotalDeposits(uint256 newDeposits) public onlyOwnerOrAdmin returns (bool) {
        require(newDeposits >= 0, "Invalid Deposits value");
        depositsTotal = newDeposits;
        inCirculationCuBit = depositsTotal.div(rateDepositUSD);
        inReservesCuBit = ledger_supplyCuBit.sub(inCirculationCuBit);
        changeValueCuBit();
        changeDateUpdated();
        emit TotalDepositsChanged(depositsTotal, inCirculationCuBit, inReservesCuBit, valueCuBit);
        return true;
    }

    function changeAssets(uint256 newAssetsLA, uint256 newAssetsRE, uint256 newAssetsTotal) public onlyOwnerOrAdmin returns (bool) {
        require(newAssetsTotal >= 0, "Total Assets must be > zero");
        require(newAssetsLA >= 0, "LA Assets must be > zero");
        require(newAssetsTotal == newAssetsLA.add(newAssetsRE), "Sum of RE and LA assets must equal Total Assets");
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

    function calculateRatio(uint256 assetAmount, uint256 totalAssets) internal pure returns (uint256) {
        require(totalAssets > 0, "Total assets must be greater than zero");
        require(assetAmount <= totalAssets, "Assets in ratio cannot exceed total assets");
        return assetAmount.mul(DECIMALS).div(totalAssets);
    }

    function changeSpreadUSD(uint256 newSpread) public onlyOwnerOrAdmin returns (bool) {
        require(newSpread > 0, "Spread amount must be greater than zero");
        spreadUSD = newSpread;
        uint256 spreadAmount = (rateDepositUSD.mul(spreadUSD)).div(DECIMALS);
        rateRedemptionUSD = rateDepositUSD.sub(spreadAmount);
        changeDateUpdated();
        emit SpreadUSDChanged(spreadUSD, rateRedemptionUSD);
        return true;
    }

    function changeProposal(bool newProposalPresent, string memory newProposalLocation, uint256 newProposalDate) public onlyOwnerOrAdmin returns (bool) {
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
        return true;
    }

    function changeAudit(uint256 newDateLastAudit, string memory newLocationLastAudit, string memory newAuditor) public onlyOwnerOrAdmin returns (bool) {
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
        return true;
    }

    function changeContactAdmin(string memory newContactAdmin) public onlyOwnerOrAdmin returns (bool) {
        require(!isEmpty(newContactAdmin), "Contact Admin cannot be empty");
        ledger_contactAdmin = newContactAdmin;
        changeDateUpdated();
        emit ContactAdminChanged(ledger_contactAdmin);
        return true;
    }

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

    function _authorizeUpgrade(address newImplementation) internal override onlyOwnerOrAdmin {}

    function updateSupplyCuBit(uint256 totalSupply) public {
        ledger_supplyCuBit = totalSupply;
        emit SupplyCuBitUpdated(ledger_supplyCuBit);
    }

    function getLedgerState() public view returns (LedgerState) {
        return ledgerState;
    }
}