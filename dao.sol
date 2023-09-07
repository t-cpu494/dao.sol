// SPDX-License-Identifier: GPL - 3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract DAO {
    struct Proposal {
        uint id;
        string description;
        uint amount;
        address payable recipient;
        uint votes;
        uint end;
        bool isExecuted;
    }

    mapping(address => bool) private isInvestor;
    mapping(address => uint) public numOfShares;
    mapping(address => mapping(uint => bool)) public isVoted;
    mapping(address => mapping(address => bool)) public withdrawlStatus;
    address[] public investorsList;
    mapping(uint => Proposal) public proposals;

    uint public totalShares;
    uint public availableFunds;
    uint public contributionTimeEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public manager;

    constructor(uint _contributionTimeEnd, uint _voteTime, uint _quorum) {
        require(_quorum > 0 && _quorum < 100, "Not a valid value!");
        contributionTimeEnd = _contributionTimeEnd;
        voteTime = _voteTime;
        quorum = _quorum;
        manager = msg.sender;
    }

    modifier onlyInvestor() {
        require(isInvestor[msg.sender] == true, "You are not an investor!");
        _;
    }

    modifier onlyManager() {
        require(manager == msg.sender, "You are not the manager!");
        _;
    }
}
