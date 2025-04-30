// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

error NotOwner();
error InsufficientBalance();
error WithdrawTooSoon();

contract SimpleBank {
    address public owner;
    uint public interestRate; // 每年利率，单位：百分比
    uint public lockTime = 1 days;

    struct Deposit {
        uint amount;
        uint timestamp;
    }

    mapping(address => Deposit) public balances;
    mapping(address => bool) public isCustomer;

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount, uint interest);
    event InterestRateChanged(uint newRate);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier hasBalance() {
        require(balances[msg.sender].amount > 0, "No balance");
        _;
    }

    constructor(uint _interestRate) {
        owner = msg.sender;
        interestRate = _interestRate;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        if (!isCustomer[msg.sender]) {
            isCustomer[msg.sender] = true;
        }
        balances[msg.sender].amount += msg.value;
        balances[msg.sender].timestamp = block.timestamp;
        emit Deposited(msg.sender, msg.value);
    }

    function getBalance(address user) public view returns (uint) {
        return balances[user].amount;
    }

    function withdraw() public hasBalance {
        Deposit storage userDeposit = balances[msg.sender];
        require(block.timestamp >= userDeposit.timestamp + lockTime, "Funds are locked");

        uint interest = calculateInterest(msg.sender);
        uint total = userDeposit.amount + interest;

        userDeposit.amount = 0;
        (bool success, ) = msg.sender.call{value: total}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, total, interest);
    }

    function calculateInterest(address user) public view returns (uint) {
        Deposit memory d = balances[user];
        uint timePassed = block.timestamp - d.timestamp;
        uint yearlyInterest = (d.amount * interestRate) / 100;
        return (yearlyInterest * timePassed) / 365 days;
    }

    function setInterestRate(uint _newRate) external onlyOwner {
        interestRate = _newRate;
        emit InterestRateChanged(_newRate);
    }

    function isLocked(address user) external view returns (bool) {
        return block.timestamp < balances[user].timestamp + lockTime;
    }

    function getTimeLeft(address user) external view returns (uint) {
        if (block.timestamp >= balances[user].timestamp + lockTime) return 0;
        return balances[user].timestamp + lockTime - block.timestamp;
    }

    // Admin can retrieve accidental funds
    function rescue() external onlyOwner {
        (bool ok, ) = owner.call{value: address(this).balance}("");
        require(ok, "Rescue failed");
    }
}