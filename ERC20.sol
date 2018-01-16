pragma solidity ^0.4.18;

import './SafeMath.sol';

contract IERC20Token {
  function name() public view returns (string) { name; }
  function symbol() public view returns (string) { symbol; }
  function decimals() public view returns (uint8) { decimals; }
  function totalSupply() public view returns (uint256) { totalSupply; }
  function balanceOf(address _owner) public view returns (uint256 balance) { _owner; balance; }
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) { _owner; _spender; remaining; }

  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
}

contract ERC20Token is IERC20Token {
  using SafeMath for uint256;

  string public standard = 'Token 0.1';
  string public name = '';
  string public symbol = '';
  uint8 public decimals = 0;
  uint256 public totalSupply = 0;
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function ERC20Token(string _name, string _symbol, uint8 _decimals) public {
    require(bytes(_name).length > 0 && bytes(_symbol).length > 0);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  modifier validAddress(address _address) {
    require(_address != 0x0);
    _;
  }

  function transfer(address _to, uint256 _value) public validAddress(_to) returns (bool) {
    require(_value <= balanceOf[msg.sender]);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public validAddress(_to) returns (bool) {
    require(_value <= allowance[_from][msg.sender]);
    require(_value <= balanceOf[_from]);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public validAddress(_spender) returns (bool) {
    require(_value == 0 || allowance[msg.sender][_spender] == 0);
    allowance[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
}
