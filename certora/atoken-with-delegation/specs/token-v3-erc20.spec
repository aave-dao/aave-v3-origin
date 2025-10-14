/*
  This is a specification file for the verification of general ERC20
  features of AaveTokenV3.sol smart contract using the Certora prover. 
  For more information, visit: https://www.certora.com/
  
  It uses the harness file: certora/harness/ATokenWithDelegation_Harness.sol
*/

import "base_token_v3.spec";

using SymbolicLendingPoolL1 as _SymbolicLendingPoolL1;
using DummyERC20_aTokenUnderlying as Underlying;

function doesntChangeBalance(method f) returns bool {
    return f.selector != sig:transfer(address,uint256).selector &&
        f.selector != sig:transferFrom(address,address,uint256).selector;
}

methods {
    function _SymbolicLendingPoolL1.getReserveNormalizedIncome(address) external returns (uint256) envfree;
    
    // called by AToken.sol::224. A method of IPool.
    function _.finalizeTransfer(address, address, address, uint256, uint256, uint256) external => NONDET;

    // called from: IncentivizedERC20.sol::29.
    function _.getACLManager() external => NONDET;

    // called from: IncentivizedERC20.sol::30.
    function _.isPoolAdmin(address) external => NONDET;

    // called from: IncentivizedERC20.sol::76.
    function _.ADDRESSES_PROVIDER() external => NONDET;

    // called from: IncentivizedERC20.sol::207. A method of incentivesControllerLocal.
    function _.handleAction(address,uint256,uint256) external => NONDET;
}

/*
ghost index() returns uint256 {
    axiom index()==RAY();
}

ghost rayMul_MI(mathint , mathint) returns uint256 {
    axiom forall mathint x. forall mathint y. to_mathint(rayMul_MI(x,y)) == x ;
}
ghost rayDiv_MI(mathint , mathint) returns uint256 {
    axiom forall mathint x. forall mathint y. to_mathint(rayDiv_MI(x,y)) == x ;
}
*/
    



/*
    @Rule


    @Description:
        Test that transferFrom works correctly. Balances are updated if not reverted. 
        If reverted, it means the transfer amount was too high, or the recipient is 0

    @Formula:
        {
            balanceFromBefore = balanceOf(from)
            balanceToBefore = balanceOf(to)
        }
        <
            transferFrom(from, to, amount)
        >
        {
            lastreverted => to = 0 || amount > balanceOf(from)
            !lastreverted => balanceOf(to) = balanceToBefore + amount &&
                            balanceOf(from) = balanceFromBefore - amount
        }

    @Notes:
        This rule fails on tokens with a blacklist and or pause function, like USDC and USDT.
        The prover finds a counterexample of a reverted transfer to a blacklisted address or a transfer in a paused state.

    @Link:

*/

rule transferFromCorrect(address from, address to, uint256 amount) {
  // We run this rule under the assumption that index==1.
  // The reasons are rounding errors due to calculations that involves the index.
  // This is OK because ATokenWithDelegation is going to be used only this way.
  require (_SymbolicLendingPoolL1.getReserveNormalizedIncome(Underlying) == RAY());
    
    env e;
    require e.msg.value == 0;
    uint256 fromBalanceBefore = balanceOf(from);
    uint256 toBalanceBefore = balanceOf(to);
    uint256 allowanceBefore = allowance(from, e.msg.sender);
    require fromBalanceBefore + toBalanceBefore < to_mathint(AAVE_MAX_SUPPLY());

    transferFrom(e, from, to, amount);

    assert from != to =>
        to_mathint(balanceOf(from)) == fromBalanceBefore - amount &&
        to_mathint(balanceOf(to)) == toBalanceBefore + amount &&
        (to_mathint(allowance(from, e.msg.sender)) == allowanceBefore - amount ||
         allowance(from, e.msg.sender) == max_uint256);
}


/*
    @Rule

    @Description:
        Balance of address 0 is always 0

    @Formula:
        { balanceOf[0] = 0 }

    @Notes:


    @Link:

*/
/*
invariant ZeroAddressNoBalance()
    balanceOf(0) == 0;
*/


