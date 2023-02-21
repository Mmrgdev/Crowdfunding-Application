// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * Crowdfunding Smart Contract
 * This contracts allows a manager to create a customizable crowdfunding process
 * The manager can take ether from the Smart contarct only when more of the 50% contributors vote for yes
 * The contributors can have a refund when the deadline has been crossed and the amount set by the manager has not been reached.  
 */
 contract Crowdfunding {

     mapping(address => uint256) public contributors;
     address public manager;
     uint256 public minContribution;
     uint256 public deadline;
     uint256 public target;
     uint256 public raiseAmount;
     uint256 public numOfContributors;

     struct Request {
         string description;
         address payable recipient;
         uint256 value;
         bool isCompleted;
         uint numOfVoters;
         mapping(address => bool) voters;
     }

     mapping(uint256 => Request) public requests;
     uint256 public numRequests;

     constructor(uint256 _target, uint256 _deadline) {
         target = _target;
         deadline = block.timestamp + _deadline;
         minContribution = 100 wei;
         manager = msg.sender;
     }

     function sendEther() public payable {
         require(block.timestamp < deadline, "Deadline has been passed");
         require(msg.value >= 1000 wei, "Minimum contribution is not met");
         if(contributors[msg.sender] == 0){
             numOfContributors++;
         } 
         contributors[msg.sender] += msg.value;
         raiseAmount += msg.value;
     }

     function getBalance() public view returns(uint256){
         return address(this).balance;
     }

     function refund() public {
         require(block.timestamp > deadline && raiseAmount < target);
         require(contributors[msg.sender] > 0);
         address payable user = payable(msg.sender);
         contributors[msg.sender] = 0;
     }

     modifier onlyManager() {
         require(msg.sender == manager, "Only manager can call this function");
         _;
     }

     function createRequest(string memory _description, address payable _recipient, uint256 _value) public onlyManager {
         Request storage newRequest = requests[numRequests];
         numRequests++;
         newRequest.description = _description;
         newRequest.recipient = _recipient;
         newRequest.value = _value;
         newRequest.isCompleted = false;
         newRequest.numOfVoters = 0;
     }

     function voteRequest(uint256 _requestNo) public {
         require(contributors[msg.sender] > 0, "You are not a contributor");
         Request storage thisRequest = requests[_requestNo];
         require(thisRequest.voters[msg.sender] == false, "You have already voted");
         thisRequest.voters[msg.sender] = true;
         thisRequest.numOfVoters++;
     }

     function makePayment(uint _requestNo) public onlyManager {
         require(raiseAmount >= target);
         Request storage thisRequest = requests[_requestNo];
         require(thisRequest.isCompleted == false, "Already distributed the amount");
         require(thisRequest.numOfVoters > numOfContributors/2, "Majority support marks not crossed");
         thisRequest.recipient.transfer(thisRequest.value);
         thisRequest.isCompleted = true;
     }

 }

