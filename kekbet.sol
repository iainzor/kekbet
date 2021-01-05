pragma solidity ^0.4.11;
contract KEKbet {

    struct Bets {
        address etherAddress;
        uint amount;
    }

    Bets[] public voteA;
    Bets[] public voteB;
    uint public teamA = 0; // balance of all bets on teamA
    uint public teamB = 0; // balance of all bets on teamB
    uint8 public house_earnings = 4; // percent
    uint public betLockTime = 0; // block
    uint public lastTransactionRec = 0; // block
    address public owner;
    address public coowner = 0x4d0D46A6A90Eb900783Fd40Be051A9792480f1F7;

    uint public minBetAmount = 10 finney;
    uint public maxBetAmount = 25 ether;

    uint constant monthBlockCount = 161280; // 28 days

    modifier onlyowner { if (msg.sender == owner) _; }

    function KEKbet() {
        owner = msg.sender;
        lastTransactionRec = block.number;
    }

    function() payable {
        // if less than minBetAmount ETH or bet locked return money
        // If bet is locked for more than 28 days allow users to return all the money
        if (msg.value < minBetAmount ||
                        (block.number >= betLockTime && betLockTime != 0 && block.number < betLockTime + monthBlockCount)) {
            throw;
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
    function lockBet(uint blocknumber) onlyowner{
        betLockTime = blocknumber;
    }

    // init getResults
    function getResults(uint winner) onlyowner {
        var winPot = (winner == 0) ? teamA : teamB;
        var losePot_ = (winner == 0) ? teamB : teamA;
        uint losePot = losePot_ * (100-house_earnings) / 100; // substract housecut
        uint collectedFees = losePot_ * house_earnings / 100;
        var winners = (winner == 0) ? voteA : voteB;
        for(uint idx = 0; idx < winners.length; idx+=1){
            uint winAmount = winners[idx].amount + (winners[idx].amount * losePot / winPot);
            if(! winners[idx].etherAddress.send(winAmount)){ // If not successfull (invalid address) add to fee pool
                collectedFees += winAmount;
            }
        }
    
        // pay housecut & reset for next bet
        if (collectedFees != 0) {
            uint part1 = collectedFees / 10;
            owner.transfer(collectedFees - part1);
            coowner.transfer(part1);
        }
        clear();
    }

    // basically private (only called if last transaction was 4 weeks ago)
    // If a match is fixed or a party cheated, I will return all transactions manually.
    function returnAll() onlyowner {
        for(uint idx = 0; idx < voteA.length; idx+=1){
            voteA[idx].etherAddress.transfer(voteA[idx].amount);
        }
        for(uint idxB = 0; idxB < voteB.length; idxB+=1){
            voteB[idxB].etherAddress.transfer(voteB[idxB].amount);
        }
        clear();
    }

    function clear() private{
    	teamA = 0;
    	teamB = 0;
    	betLockTime = 0;
    	lastTransactionRec = block.number;
	    delete voteA;
    	delete voteB;
    }

    function changeMinBetAmount(uint minBet) onlyowner {
	    minBetAmount = minBet;
    }

    function changeMaxBetAmount(uint maxBet) onlyowner {
	    maxBetAmount = maxBet;
    }

    function changeHouseEarnings(uint8 cut) onlyowner {
	    // houseEarning boundaries
    	if(cut <= 20 && cut > 0)
    	    house_earnings = cut;
    }

    function setOwner(address _owner) onlyowner {
        owner = _owner;
    }

}
