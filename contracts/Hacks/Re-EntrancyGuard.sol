// - Ensure all state changes happen before calling external contract
// - Use function modifiers that prevent re-entrancy

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}