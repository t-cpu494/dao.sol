// SPDX-License-Identifier: GPL - 3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract DAO {
    struct Proposal {
        string description;
        uint amount;
        uint totalShares;
        address payable recipient;
        uint votes;
        bool isExecuted;
    }

    mapping(address => mapping(address => bool)) private isInvestor;
    mapping(address => bool) public isProposer;
    mapping(address => mapping(address => uint)) private numOfSharesOfAnInvestorInAProposal;
    mapping(address => mapping(address => bool)) private whoVotedForWhichProposal;
    mapping(address => Proposal) public proposals;

    uint public votingStartTime;
    uint public votingDuration;
    uint public votingEndTime = votingStartTime + votingDuration;
    uint public quorum;
    address public manager;

    constructor(uint _votingStartTime, uint _votingDuration, uint _quorum) {
        require(_quorum > 50 && _quorum < 100, "Not a valid quorum value!");
        votingStartTime = _votingStartTime;
        votingDuration = _votingDuration;
        quorum = _quorum;
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(manager == msg.sender, "You are not the manager!");
        _;
    }

    function redeemShares(uint numOfShares, address proposalId) external {
        require(numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] >= numOfShares, "You don't have enough shares invested in this proposal!");
        numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] -= numOfShares;
        payable(msg.sender).transfer((proposals[proposalId].amount/proposals[proposalId].totalShares)*numOfShares);
        if(numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] == 0) {
            isInvestor[msg.sender][proposalId] == false;
        }
    }

    function transferShare(uint numOfShares, address to, address proposalId) external {
        require(numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] >= numOfShares, "You don't have enough shares invested in this proposal");
        numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] -= numOfShares;
        numOfSharesOfAnInvestorInAProposal[to][proposalId] += numOfShares;
        isInvestor[to][proposalId] = true;
        if(numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] == 0) {
            isInvestor[msg.sender][proposalId] = false;
        }
    }

    function createProposal(string calldata description, uint amount, uint totalShares, address payable recipient) public onlyManager() {
        proposals[recipient] = Proposal(description, amount, totalShares, recipient, 0, false);
    }

    function voteProposal(address proposalId) external {
        require(block.timestamp > votingStartTime, "Voting not started yet!");
        require(block.timestamp < votingEndTime, "Voting Ended!");
        Proposal storage proposal = proposals[proposalId];
        require(whoVotedForWhichProposal[msg.sender][proposalId] == false, "You have already voted for this proposal!");
        require(proposal.isExecuted == false, "It is already executed!");
        whoVotedForWhichProposal[msg.sender][proposalId] = true;
        proposal.votes += numOfShares[msg.sender];
    }

    function executeProposal(uint proposalId) public onlyManager() {
        Proposal storage proposal = proposals[proposalId];
        require(((proposal.votes*100)/totalShares) >= quorum, "Majority does not support");
        proposal.isExecuted = true;
        availableFunds -= proposal.amount;
        _transfer(proposal.amount, proposal.recipient);
    }

    function _transfer(uint amount, address payable recipient) private {
        recipient.transfer(amount);
    }

    function ProposalList() public view returns(Proposal[] memory) {
        Proposal[] memory arr = new Proposal[](nextProposalId - 1);
        for(uint i = 0; i < nextProposalId; i++) {
            arr[i] = proposals[i];
        }
        return arr;
    }
}
