
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract HelloWorld {
    string public message;

    constructor(string memory _msg) {
        message = _msg;
    }

    function update(string memory _newMsg) public {
        message = _newMsg;
    }
}
