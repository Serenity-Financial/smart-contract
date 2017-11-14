pragma solidity ^0.4.18;

import './SerenityToken.sol';
import './SafeMath.sol';

contract Crowdsale {
  using SafeMath for uint256;

  SerenityToken public token;

  mapping(uint256 => uint8) icoWeeksDiscounts; 

  uint256 public preStartTime;
  uint256 public preEndTime; 

  bool public isICOStarted = false; 
  uint256 public icoStartTime; 
  uint256 public icoEndTime; 

  address public wallet;
  uint256 public tokensPerWei; 
  uint256 public weiRaised; 

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  modifier validAddress(address _address) {
    require(_address != 0x0);
    _;
  }

  function Crowdsale(uint256 _preStartTime, uint256 _preEndTime, uint256 _tokensPerWei, address _wallet) public {
    require(_preStartTime >= now);
    require(_preEndTime >= _preStartTime);
    require(_tokensPerWei > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    preStartTime = _preStartTime;
    preEndTime = _preEndTime;
    tokensPerWei = _tokensPerWei;
    wallet = _wallet;

    initDiscounts();
  }

  function initDiscounts() internal {
    icoWeeksDiscounts[0] = 40;
    icoWeeksDiscounts[1] = 35;
    icoWeeksDiscounts[2] = 30;
    icoWeeksDiscounts[3] = 25;
    icoWeeksDiscounts[4] = 20;
    icoWeeksDiscounts[5] = 10;
  }

  function createTokenContract() internal returns (SerenityToken) {
    return new SerenityToken();
  }

  function () public payable {
    buyTokens(msg.sender);
  }

  function getTimeDiscount() internal returns(uint8) {
    require(isICOStarted == true);
    require(icoStartTime > now);
    require(icoEndTime < now);

    uint256 weeksPassed = (now - icoStartTime) / 7 days;
    return icoWeeksDiscounts[weeksPassed];
  } 

  function getTotalSoldDiscount() internal returns(uint8) {
    require(isICOStarted == true);
    require(icoStartTime > now);
    require(icoEndTime < now);

    uint256 totalSold = token.totalSoldTokens();

    if (totalSold < 150000)
      return 50;
    else if (totalSold < 250000)
      return 40;
    else if (totalSold < 500000)
      return 35;
    else if (totalSold < 700000)
      return 30;
    else if (totalSold < 1100000)
      return 25;
    else if (totalSold < 2100000)
      return 20;
    else if (totalSold < 3500000)
      return 10;
  }

  function getDiscount() internal constant returns (uint8) {
    if (!isICOStarted)
      return 50;
    else {
      uint8 timeDiscount = getTimeDiscount();
      uint8 totalSoldDiscount = getTotalSoldDiscount();

      if (timeDiscount < totalSoldDiscount)
        return timeDiscount;
      else 
        return totalSoldDiscount;
    }
  }

  function buyTokens(address beneficiary) public validAddress(beneficiary) payable {
    require(validPurchase());

    uint256 weiAmount = msg.value;

    uint8 discountPercents = getDiscount();
    uint256 costWithDiscount = tokensPerWei.mul(discountPercents).div(100);
    uint256 tokens = weiAmount.mul(costWithDiscount);

    weiRaised = weiRaised.add(weiAmount);

    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function activeteICO(uint256 _icoEndTime) public {
    require(msg.sender == wallet);
    require(_icoEndTime >= now);
    require(_icoEndTime >= preEndTime);
    require(isICOStarted == false);
      
    isICOStarted = true;
    icoEndTime = _icoEndTime;
  }

  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function validPurchase() internal constant returns (bool) {
    bool withinPresalePeriod = now >= preStartTime && now <= preEndTime;
    bool withinICOPeriod = isICOStarted && now >= icoStartTime && now <= icoEndTime;

    bool nonZeroPurchase = msg.value != 0;
    
    return (withinPresalePeriod || withinICOPeriod) && nonZeroPurchase;
  }
}