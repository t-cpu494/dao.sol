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
        contributionTimeEnd = block.timestamp + _contributionTimeEnd;
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

    function contribution() public payable {
        require(contributionTimeEnd >= block.timestamp, "Contribution Time Ended");
        require(msg.value > 0, "Send more than 0 ether");
        isInvestor[msg.sender] = true;
        numOfShares[msg.sender] = numOfShares[msg.sender] + msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
        investorsList.push(msg.sender);
    }

    function redeemShare(uint amount) public onlyInvestor() {
        require(numOfShares[msg.sender] >= amount, "You don't have enough shares");
        require(availableFunds >= amount, "Not enough funds");
        numOfShares[msg.sender] -= amount;
        if(numOfShares[msg.sender] == 0) {
            isInvestor[msg.sender] = false;
        }
        availableFunds -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transferShare(uint amount, address to) public onlyInvestor() {
        require(availableFunds >= amount, "Not enough funds");
        require(numOfShares[msg.sender] >= amount, "You don't have enough shares");
        numOfShares[msg.sender] -= amount;
        if(numOfShares[msg.sender] == 0) {
            isInvestor[msg.sender] = false;
        }
        numOfShares[to] += amount;
        isInvestor[to] = true;
        investorsList.push(to);
    }

    function createProposal(string calldata description, uint amount, address payable recipient) public onlyManager() {
        require(availableFunds >= amount, "Not enough funds");
        proposals[nextProposalId] = Proposal(nextProposalId, description, amount, recipient, 0, block.timestamp + voteTime, false);
        nextProposalId++;
    }

    function voteProposal(uint proposalId) public onlyInvestor() {
        Proposal storage proposal = proposals[proposalId];
        require(isVoted[msg.sender][proposalId] == false, "You have already voted for this proposal");
        require(proposal.end >= block.timestamp, "Voting Time Ended");
        require(proposal.isExecuted == false, "It is already executed");
        isVoted[msg.sender][proposalId] = true;
        proposal.votes += numOfShares[msg.sender];
    }
}
