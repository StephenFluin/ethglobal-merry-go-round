// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// All times faked to 5 seconds for testing

contract MerryGoRound {

    // State variables
    address public creator;
    // @TODO swap native token payments with GHO approvals
    uint256 public registrationFee = 1 ether; // 1 USD in Ether value
    mapping(address => string) public participants; // Address to nickname
     address[] public participantAddresses;    
    address[] public remainingParticipants;
    uint256 public finalizeStartTime;
    uint256 public roundNumber;
    uint256 public roundStartTime;
    mapping(address => bool) public payments; // Address to current payment status


    // Constructor (invoked during contract creation)
    constructor() {
        creator = msg.sender;
    }

    // Function to register a participant
    function register(string memory nickname) external  {
        // compare participants[msg.sender] to a string
        require(keccak256(abi.encodePacked(participants[msg.sender])) == keccak256(abi.encodePacked("")), "Already registered.");
        require(finalizeStartTime == 0, "Registration is closed.");

        participants[msg.sender] = nickname;
        participantAddresses.push(msg.sender); 

    }


    // Let's start to finalize the group and make sure everyone is happy with the participants
    function beginFinalization() external {
        require(msg.sender == creator, "Only creator can finalize.");
        require(finalizeStartTime == 0 && roundStartTime == 0, "Can't begin to finalize the group now.");
        finalizeStartTime = block.timestamp; 
    }


    // Function to remove a participant (during Removal phase)
    // Only allowed during the first 12 hours of finalization, so everyone has 12 hours to cancel.
    function remove(uint256 id) external {
        require(finalizeStartTime != 0 && roundStartTime == 0 , "Not in removal phase.");
        require(finalizeStartTime + 5 seconds > block.timestamp, "It's too late to remove another member.");
        require(id < participantAddresses.length, "Not a valid participant");

        payable(participantAddresses[id]).transfer(registrationFee); // Refund the participant

        delete participants[participantAddresses[id]]; 
        delete participantAddresses[id];
        
        // Shift elements after the deleted index to shrink
        for (uint i = id; i < participantAddresses.length - 1; i++) {
            participantAddresses[i] = participantAddresses[i + 1];
        }
        participantAddresses.pop();

    }

    // Function to cancel the round (at any point in the 24 hour hour finalization period)
    function cancel() external {
        require(finalizeStartTime != 0 && roundStartTime == 0 , "Not in finalization phase.");
        require(finalizeStartTime + 10 seconds > block.timestamp, "It's too late to cancel.");
        
        finalizeStartTime = 0;

        // Refund all participants
        for (uint i = 0; i < participantAddresses.length; i++) {
            payable(participantAddresses[i]).transfer(registrationFee); // Refund the participant
            
            participants[participantAddresses[i]] = ''; 
        }
        delete participantAddresses;
    }

    function finishFinalization() external {
        require(finalizeStartTime != 0 && roundStartTime == 0 , "Not in removal phase.");
        require(finalizeStartTime + 10 seconds < block.timestamp, "It's too early to finish finalization.");
        finalizeStartTime = 0;
        roundNumber = 1;
        roundStartTime = block.timestamp;


        for (uint i = 0; i < participantAddresses.length ; i++) {
            remainingParticipants.push(participantAddresses[i]);
        }
    }

    // Function to make payment (during Payment phase)
    function pay() external payable {
        require(roundStartTime != 0, "Not in payment phase.");
        require(msg.value == registrationFee, "Incorrect registration fee.");
        require(keccak256(abi.encodePacked(participants[msg.sender])) != keccak256(abi.encodePacked("")), "Not a participant.");
        require(payments[msg.sender] == false, "Already paid.");

        payments[msg.sender] = true;

    }
 
    // Function to initiate the payout (after Payment phase)
    function payout() external {
        require(roundStartTime != 0, "Round hasn't started yet.");
        require(roundStartTime + 5 seconds < block.timestamp, "Not yet in payout phase.");
        roundNumber++;

        // Remove anyone that didn't pay permanently
        // @TODO
        
        // (** @TODO: Invoke Chainlink VRF for fair random winner selection **)
        // THIS IS NOT SECURE AND CAN BE MANIPULATED
        uint256 randomishNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % remainingParticipants.length;
        payable(remainingParticipants[randomishNum]).transfer(address(this).balance); // Send the winner the pot

        // Remove them from remaining participants
        delete remainingParticipants[randomishNum];
        for (uint i = randomishNum; i < remainingParticipants.length - 1; i++) {
            remainingParticipants[i] = remainingParticipants[i + 1];
        }
        remainingParticipants.pop();

        
        roundStartTime = block.timestamp;
    }

}
