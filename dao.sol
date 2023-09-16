// SPDX-License-Identifier: GPL - 3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract DAO {
    struct Proposal {
        string description;
        uint amount;
        uint totalShares;
        uint priceOf1share;
        address payable recipient;
        bool isExecuted;
    }

    struct isInvestor {
        address investor;
        bool isInvestorOrNot;
    }

    mapping(address => mapping(address => bool)) private isInvestorInTheProposal;
    mapping(address => mapping(address => uint)) private numOfSharesOfAnInvestorInAProposal;
    mapping(address => mapping(address => bool)) private whoVotedForWhichProposal;
    Proposal[] public proposals;
    isInvestor[] private investorArray;

    uint public votingStartTime;
    uint public votingDuration;
    uint public votingEndTime;
    address public manager;
    address public wp;
    uint public wpIndex;
    uint public sharePurchasingStartTime;

    constructor(uint _votingStartTime, uint _votingDuration, uint timeGapAfterVotingEnds) {
        require(_votingStartTime > block.timestamp, "Not a valid voting start time!");
        votingStartTime = _votingStartTime;
        votingDuration = _votingDuration;
        votingEndTime = _votingStartTime + _votingDuration;
        sharePurchasingStartTime = votingEndTime + timeGapAfterVotingEnds;
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
        proposals[i].amount += (proposals[i].priceOf1share)*numOfShares;
        proposals[i].totalShares += numOfShares;
            }
        }
        if(numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] == 0) {
            isInvestorInTheProposal[msg.sender][proposalId] = false;
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
    }

    function createProposal(string calldata _description, uint _amount, uint _totalShares, address payable _recipient) external onlyManager() {
        require(block.timestamp < votingStartTime, "Proposal creation time ended!");
        for(uint i = 0; i < proposals.length; i++) {
            if(proposals[i].recipient == _recipient) {
                revert("You cannot propose multiple times!");
            }
        }
        proposals.push(Proposal(_description, _amount, _totalShares, _amount/_totalShares, _recipient, false));
    }

    function voteProposal(address proposalId) external {
        require(block.timestamp >= votingStartTime, "Voting not started yet!");
        require(block.timestamp <= votingEndTime, "Voting Ended!");
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
                break;
            }
        }
    }

    function winnerProposal() external onlyManager() {
        require(block.timestamp > votingEndTime, "Voting has either not started or ended yet!");
        uint majorityVotes;
        uint t;
        for(uint i = 0; i < proposals.length; i++) {
            for(uint j = 0; j < investorArray.length; j++) {
                if(whoVotedForWhichProposal[investorArray[j].investor][proposals[i].recipient] == true ) {
                    t++;
                }
            }
            if(t == majorityVotes) {
                revert("Draw!");
            }
            if(t > majorityVotes) {
                majorityVotes = t;
                wp = proposals[i].recipient;
                wpIndex = i;
            }
        }
        proposals[wpIndex].isExecuted = true;
    }

    function purchaseShares(uint numOfShares) external {
        require(block.timestamp >= sharePurchasingStartTime , "Purchase of shares not started yet!");
        require(whoVotedForWhichProposal[msg.sender][wp] == true, "You had not voted for this proposal");
        require(proposals[wpIndex].totalShares >= numOfShares, "Not enough shares left now to purchase!");
        proposals[wpIndex].totalShares -= numOfShares;
        numOfSharesOfAnInvestorInAProposal[msg.sender][wp] = numOfShares;
        isInvestorInTheProposal[msg.sender][wp] = true;
        for(uint j = 0; j < investorArray.length; j++) {
            if(investorArray[j].investor == msg.sender) {
                investorArray[j].isInvestorOrNot = true;
            }
        }
        payable(wp).transfer((proposals[wpIndex].priceOf1share)*numOfShares);
        proposals[wpIndex].amount -= (proposals[wpIndex].priceOf1share)*numOfShares;
    }
}
