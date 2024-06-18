// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract STLHarvest1 {
    IERC20 public stlToken;
    address harvestAccount;
    uint public poolIds;

    struct PoolInfo {
        uint poolId;
        uint256 totalDeposit;
        uint256 totalReward;
        address[] users;
        mapping(address => UserInfo) userInfo;
    }

    struct UserInfo {
        uint256 depositAmount;
        uint256 rewardDebt;
    }

    mapping(uint => PoolInfo) public poolInfo;

    event CreatePool(uint poolId);
    event Deposit(uint poolId, address user, uint256 amount);
    event AddRewards(uint poolId, uint256 amount);
    event Withdraw(uint poolId, uint256 amount);

    modifier onlyHarvestAccount() {
        require(msg.sender == harvestAccount, "Not harvestAccount");
        _;
    }

    constructor(address _stlToken, address _harvestAccount) {
        require(
            _stlToken != address(0) && _harvestAccount != address(0),
            "Not address zero"
        );
        stlToken = IERC20(_stlToken);
        harvestAccount = _harvestAccount;
    }

    function createPool() external onlyHarvestAccount {
        PoolInfo storage newPool = poolInfo[poolIds];
        newPool.poolId = poolIds;
        poolIds += 1;
        emit CreatePool(newPool.poolId);
    }

    function deposit(uint _poolId, uint256 _amount) external {
        require(_amount > 0, "Not zero");
        require(_poolId <= poolIds, "Not exist pool");
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = pool.userInfo[msg.sender];

        stlToken.transferFrom(msg.sender, address(this), _amount);

        if (user.depositAmount == 0) {
            pool.users.push(msg.sender);
        }

        user.depositAmount += _amount;
        pool.totalDeposit += _amount;

        emit Deposit(_poolId, msg.sender, _amount);
    }

    function withdrawAll(uint _poolId) external {
        require(_poolId <= poolIds, "Not exist pool");
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = pool.userInfo[msg.sender];

        uint256 total = user.depositAmount + user.rewardDebt;
        require(total > 0, "Nothing Balance");

        stlToken.transfer(msg.sender, total);

        pool.totalDeposit -= user.depositAmount;
        user.depositAmount = 0;
        user.rewardDebt = 0;

        for (uint i = 0; i < pool.users.length; i++) {
            if (pool.users[i] == msg.sender) {
                pool.users[i] = pool.users[pool.users.length - 1];
                pool.users.pop();
                break;
            }
        }

        emit Withdraw(_poolId, total);
    }

    function addRewards(
        uint _poolId,
        uint256 _amount
    ) external onlyHarvestAccount {
        require(_amount > 0, "Amount must be greater than zero");
        require(_poolId <= poolIds, "Not exist pool");
        PoolInfo storage pool = poolInfo[_poolId];

        for (uint i = 0; i < pool.users.length; i++) {
            UserInfo storage user = pool.userInfo[pool.users[i]];
            uint256 rewardShare = (user.depositAmount * _amount) /
                pool.totalDeposit;
            user.rewardDebt += rewardShare;
        }

        pool.totalReward = _amount;

        stlToken.transferFrom(msg.sender, address(this), _amount);

        emit AddRewards(_poolId, _amount);
    }

    function getPoolInfo(
        uint _poolId
    ) external view returns (uint, uint256, uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        return (pool.poolId, pool.totalDeposit, pool.totalReward);
    }

    function getUserInfo(
        uint _poolId
    ) external view returns (uint256, uint256, uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = pool.userInfo[msg.sender];
        return (_poolId, user.depositAmount, user.rewardDebt);
    }
}
