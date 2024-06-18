const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("STLHarvest", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [harvestAccount, aliceAccount, bobAccount] =
      await ethers.getSigners();

    //Deploy token
    const STLToken = await ethers.getContractFactory("STL");
    const sltToken = await STLToken.deploy(harvestAccount.address);
    //Deploy STLHarvest
    const STLHarvest = await ethers.getContractFactory("STLHarvest");
    const stlHarvest = await STLHarvest.deploy(
      sltToken.target,
      harvestAccount.address
    );

    await sltToken.transfer(aliceAccount.address, ethers.parseEther("1000"));
    await sltToken.transfer(bobAccount.address, ethers.parseEther("1000"));

    //approve stlHarvestContract harvestOwner
    await sltToken
      .connect(harvestAccount)
      .approve(stlHarvest.target, ethers.parseEther("1000"));
    //approve stlHarvestContract alice
    await sltToken
      .connect(aliceAccount)
      .approve(stlHarvest.target, ethers.parseEther("1000"));
    //approve stlHarvestContract bob
    await sltToken
      .connect(bobAccount)
      .approve(stlHarvest.target, ethers.parseEther("1000"));

    return { stlHarvest, sltToken, harvestAccount, aliceAccount, bobAccount };
  }

  describe("Deployment", function () {
    it("First scenario", async function () {
      const { stlHarvest, harvestAccount, aliceAccount, bobAccount } =
        await loadFixture(deployOneYearLockFixture);

      //create pool harvestOwner
      await stlHarvest.connect(harvestAccount).createPool();

      //deposit alice
      await stlHarvest
        .connect(aliceAccount)
        .deposit(0, ethers.parseEther("100"));

      //deposit bob
      await stlHarvest.connect(bobAccount).deposit(0, ethers.parseEther("300"));

      //add rewards
      await stlHarvest
        .connect(harvestAccount)
        .addRewards(0, ethers.parseEther("200"));

      //withdraw alice
      const withdrawAlice = await stlHarvest
        .connect(aliceAccount)
        .withdrawAll(0);
      const withdrawAliceWait = await withdrawAlice.wait();
      let balanceSTL;

      withdrawAliceWait.logs.forEach((log) => {
        if (log.args && log.args.length > 1) {
          const valorWei = log.args[1];
          balanceSTL = ethers.formatEther(valorWei.toString());
        }
      });

      // expect result event withdraw Alice with solicit challeng
      expect(balanceSTL).to.equal("150.0");

      //withdraw bob
      const withdrawBob = await stlHarvest.connect(bobAccount).withdrawAll(0);
      const withdrawBobeWait = await withdrawBob.wait();

      withdrawBobeWait.logs.forEach((log) => {
        if (log.args && log.args.length > 1) {
          const valorWei = log.args[1];
          balanceSTL = ethers.formatEther(valorWei.toString());
        }
      });

      //expect result event withdraw Bob with solicit challeng
      expect(balanceSTL).to.equal("450.0");
    });

    it("Second scenario", async function () {
      const { stlHarvest, harvestAccount, aliceAccount, bobAccount } =
        await loadFixture(deployOneYearLockFixture);

      //create pool harvest owner
      await stlHarvest.connect(harvestAccount).createPool();

      // deposit alice
      await stlHarvest
        .connect(aliceAccount)
        .deposit(0, ethers.parseEther("100"));

      //add rewards harvestOwner
      await stlHarvest
        .connect(harvestAccount)
        .addRewards(0, ethers.parseEther("200"));

      //deposit bob
      await stlHarvest.connect(bobAccount).deposit(0, ethers.parseEther("300"));

      //withdraw alice
      const withdrawAlice = await stlHarvest
        .connect(aliceAccount)
        .withdrawAll(0);
      const withdrawAliceWait = await withdrawAlice.wait();
      let balanceSTL;

      withdrawAliceWait.logs.forEach((log) => {
        if (log.args && log.args.length > 1) {
          const valorWei = log.args[1];
          balanceSTL = ethers.formatEther(valorWei.toString());
        }
      });

      // expect result event withdraw Alice with solicit challeng
      expect(balanceSTL).to.equal("300.0");

      //withdraw bob
      const withdrawBob = await stlHarvest.connect(bobAccount).withdrawAll(0);
      const withdrawBobeWait = await withdrawBob.wait();

      withdrawBobeWait.logs.forEach((log) => {
        if (log.args && log.args.length > 1) {
          const valorWei = log.args[1];
          balanceSTL = ethers.formatEther(valorWei.toString());
        }
      });

      //expect result event withdraw Bob with solicit challeng
      expect(balanceSTL).to.equal("300.0");
    });
  });
});
