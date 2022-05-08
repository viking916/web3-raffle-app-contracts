// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract Raffle is VRFConsumerBaseV2 {

    //Variables that start with i_ are immutablesa. Immutables and constants are cheap.
    //Variables that start with s_ are storage variable, Storage variables are expensive.
    //Private variables are cheaper compared to public variables

    //Immutables
    uint256 public immutable i_entranceFee;
    uint256 public immutable i_interval;
    bytes32 public immutable i_gasLane;
    uint64 public immutable i_subscriptionId;
    uint32 public immutable i_callBackGasLimit;
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;

    //Constants
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;
    
    //Errors
    error Raffle__SendMoreAmountToEnterRaffle();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded();
    error Raffle_FailedToTranferWinningAmountToWinner();
    
    //Enum
    enum RaffleState {
        OPEN,
        PICKING_WINNER
    }
    RaffleState public s_raffleState;

    //Array
    address payable[] public s_players;


    uint256 public s_lastTimeStamp;
    address public s_recentWinner;

    //Events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    //Double contructor due to VRFConsumerBaseV2
    constructor(
        uint256 _entranceFee, 
        uint256 _interval, 
        address _vrfCoordinatorV2,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callBackGasLimit
        ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_gasLane = _gasLane; //keyhas for VRF
        i_subscriptionId = _subscriptionId;
        i_callBackGasLimit = _callBackGasLimit;

    }

    function enterRaffle() external payable{
        //require check function call is expensive than handling and storing error messages onchain manually.
        //require(msg.value >= i_entranceFee,"Not enough amount to participate.");
        //Check if user is trying to enter Raffle with required amount or not.
        if(msg.value < i_entranceFee){
            revert Raffle__SendMoreAmountToEnterRaffle();
        }

        //Check Raffle state.
        if(s_raffleState != RaffleState.OPEN ){
            revert Raffle_RaffleNotOpen();
        }

        //Enter user into Raffle
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);

    }

    // We want winner to be picked automatically. ChainLink keepers can be used to pick winners automatically,
    // Will need two functions for chainlink keepers to work 1. CheckUpKeep 2. PerformUpKeep

    // We want a real random winner

    // 1.We want this function to be true after some time interval
    // 2.Lottery should be open
    // 3.Contract has ETH
    // 4.Keepers has LINK 
    function checkUpKeep(bytes memory  /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData*/) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >  i_interval);
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData*/
    ) external{
        (bool upkeepNeeded,) = checkUpKeep("");
        if(!upkeepNeeded){
            revert Raffle_UpkeepNotNeeded();
        }
        s_raffleState = RaffleState.PICKING_WINNER;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /* requestId*/,
        uint256[] memory randomWords
    ) internal override{
        uint256 indexOfWinner = randomWords[0]% s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert Raffle_FailedToTranferWinningAmountToWinner();
        }
        emit WinnerPicked(recentWinner);
    }
}
