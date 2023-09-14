// SPDX-License-Identifier: GPL - 3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract DAO {
    struct Proposal {
        string description;
        uint amount;
        uint totalShares;
        uint priceOf1share;
        address payable recipient;
        uint votes;
        bool isExecuted;
    }

    struct isInvestor {
        address investor;
        bool isInvestorOrNot;
    }

    mapping(address => mapping(address => bool)) private isInvestorInTheProposal;
    mapping(address => bool) public isProposer;
    mapping(address => mapping(address => uint)) private numOfSharesOfAnInvestorInAProposal;
    mapping(address => mapping(address => bool)) private whoVotedForWhichProposal;
    Proposal[] public proposals;
    isInvestor[] private investorArray;

    uint public votingStartTime;
    uint public votingDuration;
    uint public votingEndTime = votingStartTime + votingDuration;
    uint public quorum;
    address public manager;
    address public wp;

    constructor(uint _votingStartTime, uint _votingDuration, uint _quorum) {
        require(_votingStartTime > block.timestamp, "Not a valid voting start time!");
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
        for(uint i = 0; i < proposals.length; i++) {
            if(proposals[i].recipient == proposalId) {
        payable(msg.sender).transfer((proposals[i].priceOf1share)*numOfShares);
            }
        }
        if(numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] == 0) {
            isInvestorInTheProposal[msg.sender][proposalId] = false;
        }
        for(uint i = 0; i <= proposals.length; i++) {
            if(i == proposals.length) {
                for(uint j = 0; j < investorArray.length; j++) {
                    if(investorArray[j].investor == msg.sender) {
                        investorArray[j].isInvestorOrNot = false;
                    }
                }
            }
            if(isInvestorInTheProposal[msg.sender][proposals[i].recipient] == true) {
                break;
            }
            }
        }

    function transferShare(uint numOfShares, address to, address proposalId) external {
        require(numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] >= numOfShares, "You don't have enough shares invested in this proposal");
        numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] -= numOfShares;
        numOfSharesOfAnInvestorInAProposal[to][proposalId] += numOfShares;
        isInvestorInTheProposal[to][proposalId] = true;
        for(uint i = 0; i <= investorArray.length; i++) {
            if(i == investorArray.length) {
                investorArray.push(isInvestor(to, true));
            }
            if(investorArray[i].investor == to) {
                investorArray[i].isInvestorOrNot = true;
            }
        }
        if(numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] == 0) {
            isInvestorInTheProposal[msg.sender][proposalId] = false;
        }
        for(uint i = 0; i <= proposals.length; i++) {
            if(i == proposals.length) {
                for(uint j = 0; j < investorArray.length; j++) {
                    if(investorArray[j].investor == msg.sender) {
                        investorArray[j].isInvestorOrNot = false;
                    }
                }
            }
            if(isInvestorInTheProposal[msg.sender][proposals[i].recipient] == true) {
                break;
            }
            }        
    }

    function createProposal(string calldata _description, uint _amount, uint _totalShares, address payable _recipient) external onlyManager() {
        require(block.timestamp < votingStartTime, "Proposal creation time ended!");
        proposals.push(Proposal(_description, _amount, _totalShares, _amount/_totalShares, _recipient, 0, false));
        isProposer[_recipient] = true;
    }

    function voteProposal(address proposalId) external {
        require(block.timestamp > votingStartTime, "Voting not started yet!");
        require(block.timestamp < votingEndTime, "Voting Ended!");
        for(uint i = 0; i < proposals.length; i++) {
            if(proposals[i].recipient == proposalId) {
                require(proposals[i].isExecuted == false, "It is already executed!");
            }}
        require(whoVotedForWhichProposal[msg.sender][proposalId] == false, "You have already voted for this proposal!");
        whoVotedForWhichProposal[msg.sender][proposalId] = true;
        for(uint i = 0; i <= investorArray.length; i++) {
            if(i == investorArray.length) {
                investorArray.push(isInvestor(msg.sender, false));
            }
            if(investorArray[i].investor == msg.sender) {
                investorArray[i].isInvestorOrNot = false;
            }
        }
    }

    function winnerProposal() external onlyManager() {
        require(block.timestamp > votingStartTime, "Voting has not ended yet!");
        uint majorityVotes;
        uint t;
        for(uint i = 0; i < proposals.length; i++) {
            for(uint j = 0; j < investorArray.length; j++) {
                if(whoVotedForWhichProposal[investorArray[j].investor][proposals[i].recipient] == true ) {
                    t++;
                }
            }
            if(t >= majorityVotes) {
                majorityVotes = t;
                wp = proposals[i].recipient;
            }
        }
        for(uint i = 0; i < proposals.length; i++) {
            if(proposals[i].recipient == wp) {
                proposals[i].isExecuted = true;
            }
        }
    }

    function purchaseShares(uint numOfShares) external {
        uint i;
        for(uint j = 0; j < proposals.length; j++) {
            if(proposals[j].recipient == wp) {
                i = j;
            }
        }
        require(proposals[i].totalShares >= numOfShares, "Not enough shares left now to purchase!");
        proposals[i].totalShares -= numOfShares;
        numOfSharesOfAnInvestorInAProposal[msg.sender][wp] = numOfShares;
        isInvestorInTheProposal[msg.sender][wp] = true;
        for(uint j = 0; j < investorArray.length; j++) {
            if(investorArray[j].investor == msg.sender) {
                investorArray[j].isInvestorOrNot = true;
            }
        }
        payable(wp).transfer((proposals[i].priceOf1share)*numOfShares);
        proposals[i].amount -= (proposals[i].priceOf1share)*numOfShares;
    }
}
