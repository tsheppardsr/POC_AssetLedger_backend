// deployment script for proxy and main contract Asset Ledger
const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const balance = await deployer.getBalance();
  console.log("Account balance:", balance.toString());

  // Deploy the main contract
  const AssetLedgerV00_01 = await ethers.getContractFactory(
    "AssetLedgerV00_01"
  );
  const assetLedger = await AssetLedgerV00_01.deploy();
  await assetLedger.deployed();
  console.log("Main contract deployed to address:", assetLedger.address);

  // Deploy the proxy contract
  const AssetLedgerProxyV00_01 = await ethers.getContractFactory(
    "AssetLedgerProxyV00_01"
  );
  console.log("Deploying AssetLedgerProxyV00_01...");
  const proxy = await upgrades.deployProxy(
    AssetLedgerProxyV00_01,
    [assetLedger.address],
    { initializer: "initialize" }
  );
  await proxy.deployed();
  console.log("Proxy contract deployed to address:", proxy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
