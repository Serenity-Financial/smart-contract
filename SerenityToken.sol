pragma solidity ^0.4.18;

import './SafeMath.sol';
import './ERC20.sol';
import './Owned.sol';


contract ISerenityToken {
  function initialSupply () public constant returns (uint256) { initialSupply; }

  function totalSoldTokens () public constant returns (uint256) { totalSoldTokens; }
  function totalProjectToken() public constant returns (uint256) { totalProjectToken; }

  function fundingEnabled() public constant returns (bool) { fundingEnabled; }
  function transfersEnabled() public constant returns (bool) { transfersEnabled; }
}

contract SerenityToken is ISerenityToken, ERC20Token, Owned {
  using SafeMath for uint256;
 
  address public fundingWallet;
  bool public fundingEnabled = true;
  uint256 public maxSaleToken = 3500000 ether;
  uint256 public initialSupply = 3500000 ether;
  uint256 public totalSoldTokens = 0;
  uint256 public totalProjectToken;
  bool public transfersEnabled = false;

  mapping (address => bool) private fundingWallets;

  event Finalize(address indexed _from, uint256 _value);
  event DisableTransfers(address indexed _from);

  function SerenityToken() ERC20Token("SERENITY", "SERENITY", 18) public {
    fundingWallet = msg.sender; 

    balanceOf[fundingWallet] = maxSaleToken;
    balanceOf[0x47c8F28e6056374aBA3DF0854306c2556B104601] = maxSaleToken;
    balanceOf[0xCAD0AfB8Ec657D0DB9518B930855534f6433360f] = maxSaleToken;
    balanceOf[0x041375343c3Bd1Bb28b40b5Ce7b4665A9a6e21D0] = maxSaleToken;

    fundingWallets[fundingWallet] = true;
    fundingWallets[0x47c8F28e6056374aBA3DF0854306c2556B104601] = true;
    fundingWallets[0xCAD0AfB8Ec657D0DB9518B930855534f6433360f] = true;
    fundingWallets[0x041375343c3Bd1Bb28b40b5Ce7b4665A9a6e21D0] = true;
  }

  modifier validAddress(address _address) {
    require(_address != 0x0);
    _;
  }

  modifier transfersAllowed(address _address) {
    if (fundingEnabled) {
      require(fundingWallets[_address]);
    }
    else {
      require(transfersEnabled);
    }
    _;
  }

  function transfer(address _to, uint256 _value) public validAddress(_to) transfersAllowed(msg.sender) returns (bool) {
    return super.transfer(_to, _value);
  }

  function autoTransfer(address _to, uint256 _value) public validAddress(_to) onlyOwner returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public validAddress(_to) transfersAllowed(_from) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function getTotalSoldTokens() public constant returns (uint256) {
    uint256 result = 0;
    result = result.add(maxSaleToken.sub(balanceOf[fundingWallet]));
    result = result.add(maxSaleToken.sub(balanceOf[0x47c8F28e6056374aBA3DF0854306c2556B104601]));
    result = result.add(maxSaleToken.sub(balanceOf[0xCAD0AfB8Ec657D0DB9518B930855534f6433360f]));
    result = result.add(maxSaleToken.sub(balanceOf[0x041375343c3Bd1Bb28b40b5Ce7b4665A9a6e21D0]));
    return result;
  }

  function finalize() external onlyOwner {
    require(fundingEnabled);
    
    totalSoldTokens = getTotalSoldTokens();

    totalProjectToken = totalSoldTokens.mul(15).div(100);

    // Zeroing a cold wallet.
    balanceOf[fundingWallet] = 0;
    balanceOf[0xCAD0AfB8Ec657D0DB9518B930855534f6433360f] = 0;
    balanceOf[0x041375343c3Bd1Bb28b40b5Ce7b4665A9a6e21D0] = 0;

    // Shareholders/bounties
    balanceOf[0x47c8F28e6056374aBA3DF0854306c2556B104601] = totalProjectToken;

    // End of crowdfunding.
    fundingEnabled = false;
    transfersEnabled = true;

    // End of crowdfunding.
    Transfer(this, fundingWallet, 0);
    Finalize(msg.sender, totalSupply);
  }

  function disableTransfers() external onlyOwner {
    require(transfersEnabled);

    transfersEnabled = false;

    DisableTransfers(msg.sender);
  }

  function disableFundingWallets(address _address) external onlyOwner {
    require(fundingEnabled);
    require(fundingWallet != _address);
    require(fundingWallets[_address]);

    fundingWallets[_address] = false;
  }

  function enableFundingWallets(address _address) external onlyOwner {
    require(fundingEnabled);
    require(fundingWallet != _address);

    fundingWallets[_address] = true;
  }
}
