// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract LiquidityMining {
    uint256 public totalStaked;
    ERC20 public token;
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public rewardsBalances;
    uint256 public constant DURATION = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _token) {
        token = ERC20(_token);
        lastUpdateTime = block.timestamp;
    }

    function stake(uint256 _amount) external {
        updateReward(msg.sender);
        require(_amount > 0, "Cannot stake 0");
        totalStaked += _amount;
        stakedBalances[msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        updateReward(msg.sender);
        require(_amount > 0, "Cannot withdraw 0");
        require(stakedBalances[msg.sender] >= _amount, "Insufficient balance");
        totalStaked -= _amount;
        stakedBalances[msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function claimReward() external {
        updateReward(msg.sender);
        require(rewardsBalances[msg.sender] > 0, "No rewards to claim");
        uint256 reward = rewardsBalances[msg.sender];
        rewardsBalances[msg.sender] = 0;
        token.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function updateReward(address _user) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_user != address(0)) {
            rewardsBalances[_user] = earned(_user);
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < (lastUpdateTime + DURATION) ? block.timestamp : (lastUpdateTime + DURATION);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return (rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalStaked);
    }

    function earned(address _user) public view returns (uint256) {
        return ((stakedBalances[_user] * (rewardPerToken() - rewardPerTokenStored)) / 1e18) + rewardsBalances[_user];
    }

    function startMining(uint256 _reward) external {
        require(_reward > 0, "Cannot start with zero reward");
        require(block.timestamp >= lastUpdateTime + DURATION, "Mining has not ended yet");
        updateReward(address(0));
        rewardRate = _reward / DURATION;
        lastUpdateTime = block.timestamp;
    }
}