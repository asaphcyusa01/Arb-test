// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract VendingMachine {
    mapping(address => uint) private cupcakeBalances;
    mapping(address => uint) private lastPurchaseTime;

    function getCupcake() public {
        require(block.timestamp >= lastPurchaseTime[msg.sender] + 5, "Wait 5 seconds between purchases");
        require(cupcakeBalances[msg.sender] == 0, "You already have a cupcake");
        cupcakeBalances[msg.sender]++;
        lastPurchaseTime[msg.sender] = block.timestamp;
    }

    function getBalance() public view returns (uint) {
        return cupcakeBalances[msg.sender];
    }
}
