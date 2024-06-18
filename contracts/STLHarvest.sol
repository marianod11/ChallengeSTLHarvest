// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract STLHarvest {
    IERC20 public stlToken;
    address public harvestAccount;
    uint public poolIds;
    uint256 public constant PRECISION = 1e12;

    // Structure to store pool information
    struct PoolInfo {
        uint poolId;
        uint256 totalDeposit;
        uint256 totalReward;
        uint256 rewardPerShare;
        mapping(address => UserInfo) userInfo;
    }

    // Structure to store user information
    struct UserInfo {
        uint256 depositAmount;
    }

    mapping(uint => PoolInfo) public poolInfo;
    mapping(address => uint) public userPool;

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

    /**
     * @notice Creates a new pool.
     * @dev Can only be called by the authorized account (onlyHarvestAccount).
     */
    function createPool() external onlyHarvestAccount {
        PoolInfo storage newPool = poolInfo[poolIds];
        newPool.poolId = poolIds;
        poolIds += 1;
        emit CreatePool(newPool.poolId);
    }

    /**
     * @notice Deposits a specific amount of tokens into a pool.
     * @param _poolId The ID of the pool to deposit into.
     * @param _amount The amount of tokens to deposit.
     */
    function deposit(uint _poolId, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(_poolId < poolIds, "Pool does not exist");

        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = pool.userInfo[msg.sender];

        stlToken.transferFrom(msg.sender, address(this), _amount);

        user.depositAmount += _amount;
        pool.totalDeposit += _amount;
        userPool[msg.sender] = _poolId;

        emit Deposit(_poolId, msg.sender, _amount);
    }

    /**
     * @notice Withdraws all deposits and rewards from a pool.
     * @param _poolId The ID of the pool to withdraw from.
     */
    function withdrawAll(uint _poolId) external {
        require(_poolId < poolIds, "Pool does not exist");

        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = pool.userInfo[msg.sender];

        uint256 userDeposit = user.depositAmount;
        require(userDeposit > 0, "Nothing to withdraw");

        uint256 pendingReward = (userDeposit * pool.rewardPerShare) / PRECISION;

        uint256 total = userDeposit + pendingReward;
        stlToken.transfer(msg.sender, total);

        pool.totalDeposit -= userDeposit;
        pool.totalReward -= pendingReward;

        if (pool.totalReward == 0) {
            pool.rewardPerShare = 0;
        }

        user.depositAmount = 0;

        emit Withdraw(_poolId, total);
    }

    /**
     * @notice Withdraws first deposit from a pool.
     * @param _poolId The ID of the pool to withdraw from.
     */
    function withdrawFirsDeposit(uint _poolId) external {
        require(_poolId < poolIds, "Pool does not exist");

        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = pool.userInfo[msg.sender];

        uint256 userDeposit = user.depositAmount;
        require(userDeposit > 0, "Nothing to withdraw");

        stlToken.transfer(msg.sender, userDeposit);

        pool.totalDeposit -= userDeposit;

        user.depositAmount = 0;

        emit Withdraw(_poolId, userDeposit);
    }

    /**
     * @notice Adds rewards to a pool.
     * @param _poolId The ID of the pool to add rewards to.
     * @param _amount The amount of reward tokens to add.
     * @dev Can only be called by the authorized account (onlyHarvestAccount).
     */
    function addRewards(
        uint _poolId,
        uint256 _amount
    ) external onlyHarvestAccount {
        require(_amount > 0, "Amount must be greater than zero");
        require(_poolId < poolIds, "Pool does not exist");

        PoolInfo storage pool = poolInfo[_poolId];

        if (pool.totalDeposit > 0) {
            pool.rewardPerShare += (_amount * PRECISION) / pool.totalDeposit;
        }
        pool.totalReward += _amount;

        stlToken.transferFrom(msg.sender, address(this), _amount);

        emit AddRewards(_poolId, _amount);
    }

    /**
     * @notice Gets information about a specific pool.
     * @param _poolId The ID of the pool to get information for.
     * @return (uint, uint256, uint256, uint256) Returns the pool ID, total deposit, total reward, and reward per share.
     */
    function getPoolInfo(
        uint _poolId
    ) external view returns (uint, uint256, uint256, uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        return (
            pool.poolId,
            pool.totalDeposit,
            pool.totalReward,
            pool.rewardPerShare
        );
    }

    /**
     * @notice Gets information about a specific user in a pool.
     * @return (uint256) Returns the user's deposit amount and reward debt.
     */
    function getUserInfo() external view returns (uint256) {
        PoolInfo storage pool = poolInfo[userPool[msg.sender]];
        UserInfo storage user = pool.userInfo[msg.sender];
        return (user.depositAmount);
    }
}
