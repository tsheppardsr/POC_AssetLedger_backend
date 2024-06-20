const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("AssetLedgerV00_01", function () {
  let AssetLedger, assetLedger, owner, admin, addr1;

  beforeEach(async function () {
    [owner, admin, addr1] = await ethers.getSigners();
    AssetLedger = await ethers.getContractFactory("AssetLedgerV00_01");
    assetLedger = await upgrades.deployProxy(AssetLedger, [owner.address], {
      initializer: "initialize",
    });
    await assetLedger.deployed();
  });

  it("Should set the initial values correctly", async function () {
    const initialRateDepositUSD = ethers.utils.parseUnits("119.17", 18);
    const initialSpreadUSD = ethers.utils.parseUnits("3.47", 18);

    expect(await assetLedger.ledger_Owner()).to.equal(owner.address);
    expect(await assetLedger.rateDepositUSD()).to.equal(initialRateDepositUSD);
    expect(await assetLedger.spreadUSD()).to.equal(initialSpreadUSD);
  });

  it("Should update total deposits and related values", async function () {
    // Setup initial values
    const initialAssets = ethers.utils.parseUnits("1000000", 18);
    await assetLedger
      .connect(owner)
      .changeAssets(initialAssets, initialAssets, initialAssets.mul(2));

    // Perform the test
    await assetLedger
      .connect(owner)
      .changeTotalDeposits(ethers.utils.parseUnits("1000000", 18));
    expect(await assetLedger.depositsTotal()).to.equal(
      ethers.utils.parseUnits("1000000", 18)
    );
  });

  it("Should change rate deposit USD correctly", async function () {
    await assetLedger
      .connect(owner)
      .changeRateDepositUSD(ethers.utils.parseUnits("200.00", 16));
    expect(await assetLedger.rateDepositUSD()).to.equal(
      ethers.utils.parseUnits("200.00", 18)
    );
  });

  it("Should update assets and related values", async function () {
    // Setup initial values
    const initialCuBitInCirculation = ethers.utils.parseUnits("1000", 18);
    await assetLedger
      .connect(owner)
      .changeTotalDeposits(initialCuBitInCirculation);

    // Perform the test
    await assetLedger
      .connect(owner)
      .changeAssets(
        ethers.utils.parseUnits("5000000", 18),
        ethers.utils.parseUnits("5000000", 18),
        ethers.utils.parseUnits("10000000", 18)
      );
    expect(await assetLedger.assetsTotal()).to.equal(
      ethers.utils.parseUnits("10000000", 18)
    );
  });

  it("Should update spread USD and related values", async function () {
    await assetLedger
      .connect(owner)
      .changeSpreadUSD(ethers.utils.parseUnits("4.00", 16));
    const spreadAmount = ethers.utils
      .parseUnits("4.00", 18)
      .mul(await assetLedger.rateDepositUSD())
      .div(ethers.utils.parseUnits("1", 18));
    const expectedRateRedemptionUSD = (await assetLedger.rateDepositUSD()).sub(
      spreadAmount
    );
    expect(await assetLedger.spreadUSD()).to.equal(
      ethers.utils.parseUnits("4.00", 18)
    );
    expect(await assetLedger.rateRedemptionUSD()).to.equal(
      expectedRateRedemptionUSD
    );
  });
});
