const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AssetLedgerV00_01", function () {
  async function deployAssetLedgerFixture() {
    const [owner, admin] = await ethers.getSigners();

    const AssetLedger = await ethers.getContractFactory("AssetLedgerV00_01");
    const assetLedger = await AssetLedger.deploy();
    await assetLedger.deployed();

    return { assetLedger, owner, admin };
  }

  describe("Deployment", function () {
    it("Should set the initial values correctly", async function () {
      const { assetLedger, owner } = await deployAssetLedgerFixture();

      expect(await assetLedger.valueCuBit()).to.equal(
        ethers.utils.parseUnits("1", 18)
      );
      expect(await assetLedger.ledger_nameAdmin()).to.equal("UREWPS, LLC");
      expect(await assetLedger.ledger_nameOwner()).to.equal("CuBitDAO, LLC");
      expect(await assetLedger.rateDepositUSD()).to.equal(
        ethers.utils.parseUnits("119.17", 16)
      );
      expect(await assetLedger.ledger_Owner()).to.equal(owner.address);
    });
  });

  describe("Change Total Deposits", function () {
    it("Should update total deposits and related values", async function () {
      const { assetLedger, owner } = await deployAssetLedgerFixture();

      await assetLedger.changeTotalDeposits(
        ethers.utils.parseUnits("1000", 18),
        { from: owner.address }
      );

      const depositsTotal = await assetLedger.depositsTotal();
      expect(depositsTotal).to.equal(ethers.utils.parseUnits("1000", 18));

      const inCirculationCuBit = await assetLedger.inCirculationCuBit();
      expect(inCirculationCuBit).to.be.gt(0);

      const inReservesCuBit = await assetLedger.inReservesCuBit();
      expect(inReservesCuBit).to.be.lt(await assetLedger.ledger_supplyCuBit());
    });
  });

  describe("Change Assets", function () {
    it("Should update assets and related values", async function () {
      const { assetLedger, owner } = await deployAssetLedgerFixture();

      await assetLedger.changeAssets(
        ethers.utils.parseUnits("500", 18),
        ethers.utils.parseUnits("500", 18),
        ethers.utils.parseUnits("1000", 18),
        { from: owner.address }
      );

      const assetsTotal = await assetLedger.assetsTotal();
      expect(assetsTotal).to.equal(ethers.utils.parseUnits("1000", 18));

      const ratioLA = await assetLedger.ratioLA();
      expect(ratioLA).to.equal(ethers.utils.parseUnits("0.5", 18));

      const ratioRE = await assetLedger.ratioRE();
      expect(ratioRE).to.equal(ethers.utils.parseUnits("0.5", 18));
    });
  });

  describe("Change Spread USD", function () {
    it("Should update spread USD and related values", async function () {
      const { assetLedger, owner } = await deployAssetLedgerFixture();

      await assetLedger.changeSpreadUSD(ethers.utils.parseUnits("0.04", 18), {
        from: owner.address,
      });

      const spreadUSD = await assetLedger.spreadUSD();
      expect(spreadUSD).to.equal(ethers.utils.parseUnits("0.04", 18));

      const rateDepositUSD = await assetLedger.rateDepositUSD();
      const rateRedemptionUSD = await assetLedger.rateRedemptionUSD();

      const expectedSpreadAmount = rateDepositUSD
        .mul(spreadUSD)
        .div(ethers.utils.parseUnits("1", 18));
      const expectedRateRedemptionUSD =
        rateDepositUSD.sub(expectedSpreadAmount);

      expect(rateRedemptionUSD).to.equal(expectedRateRedemptionUSD);
    });
  });
});
