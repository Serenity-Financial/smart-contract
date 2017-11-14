pragma solidity ^0.4.18;

contract IOwned {
  function owner() public constant returns (address) { owner; }
  function transferOwnership(address _newOwner) public;
}

contract Owned is IOwned {
  address public owner;

  function Owned() public {
    owner = msg.sender;
  }

  modifier validAddress(address _address) {
    require(_address != 0x0);
    _;
  }
  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }
  
  function transferOwnership(address _newOwner) public validAddress(_newOwner) onlyOwner {
    require(_newOwner != owner);
    
    owner = _newOwner;
  }
}
