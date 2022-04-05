// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";
 
    
contract Staker {

  ExampleExternalContract public exampleExternalContract;

  //Staking threshold
  uint256 public constant threshold = 1 ether;

  //Staking deadline
  uint256 public deadline = block.timestamp + 72 hours;

  //Balance of the user's stake
  mapping ( address => uint256 ) public balances;

  //Contract's Events
  event Stake(address indexed user, uint _timestamp, uint256 indexed amount);
  
  //set withdraw to be opened
  bool openForWithdraw;

  bool executed = false;

  //Modifier to check if deadline has been reached or not
  modifier deadlineReached( bool requireReached ) {
    uint256 timeRemaining = timeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Deadline is already reached");
    }
    _;
  }


  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "staking process already completed");
    _;
  }

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    
  function stake() public payable {
    require(msg.value > 0, "Cannot stake 0");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, block.timestamp, msg.value);
  }

  
  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {
    require(block.timestamp >= deadline, "Stake period still active");
   
    if(address(this).balance >= threshold) {
      (bool sent, ) = address(exampleExternalContract).call{value: address(this).balance}(abi.encodeWithSignature("complete()"));
     require (sent, "exampleExternalContract.complete failed");
     openForWithdraw = false;
    } else {
      openForWithdraw = true;
    }
  }


  // if the `threshold` was not met, all bow everyone to call a `withdraw()` function
  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public deadlineReached(true) notCompleted {
    uint256 userBalance = balances[msg.sender];

    require(userBalance > 0, "Cannot withdraw, You have no tokens staked"); balances[msg.sender] = 0;
    
  // Transfer balance back to the user
    (bool sent,) = msg.sender.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  
  // this function is called when someone sends ether to the token contract
   receive() external payable {        
    stake();                      //calls the stake functions
  }

}