/*
    @Rule

    @Description:
        Contract calls don't change token total supply.

    @Formula:
        {
            supplyBefore = totalSupply()
        }
        < f(e, args)>
        {
            supplyAfter = totalSupply()
            supplyBefore == supplyAfter
        }

    @Notes:
        This rule should fail for any token that has functions that change totalSupply(), like mint() and burn().
        It's still important to run the rule and see if it fails in functions that _aren't_ supposed to modify totalSupply()

    @Link:

*/
rule NoChangeTotalSupply(method f)
  filtered {f ->
    f.selector != sig:burn(address,address,uint256,uint256,uint256).selector &&
    f.selector != sig:mint(address,address,uint256,uint256).selector &&
    f.selector != sig:mintToTreasury(uint256,uint256).selector &&
    !f.isView &&
    f.contract == currentContract
    }
{
    //    require f.selector != sig:burn(uint256).selector && f.selector != sig:mint(address, uint256).selector;
    env e;
    uint256 totalSupplyBefore = scaledTotalSupply(e);
    calldataarg args;
    f(e, args);
    assert scaledTotalSupply(e) == totalSupplyBefore;
}


/*
    @Rule

    @Description:
        Allowance changes correctly as a result of calls to approve, transfer, increaseAllowance, decreaseAllowance

    @Formula:
        {
            allowanceBefore = allowance(from, spender)
        }
        <
            f(e, args)
        >
        {
            f.selector = approve(spender, amount) => allowance(from, spender) = amount
            f.selector = transferFrom(from, spender, amount) => allowance(from, spender) = allowanceBefore - amount
            f.selector = decreaseAllowance(spender, delta) => allowance(from, spender) = allowanceBefore - delta
            f.selector = increaseAllowance(spender, delta) => allowance(from, spender) = allowanceBefore + delta
            generic f.selector => allowance(from, spender) == allowanceBefore
        }

    @Notes:
        Some ERC20 tokens have functions like permit() that change allowance via a signature. 
        The rule will fail on such functions.

    @Link:

*/
rule ChangingAllowance(method f, address from, address spender) filtered {f -> f.contract == currentContract}
{
  // We run this rule under the assumption that index==1.
  // This is OK because ATokenWithDelegation is going to be used only this way.
  require (_SymbolicLendingPoolL1.getReserveNormalizedIncome(Underlying) == RAY());
  
  uint256 allowanceBefore = allowance(from, spender);
  env e;
  if (f.selector == sig:approve(address, uint256).selector) {
    address spender_;
    uint256 amount;
    approve(e, spender_, amount);
    if (from == e.msg.sender && spender == spender_) {
      assert allowance(from, spender) == amount;
    } else {
      assert allowance(from, spender) == allowanceBefore;
    }
  } else if (f.selector == sig:transferFrom(address,address,uint256).selector) {
    address from_;
    address to;
    uint256 amount;
    transferFrom(e, from_, to, amount);
    mathint allowanceAfter = allowance(from, spender);
    if (from == from_ && spender == e.msg.sender) {
      uint256 index = _SymbolicLendingPoolL1.getReserveNormalizedIncome(Underlying);
      assert from == to ||
        allowanceBefore == max_uint256 ||
        allowanceAfter == allowanceBefore - amount; 
    } else {
      assert allowance(from, spender) == allowanceBefore;
    }
  } else if (f.selector == sig:decreaseAllowance(address, uint256).selector) {
    address spender_;
    uint256 amount;
    require amount <= allowanceBefore;
    decreaseAllowance(e, spender_, amount);
    if (from == e.msg.sender && spender == spender_) {
      assert to_mathint(allowance(from, spender)) == allowanceBefore - amount;
    } else {
      assert allowance(from, spender) == allowanceBefore;
    }
  } else if (f.selector == sig:increaseAllowance(address, uint256).selector) {
    address spender_;
    uint256 amount;
    require amount + allowanceBefore < max_uint256;
    increaseAllowance(e, spender_, amount);
    if (from == e.msg.sender && spender == spender_) {
      assert to_mathint(allowance(from, spender)) == allowanceBefore + amount;
    } else {
      assert allowance(from, spender) == allowanceBefore;
    }
  } 
  else
    {
      calldataarg args;
      f(e, args);
      assert allowance(from, spender) == allowanceBefore ||
        f.selector == sig:permit(address,address,uint256,uint256,uint8,bytes32,bytes32).selector;
    }
}

