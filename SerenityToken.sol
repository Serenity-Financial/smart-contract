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
  uint256 private totalLockToken;
  bool public transfersEnabled = false; 

  mapping (address => bool) private fundingWallets;
  mapping (address => allocationLock) public allocations;

  struct allocationLock {
    uint256 value;
    uint256 end;
    bool locked;
  }

  event Finalize(address indexed _from, uint256 _value);
  event Lock(address indexed _from, address indexed _to, uint256 _value, uint256 _end);
  event Unlock(address indexed _from, address indexed _to, uint256 _value);
  event DisableTransfers(address indexed _from);

  function SerenityToken() ERC20Token("SERENITY INVEST", "SERENITY", 18) public {
    fundingWallet = msg.sender; 

    balanceOf[fundingWallet] = maxSaleToken;

    fundingWallets[fundingWallet] = true;
    fundingWallets[0x47c8F28e6056374aBA3DF0854306c2556B104601] = true;
    fundingWallets[0xCAD0AfB8Ec657D0DB9518B930855534f6433360f] = true;
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
    totalSoldTokens = totalSoldTokens + _value;
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public validAddress(_to) transfersAllowed(_from) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function lock(address _to, uint256 _value, uint256 _end) internal validAddress(_to) onlyOwner returns (bool) {
    require(_value > 0);

    assert(totalProjectToken > 0);
    totalLockToken = totalLockToken.add(_value);
    assert(totalProjectToken >= totalLockToken);

    require(allocations[_to].value == 0);

    // Assign a new lock.
    allocations[_to] = allocationLock({
      value: _value,
      end: _end,
      locked: true
    });

    Lock(this, _to, _value, _end);

    return true;
  }

  function unlock() external {
    require(allocations[msg.sender].locked);
    require(now >= allocations[msg.sender].end);
    
    balanceOf[msg.sender] = balanceOf[msg.sender].add(allocations[msg.sender].value);

    allocations[msg.sender].locked = false;

    Transfer(this, msg.sender, allocations[msg.sender].value);
    Unlock(this, msg.sender, allocations[msg.sender].value);
  }

  function finalize() external onlyOwner {
    require(fundingEnabled);
    
    totalSoldTokens = maxSaleToken.sub(balanceOf[fundingWallet]);

    totalProjectToken = totalSoldTokens.mul(15).div(100);

    lock(0x47c8F28e6056374aBA3DF0854306c2556B104601, totalProjectToken, now);
    
    // Zeroing a cold wallet.
    balanceOf[fundingWallet] = 0;
    balanceOf[0x47c8F28e6056374aBA3DF0854306c2556B104601] = 0;
    balanceOf[0xCAD0AfB8Ec657D0DB9518B930855534f6433360f] = 0;

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
