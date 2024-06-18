const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

async function main() {
  const [harvestAccount] = await ethers.getSigners();

  const STLToken = await ethers.getContractFactory("STL");
  const sltToken = await STLToken.deploy(harvestAccount.address);

  const STLHarvest = await ethers.getContractFactory("STLHarvest");
  const stlHarvest = await STLHarvest.deploy(
    sltToken.target,
    harvestAccount.address
  );

  await sltToken.approve(stlHarvest.target, ethers.parseEther("1000"));
  await sltToken.transfer(stlHarvest.target, ethers.parseEther("1000"));

  const balance = await sltToken.balanceOf(stlHarvest.target);

  console.log(
    `The total amount of STL tokens in the contract: ${ethers.formatEther(
      balance
    )} STL`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