/*
    @Rule

    @Description:
        Transfer from a to b doesn't change the sum of their balances

    @Formula:
        {
            balancesBefore = balanceOf(msg.sender) + balanceOf(b)
        }
        <
            transfer(b, amount)
        >
        {
            balancesBefore == balanceOf(msg.sender) + balanceOf(b)
        }

    @Notes:

    @Link:

*/
rule TransferSumOfFromAndToBalancesStaySame(address to, uint256 amount) {
    // This rule originally used balaceOf().
    // Changed to scaledBalanceOf() because it's more relevant to ERC20.
    env e;
    mathint summ = scaledBalanceOf(e.msg.sender) + scaledBalanceOf(to);
    require summ < max_uint256;
    transfer(e, to, amount); 
    assert scaledBalanceOf(e.msg.sender) + scaledBalanceOf(to) == summ;
}

/*
    @Rule

    @Description:
        Transfer using transferFrom() from a to b doesn't change the sum of their balances

    @Formula:
        {
            balancesBefore = balanceOf(a) + balanceOf(b)
        }
        <
            transferFrom(a, b)
        >
        {
            balancesBefore == balanceOf(a) + balanceOf(b)
        }

    @Notes:

    @Link:

*/
rule TransferFromSumOfFromAndToBalancesStaySame(address from, address to, uint256 amount) {
    // This rule originally used balaceOf().
    // Changed to scaledBalanceOf() because it's more relevant to ERC20.
    env e;
    mathint summ = scaledBalanceOf(from) + scaledBalanceOf(to);
    require summ < max_uint256;
    transferFrom(e, from, to, amount); 
    assert scaledBalanceOf(from) + scaledBalanceOf(to) == summ;
}

/*
    @Rule

    @Description:
        Transfer from msg.sender to alice doesn't change the balance of other addresses

    @Formula:
        {
            balanceBefore = balanceOf(bob)
        }
        <
            transfer(alice, amount)
        >
        {
            balanceOf(bob) == balanceBefore
        }

    @Notes:

    @Link:

*/
rule TransferDoesntChangeOtherBalance(address to, uint256 amount, address other) {
    env e;
    require other != e.msg.sender;
    require other != to && other != currentContract;
    uint256 balanceBefore = balanceOf(other);
    transfer(e, to, amount); 
    assert balanceBefore == balanceOf(other);
}

/*
    @Rule

    @Description:
        Transfer from alice to bob using transferFrom doesn't change the balance of other addresses

    @Formula:
        {
            balanceBefore = balanceOf(charlie)
        }
        <
            transferFrom(alice, bob, amount)
        >
        {
            balanceOf(charlie) = balanceBefore
        }

    @Notes:

    @Link:

*/
rule TransferFromDoesntChangeOtherBalance(address from, address to, uint256 amount, address other) {
    env e;
    require other != from;
    require other != to;
    uint256 balanceBefore = balanceOf(other);
    transferFrom(e, from, to, amount); 
    assert balanceBefore == balanceOf(other);
}

/*
    @Rule

    @Description:
        Balance of an address, who is not a sender or a recipient in transfer functions, doesn't decrease 
        as a result of contract calls

    @Formula:
        {
            balanceBefore = balanceOf(charlie)
        }
        <
            f(e, args)
        >
        {
            f.selector != transfer && f.selector != transferFrom => balanceOf(charlie) == balanceBefore
        }

    @Notes:
        USDC token has functions like transferWithAuthorization that use a signed message for allowance. 
        FTT token has a burnFrom that lets an approved spender to burn owner's token.
        Certora prover finds these counterexamples to this rule.
        In general, the rule will fail on all functions other than transfer/transferFrom that change a balance of an address.

    @Link:

*/
rule OtherBalanceOnlyGoesUp(address other, method f)
    filtered {f ->
        f.selector != sig:burn(address,address,uint256,uint256,uint256).selector &&
        f.selector != sig:transferOnLiquidation(address,address,uint256,uint256,uint256).selector
        }
{
    
    env e;
    require other != currentContract;
    uint256 balanceBefore = scaledBalanceOf(e,other);

    if (f.selector == sig:transferFrom(address, address, uint256).selector) {
        address from;
        address to;
        uint256 amount;
        require(other != from);
        require balanceOf(from) + balanceBefore < max_uint256;
        transferFrom(e, from, to, amount);
    } else if (f.selector == sig:transfer(address, uint256).selector) {
        require other != e.msg.sender;
        require balanceOf(e.msg.sender) + balanceBefore < max_uint256;
        calldataarg args;
        f(e, args);
    } else {
        require other != e.msg.sender;
        calldataarg args;
        f(e, args);
    }

    assert scaledBalanceOf(e,other) >= balanceBefore;
}

