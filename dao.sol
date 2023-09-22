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

    constructor(uint timeDurationAfterWhichVotingStarts, uint _votingDuration, uint timeGapAfterVotingEnds) {
        votingStartTime = block.timestamp + timeDurationAfterWhichVotingStarts;
        votingDuration = _votingDuration;
        votingEndTime = votingStartTime + _votingDuration;
        sharePurchasingStartTime = votingEndTime + timeGapAfterVotingEnds;
        manager = msg.sender;
    }

    function redeemShares(uint numOfShares, address proposalId) external payable {
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
        require(numOfSharesOfAnInvestorInAProposal[msg.sender][proposalId] >= numOfShares, "You don't have enough shares invested in this proposal!");
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

    function createProposal(string calldata _description, uint _amount, uint _totalShares, address payable _recipient) external {
        require(block.timestamp < votingStartTime, "Proposal creation time ended!");
        for(uint i = 0; i < proposals.length; i++) {
            if(proposals[i].recipient == _recipient) {
                revert("You cannot propose multiple times!");
            }
        }
        proposals.push(Proposal(_description, _amount, _totalShares, _amount/_totalShares, _recipient, 0, false));
    }

    function voteProposal(address proposalId) external {
        require(block.timestamp >= votingStartTime, "Voting not started yet!");
        require(block.timestamp <= votingEndTime, "Voting Ended!");
        for(uint i = 0; i <= proposals.length; i++) {
            if(proposals[i].recipient == proposalId) {
                require(proposals[i].isExecuted == false, "It is already executed!");
                break;
            }
            if(i == proposals.length) {
                revert("There is no proposal with this ID!");
            }}
        require(whoVotedForWhichProposal[msg.sender][proposalId] == false, "You have already voted for this proposal!");
        whoVotedForWhichProposal[msg.sender][proposalId] = true;
        for(uint i = 0; i < proposals.length; i++) {
            if(proposals[i].recipient == proposalId) {
                proposals[i].votes++;
            }
        }
        for(uint i = 0; i <= investorArray.length; i++) {
            if(i == investorArray.length) {
                investorArray.push(isInvestor(msg.sender, false));
            }
            if(investorArray[i].investor == msg.sender) {
                break;
            }
        }
    }

    function winnerProposal() external {
        require(msg.sender == manager, "You are not the manager!");
        require(block.timestamp > votingEndTime, "Voting has either not started or ended yet!");
        uint majorityVotes;
        uint t;

        for(uint i = 0; i < proposals.length; i++) {
            t = proposals[i].votes;
            if(t > majorityVotes) {
                majorityVotes = t;
                wp = proposals[i].recipient;
                wpIndex = i;
            }
    }
    for(uint i = 0; i < proposals.length; i++) {
        if(proposals[i].votes == majorityVotes && wp != proposals[i].recipient) {
            revert("Draw!");
        }
    }
    proposals[wpIndex].isExecuted = true;
    }

    function purchaseShares(uint numOfShares) external payable {
        require(block.timestamp >= sharePurchasingStartTime , "Purchase of shares not started yet!");
        require(whoVotedForWhichProposal[msg.sender][wp] == true, "You had not voted for this proposal");
        require(proposals[wpIndex].totalShares >= numOfShares, "Not enough shares left now to purchase!");
        if(msg.value == proposals[wpIndex].priceOf1share * numOfShares) {
        payable(wp).transfer(msg.value);
        } else {
            revert("Enter purchased shares' amount");
        }
        proposals[wpIndex].totalShares -= numOfShares;
        numOfSharesOfAnInvestorInAProposal[msg.sender][wp] = numOfShares;
        isInvestorInTheProposal[msg.sender][wp] = true;
        for(uint j = 0; j < investorArray.length; j++) {
            if(investorArray[j].investor == msg.sender) {
                investorArray[j].isInvestorOrNot = true;
            }
        }
        proposals[wpIndex].amount -= (proposals[wpIndex].priceOf1share)*numOfShares;
    }
}
