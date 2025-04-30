// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract SimpleVoting {
    address public owner;
    uint public deadline;

    struct Candidate {
        string name;
        uint voteCount;
    }

    Candidate[] public candidates;
    mapping(address => bool) public hasVoted;

    constructor(string[] memory candidateNames, uint _deadline) {
        owner = msg.sender;
        deadline = block.timestamp + _deadline;

        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate(candidateNames[i], 0));
        }
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyBeforeDeadline() {
        require(block.timestamp < deadline, "Voting is closed.");
        _;
    }

    event Voted(address indexed voter, uint indexed candidateIndex);

    function vote(uint candidateIndex) external onlyBeforeDeadline {
        require(!hasVoted[msg.sender], "You have already voted.");
        require(candidateIndex < candidates.length, "Invalid candidate index.");

        candidates[candidateIndex].voteCount++;
        hasVoted[msg.sender] = true;

        emit Voted(msg.sender, candidateIndex);
    }

    function getCandidate(uint index) public view returns (string memory name, uint voteCount) {
        require(index < candidates.length, "Invalid index");
        Candidate storage c = candidates[index];
        return (c.name, c.voteCount);
    }

    function getWinner() public view onlyOwner() returns (string memory winnerName, uint maxVotes) {
        uint winningVoteCount = 0;
        uint winnerIndex = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winnerIndex = i;
            }
        }
        return (candidates[winnerIndex].name, candidates[winnerIndex].voteCount);
    }
}
