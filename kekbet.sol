pragma solidity ^0.4.24;

import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.4/ChainlinkClient.sol";

contract kekbet is ChainlinkClient {
    struct Bet {
        address etherAddress;
        uint amount;
    }
    
    address oracle = 0xA42FdFD2E1a7239B76D753803cbB7611004FE068; // oracle address
    bytes32 jobId = bytes32("6e5ea740bca64bf596288cef75707f51"); //job id
    uint256 fee = 0.1 * 10 ** 18; // 0.1 LINK
    uint8 public house_earnings = 4; // percent
    uint public betLockTime = 0; // block
    uint public lastTransactionRec = 0; // block

    Bet[] public voteA;
    Bet[] public voteB;
    
    uint public teamA = 0; // balance of all bets on teamA
    uint public teamB = 0; // balance of all bets on teamB
    
    address public owner;
    address public coowner = 0x618A9Df7c2Df1567583EB03926472Ffd7FcE5423;
    

    uint public minBetAmount = 10 finney;
    uint public maxBetAmount = 25 ether;

    uint constant monthBlockCount = 161280; // 28 days

    modifier onlyowner { if (msg.sender == owner) _; }

    constructor() public {
        setPublicChainlinkToken();
        
    }
    

    function KEKbets() public {
        owner = msg.sender;
        lastTransactionRec = block.number;
    }

    function() payable public {
        // if less than minBetAmount ETH or bet locked return money
        // If bet is locked for more than 28 days allow users to return all the money
        if (msg.value < minBetAmount ||
                        (block.number >= betLockTime && betLockTime != 0 && block.number < betLockTime + monthBlockCount)) {
            revert();
        }

        uint amount;
        if (msg.value > maxBetAmount) {
            msg.sender.transfer(msg.value - maxBetAmount);
            amount = maxBetAmount;
        } else {
            amount = msg.value;
        }

        if(lastTransactionRec + monthBlockCount < block.number){ // 28 days after last transaction
            returnAll();
            betLockTime = block.number;
            lastTransactionRec = block.number;
            msg.sender.transfer(msg.value);
            return;
        }
        lastTransactionRec = block.number;

        uint cidx;
        //vote with finney (even = team A, odd = team B)
        if((amount / 1000000000000000) % 2 == 0){
            teamA += amount;
            cidx = voteA.length;
            voteA.length +=1;
            voteA[cidx].etherAddress = msg.sender;
            voteA[cidx].amount = amount;
        } else {
            teamB += amount;
            cidx = voteB.length;
            voteB.length +=1;
            voteB[cidx].etherAddress = msg.sender;
            voteB[cidx].amount = amount;
        }
    }

    // no further ether will be accepted (fe match is now live)
    function lockBet(uint blocknumber) public onlyowner {
        betLockTime = blocknumber;
    }

  function getResults() public {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillResults.selector);
        sendChainlinkRequestTo(oracle, req, fee);
    }
    
    /**
     * Callback function
     */
    function fulfillResults(bytes32 _requestId, uint256 _finalScore) public recordChainlinkFulfillment(_requestId) {
        Results = _finalScore;
    }


    // init getResults
  //**  function getResults(uint winner) onlyowner {
      //  var winPot = (winner == 0) ? teamA : teamB;
    //    var losePot_ = (winner == 0) ? teamB : teamA;
  //      uint losePot = losePot_ * (100-house_earnings) / 100; // substract housecut
//        uint collectedFees = losePot_ * house_earnings / 100;
      //  var winners = (winner == 0) ? voteA : voteB;
    //    for(uint idx = 0; idx < winners.length; idx+=1){
  //          uint winAmount = winners[idx].amount + (winners[idx].amount * losePot / winPot);
        //    if(! winners[idx].etherAddress.send(winAmount)){ // If not successfull (invalid address) add to fee pool
//                collectedFees += winAmount;
        //    }
      //  }
    
    //    // pay housecut & reset for next bet
  //      if (collectedFees != 0) {
//            uint part1 = collectedFees / 10;
 //           owner.transfer(collectedFees - part1);
          //  coowner.transfer(part1);
//        }
  //      clear();
//   }

    // basically private (only called if last transaction was 4 weeks ago)
    // If a match is fixed or a party cheated, I will return all transactions manually.
    function returnAll() public onlyowner {
        for(uint idx = 0; idx < voteA.length; idx+=1){
            voteA[idx].etherAddress.transfer(voteA[idx].amount);
        }
        for(uint idxB = 0; idxB < voteB.length; idxB+=1){
            voteB[idxB].etherAddress.transfer(voteB[idxB].amount);
        }
        clear();
    }

    function clear() private {
    	teamA = 0;
    	teamB = 0;
    	betLockTime = 0;
    	lastTransactionRec = block.number;
	    delete voteA;
    	delete voteB;
    }

    function changeMinBetAmount(uint minBet) public onlyowner {
	    minBetAmount = minBet;
    }

    function changeMaxBetAmount(uint maxBet) public onlyowner {
	    maxBetAmount = maxBet;
    }

    function changeHouseEarnings(uint8 cut) public onlyowner {
	    // houseEarning boundaries
    	if(cut <= 20 && cut > 0)
    	    house_earnings = cut;
    }

    function setOwner(address _owner) public onlyowner {
        owner = _owner;
    }
}
