// in solidity any address can be casted into specific contract, even if the contract at the address is not the one being casted
// this can be exploited to hide malicious code

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

/*
Let's say Alice can see the code of Foo and Bar but not Mal.
It is obvious to Alice that Foo.callBar() executes the code inside Bar.log().
However Eve deploys Foo with the address of Mal, so that calling Foo.callBar()
will actually execute the code at Mal.
*/

/*
1. Eve deploys Mal
2. Eve deploys Foo with the address of Mal
3. Alice calls Foo.callBar() after reading the code and judging that it is
   safe to call.
4. Although Alice expected Bar.log() to be execute, Mal.log() was executed.
*/

// preventative techniques
// - initialize a new contract inside the constructor
// - make the address of external contract public so that the code of the external contract can be reviewed

contract Foo {
    Bar bar;

    constructor(address _bar) {
        bar = Bar(_bar);
    }

    function callBar() public {
        bar.log();
    }
}

contract Bar {
    event Log(string message);

    function log() public {
        emit Log("Bar was called");
    }
}

// this code is hidden in a separate file
contract Mal {
    event Log(string message);

    // fallback() external {
        // emit Log("mal was called");
    // }

    // actually we can execute the same exploit even if this function does
    // not exist by using the fallback
    function log() public {
        emit Log("mal was called");
    }
}