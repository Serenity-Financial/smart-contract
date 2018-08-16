pragma solidity 0.4.24;
pragma experimental "v0.5.0";

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract SRNTPriceOracleBasic {
    uint256 public SRNT_per_USD;
}

contract Escrow {
    using SafeMath for uint256;

    address public party_a;
    address public party_b;
    address constant serenity_wallet = 0x47c8F28e6056374aBA3DF0854306c2556B104601;
    address constant burn_address = 0x0000000000000000000000000000000000000001;
    ERC20Basic constant SRNT_token = ERC20Basic(0xBC7942054F77b82e8A71aCE170E4B00ebAe67eB6);
    SRNTPriceOracleBasic constant SRNT_price_oracle = SRNTPriceOracleBasic(0xae5D95379487d047101C4912BddC6942090E5D17);

    ERC20Basic public erc20_stablecoin;
    uint256 public erc20_stablecoin_decimals;

    uint256 public withdrawal_party_a_gets;
    uint256 public withdrawal_party_b_gets;
    address public withdrawal_last_voter;

    uint256 private last_balance = 0;

    event WithdrawalRequest(address requester, uint256 party_a_gets, uint256 party_b_gets);
    event Withdrawal(uint256 party_a_gets, uint256 party_b_gets);

    constructor (address new_party_a, address new_party_b, address ERC20_address,
                 uint256 ERC20_decimals) public {
        party_a = new_party_a;
        party_b = new_party_b;
        erc20_stablecoin = ERC20Basic(ERC20_address);
        erc20_stablecoin_decimals = ERC20_decimals;
    }

    function deduct_fees() private {
        uint256 current_balance = erc20_stablecoin.balanceOf(address(this));
        if (current_balance > last_balance) {
            uint256 fee = current_balance.sub(last_balance).div(100);
            uint256 srnt_balance = SRNT_token.balanceOf(address(this));
            uint256 fee_paid_by_srnt = srnt_balance.div(SRNT_price_oracle.SRNT_per_USD())
                                                   .div(10**(18 - erc20_stablecoin_decimals));
            if (fee_paid_by_srnt < fee) {  // Burn all SRNT, deduct from fee
                if (fee_paid_by_srnt > 0) {
                    fee = fee.sub(fee_paid_by_srnt);
                    SRNT_token.transfer(burn_address, srnt_balance);
                }
                erc20_stablecoin.transfer(serenity_wallet, fee);
            } else {  // There's more SRNT available than needed. Burn a part of it.
                SRNT_token.transfer(burn_address, fee.mul(SRNT_price_oracle.SRNT_per_USD())
                                                     .mul(10**(18 - erc20_stablecoin_decimals)));
            }
        }
    }

    function force_deduct_fees() external {
        require(msg.sender == serenity_wallet);
        deduct_fees();
        last_balance = erc20_stablecoin.balanceOf(address(this));
    }

    function request_withdrawal(uint256 party_a_gets, uint256 party_b_gets) external {
        // Since the contract doesn't get called when we receive new ERC20 tokens,
        // we have to do fee deduction while processing withdrawals

        require(msg.sender != withdrawal_last_voter);  // You can't vote twice
        require((msg.sender == party_a) || (msg.sender == party_b) || (msg.sender == serenity_wallet));

        deduct_fees();

        last_balance = erc20_stablecoin.balanceOf(address(this));

        require(party_a_gets.add(party_b_gets) <= last_balance);

        withdrawal_last_voter = msg.sender;

        emit WithdrawalRequest(msg.sender, party_a_gets, party_b_gets);

        if ((withdrawal_party_a_gets == party_a_gets) && (withdrawal_party_b_gets == party_b_gets)) {  // We have consensus
            delete withdrawal_party_a_gets;
            delete withdrawal_party_b_gets;
            delete withdrawal_last_voter;
            if (party_a_gets > 0) {
                erc20_stablecoin.transfer(party_a, party_a_gets);
            }
            if (party_b_gets > 0) {
                erc20_stablecoin.transfer(party_b, party_b_gets);
            }
            last_balance = erc20_stablecoin.balanceOf(address(this));
            emit Withdrawal(party_a_gets, party_b_gets);
        } else {
            withdrawal_party_a_gets = party_a_gets;
            withdrawal_party_b_gets = party_b_gets;
        }
    }
}
