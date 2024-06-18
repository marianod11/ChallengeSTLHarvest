# STL Harvest Contract

This project is part of a challenge. The project is based on the deposit of the STL token in the pool, and the manual addition of rewards for the users. Depending on their share in the pool, the respective amount of reward tokens will be allocated to them.

## Introduction

The `STLHarvest` contract allows users to deposit STL tokens and receive rewards based on their participation in the pool.

In this contract, the distribution of the tokens is managed by the `rewardPerShare` variable, which stores the value of each token based on the total deposits in the pool.

## Usage

`npm install`
`npx hardhat test` => Running this command, you will see how the two scenarios proposed in the challenge are carried out.

`npx hardhat script/STLTokenBalance.task.js`=> Running this command you can see the balance of the contract in the test-net.

## Structure

├── contracts
│ ├── STLHarvest1.sol # The main contract
│ └── STLToken.sol # The STL token contract
├── scripts
│ └── STLTokenBalance.task.js # Script to check the token balance on the test-net
├── test
│ └── STLHarvest1.test.js # Contract tests
├── hardhat.config.js # Hardhat configuration
├── package.json # Project dependencies
└── README.md # This documentation file


Mariano Dell Aquila