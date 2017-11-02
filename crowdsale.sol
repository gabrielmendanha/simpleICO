pragma solidity ^0.4.15;

contract tokenInCrowdsale {
  function transfer(address receiver, uint amount);
  function mintToken(address target, uint mintedAmount);
}

/* This contract defines the basic crowdsale functions.
Este contrato define as funções básicas de uma ICO. */
contract Crowdsale {
  enum State {

    /* Initial state, where the funds are still being rased.
    Estado inicial, onde o dinheiro ainda está sendo levantado. */
    Fundraising,

    /* Fails if ICO does not achieve minimum targets.
    Falha se não atingir os objetivos mínimos. */
    Failed,

    /* Success if ICO done well, but funds where not transfered to founders.
    Sucesso de a ICO deu certo, mas o dinheiro ainda não foi transferido para os fundadores */
    Successful,

    /* All done, no need to do anything.
    Tudo certo, não é necessário mais nada. */
    Closed
  }

  /* Current state of the ICO.
  Estado atual da ICO. */
  State public currentState = State.Fundraising;

  struct Contribution {
    uint amount;
    address person;
  }

  /* Array of Contribution struct.
  Array da estrutura Contribution. */
  Contribution[] contributions;

  /* The token being used as reward.
  O token que de fato está sendo usado na ICO. */
  tokenInCrowdsale public tokenReward;

  /* The person who is creating this ICO.
  A pessoa que está criando esta ICO. */
  address public creator;

  /*  The person who is going to receive the funds raised. */
  address public beneficiary;
  string public campaignUrl;

  uint public totalRaised;
  uint public currentBalance;
  uint public completedAt;
  uint public deadline; // In seconds. Em segundos.
  uint public priceInWei; // Wei is the smalest unit of Ether.
  uint public minTargetInWei;
  uint public maxTargetInWei;

  event fundReceived(address addr, uint amount, uint currentTotal);
  event winnerPaid(address winner);
  event fundingSuccessful(uint _totalRaised);
  event fundingInitialized(address _creator, address _beneficiary, string url, uint _maxTargetInEther, uint _deadline);

  function Crowdsale(uint _timeInMinutesForFundraising,
                    string _campaignUrl, address _beneficiary,
                    uint _minTargetInEther, uint _maxTargetInEther,
                    tokenInCrowdsale _addressOfTokenUsed, uint _etherCostOfEachToken) {
    creator = msg.sender;
    beneficiary = _beneficiary;
    campaignUrl = _campaignUrl;
    deadline = now + (_timeInMinutesForFundraising * 1 minutes); // Convertion to seconds
    maxTargetInWei = _maxTargetInEther * 1 ether; // Converts to Wei
    minTargetInWei = _minTargetInEther * 1 ether;
    currentBalance = 0;
    tokenReward = tokenInCrowdsale(_addressOfTokenUsed);
    priceInWei = _etherCostOfEachToken * 1 ether;

    fundingInitialized(creator, beneficiary, campaignUrl, maxTargetInWei, deadline);
  }

  modifier inState(State state){
    if (currentState != state){ revert(); }
    _;
  }

  modifier isCreator(){
    if (creator != msg.sender){ revert(); }
    _;
  }

  function contribute() public inState(State.Fundraising) payable returns(uint256) {

    uint256 amountInWei = msg.value;

    contributions.push(
      Contribution({
        amount: msg.value,
        person: msg.sender
    }));

    totalRaised += msg.value;
    currentBalance = totalRaised;
    if(maxTargetInWei != 0){ // limited funding
      tokenReward.transfer(msg.sender, amountInWei/priceInWei);
    } else { // unlimited tokens
      tokenReward.mintToken(msg.sender, amountInWei/priceInWei);
    }

    fundReceived(msg.sender, msg.value, currentBalance);

    checkFundingCompletedOrExpired();

    return contributions.length - 1;
  }

  function payout() public inState(State.Successful) {
    if(!beneficiary.send(currentBalance)){ revert(); }
    currentState = State.Closed;
    currentBalance = 0;
    winnerPaid(beneficiary);
  }

  function checkFundingCompletedOrExpired(){
    if(maxTargetInWei != 0 && totalRaised > maxTargetInWei) {

      currentState = State.Successful;
      fundingSuccessful(totalRaised);
      payout();
      completedAt = now;

    } else {
      if(now > deadline){
        if(totalRaised >= minTargetInWei){
            currentState = State.Successful;
            fundingSuccessful(totalRaised);
            payout();
            completedAt = now;
        } else { // After deadline minimum target was not achieved
          currentState = State.Failed;
          completedAt = now;
        }
      }
    }
  }

  function refund() public inState(State.Failed) returns(bool) {
    for(uint i = 0; i <= contributions.length; i++){
      if(contributions[i].person == msg.sender){
        uint amountRefound = contributions[i].amount;
        contributions[i].amount == 0;

        if(!contributions[i].person.send(amountRefound)){
          contributions[i].amount = amountRefound;
          return false;
        } else {
          totalRaised -= amountRefound;
          currentBalance = totalRaised;
        }
        return true;
      }
      return false;
    }
  }

  function purgeContract() public isCreator() {
    selfdestruct(msg.sender);
  }

  function(){
    revert();
  }
}
