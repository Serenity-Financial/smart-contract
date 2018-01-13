pragma solidity ^0.4.18;

import './SerenityToken.sol';
import './SafeMath.sol';

contract Crowdsale {
  using SafeMath for uint256;

  SerenityToken public token;

  mapping(uint256 => uint8) icoWeeksDiscounts; 

  bool public isICOStarted = false; 
  uint256 public icoStartTime; 
  uint256 public icoEndTime; 

  address public wallet = 0x47c8F28e6056374aBA3DF0854306c2556B104601;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  modifier validAddress(address _address) {
    require(_address != 0x0);
    _;
  }

  function Crowdsale() public {
    token = createTokenContract();
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

  function getDiscount() internal constant returns (uint8) {
    require(isICOStarted == true);
    require(icoStartTime < now);
    require(icoEndTime > now);

    uint256 weeksPassed = (now - icoStartTime) / 7 days;
    return icoWeeksDiscounts[weeksPassed];
  } 

  function buyTokens(address beneficiary) public validAddress(beneficiary) payable {
    require(isICOStarted);
    require(validPurchase());

    uint8 discountPercents = getDiscount();
    uint256 tokens = msg.value.mul(100).div(100 - discountPercents).mul(10000);

    require(tokens >= 100 ether);

    token.autoTransfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, msg.value, tokens);

    forwardFunds();
  }

  function activateICO(uint256 _icoEndTime) public {
    require(msg.sender == wallet);
    require(_icoEndTime >= now);
    require(isICOStarted == false);
      
    isICOStarted = true;
    icoEndTime = _icoEndTime;
    icoStartTime = now;
  }

  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function finalize() public {
    require(msg.sender == wallet);
    token.finalize();
  }

  function validPurchase() internal constant returns (bool) {
    bool withinICOPeriod = isICOStarted && now >= icoStartTime && now <= icoEndTime;

    bool nonZeroPurchase = msg.value != 0;
    
    return withinICOPeriod && nonZeroPurchase;
  }
}
