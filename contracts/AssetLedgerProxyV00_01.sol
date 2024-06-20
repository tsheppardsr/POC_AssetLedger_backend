// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// CuBitDAO Asset Ledger Proxy Contract
// Author Sudato M O'Benshee w/ assistance from ChatGPT and OpenZeppelin library support
// Version 2.0.0x
// This contract enables the public display and ADMIN or OWNER update of the CuBitDAO Asset Ledger
// This contract performs almost no calculations. Substantive calculations should be done off-chain and uploaded to the Ledger.
// The decision to allow off-chain calculations was made by the DAO and Admin in 2024. This makes the contract more secure.
// version x temporarily removes interactions with any other contracts 
// version x also sets the ledger state to Transition
// version x also fixes the USD Deposit rate at 119.17 USD per CuBit

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AssetLedgerProxyV00_01 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address private _assetLedger;

    function initialize(address assetLedger) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        _assetLedger = assetLedger;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _upgradeTo(address newImplementation) internal {
        _authorizeUpgrade(newImplementation);
        _assetLedger = newImplementation;
    }

    function _implementation() internal view returns (address) {
        return _assetLedger;
    }

    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    fallback() external payable {
        _delegate(_assetLedger);
    }

    receive() external payable {
        _delegate(_assetLedger);
    }
}
