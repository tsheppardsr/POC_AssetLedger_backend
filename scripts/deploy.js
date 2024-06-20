// deployment script for proxy and main contract Asset Ledger
const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const balance = await deployer.getBalance();
  console.log("Account balance:", balance.toString());

  const AssetLedgerV00_01 = await ethers.getContractFactory(
    "AssetLedgerV00_01"
  );
  const assetLedger = await upgrades.deployProxy(
    AssetLedgerV00_01,
    [deployer.address],
    { initializer: "initialize" }
  );

  await assetLedger.deployed();
  console.log("Proxy contract deployed to address:", assetLedger.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
