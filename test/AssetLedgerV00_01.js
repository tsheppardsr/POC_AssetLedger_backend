const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AssetLedgerV00_01", function () {
    let AssetLedger, assetLedger, owner, admin;

    beforeEach(async function () {
        [owner, admin] = await ethers.getSigners();
        AssetLedger = await ethers.getContractFactory("AssetLedgerV00_01");
        assetLedger = await AssetLedger.deploy();
        await assetLedger.initialize(owner.address);
    });

    it("Should set the initial values correctly", async function () {
        expect(await assetLedger.spreadUSD()).to.equal(ethers.BigNumber.from("347").mul(ethers.BigNumber.from("10").pow(15)));
        expect(await assetLedger.rateDepositUSD()).to.equal(ethers.BigNumber.from("11917").mul(ethers.BigNumber.from("10").pow(16)));
        expect(await assetLedger.inCirculationCuBit()).to.equal(ethers.BigNumber.from("1").mul(ethers.BigNumber.from("10").pow(18)));
        expect(await assetLedger.ledger_supplyCuBit()).to.equal(ethers.BigNumber.from("15000000").mul(ethers.BigNumber.from("10").pow(18)));
        expect(await assetLedger.assetsTotal()).to.equal(ethers.BigNumber.from("11917").mul(ethers.BigNumber.from("10").pow(16)));
        expect(await assetLedger.assetsLA()).to.equal(ethers.BigNumber.from("11917").mul(ethers.BigNumber.from("10").pow(16)));
        expect(await assetLedger.ratioLA()).to.equal(ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(16)));
        expect(await assetLedger.depositsTotal()).to.equal(ethers.BigNumber.from("11917").mul(ethers.BigNumber.from("10").pow(16)));
        expect(await assetLedger.valueCuBit()).to.equal(ethers.BigNumber.from("11917").mul(ethers.BigNumber.from("10").pow(16)));
        expect(await assetLedger.ledger_mintLimit()).to.equal(ethers.BigNumber.from("500000000").mul(ethers.BigNumber.from("10").pow(18)));
    });

    it("Should update total deposits and related values", async function () {
        await assetLedger.connect(owner).changeTotalDeposits(ethers.BigNumber.from("839").mul(ethers.BigNumber.from("10").pow(18)));
        expect(await assetLedger.depositsTotal()).to.equal(ethers.BigNumber.from("839").mul(ethers.BigNumber.from("10").pow(18)));
        expect(await assetLedger.inCirculationCuBit()).to.be.above(0);
    });

    it("Should change rate deposit USD correctly", async function () {
        await assetLedger.connect(owner).changeRateDepositUSD(ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(18)));
        expect(await assetLedger.rateDepositUSD()).to.equal(ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(18)));
    });

    it("Should update spread USD and related values", async function () {
        await assetLedger.connect(owner).changeSpreadUSD(ethers.BigNumber.from("400").mul(ethers.BigNumber.from("10").pow(15)));
        expect(await assetLedger.spreadUSD()).to.equal(ethers.BigNumber.from("400").mul(ethers.BigNumber.from("10").pow(15)));
    });
});


  it("Should update spread USD and related values", async function () {
    await assetLedger
      .connect(owner)
      .changeSpreadUSD(
        ethers.BigNumber.from("400").mul(ethers.BigNumber.from("10").pow(15))
      );
    expect(await assetLedger.spreadUSD()).to.equal(
      ethers.BigNumber.from("400").mul(ethers.BigNumber.from("10").pow(15))
    );
  });
});
