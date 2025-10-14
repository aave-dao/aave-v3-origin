





// Shared rules for AToken, VariableDebtToken, and StableDebtToken equivalence checks

// balanceOf equivalence
rule balanceOfEquivalence(method f)
filtered { f -> f.contract == currentContract && !f.isView && !ignore_func(f) }
{
    env e;
    init_state_invariants();
    address user;
    // this is actually not enough to check the balanceOf getters, because
    // of rounding that can cause divergence after updates.
    // here, we must resort to make sure that the ghost state matches the
    // low-level state of the AToken. So the proof is a bit more 'specific'
    // per AToken, but that is okay.
    // specifically:
    require forall address a. to_mathint(aToken._userState[a].balance) == to_mathint(balanceByToken[aToken][a]);
    uint _contractVal = aToken.balanceOf(e, user);
    uint _specVal = aTokenBalanceOfCVL(aToken, user, e);
    // given the low-level require, we can assert equivalence already here!
    assert _contractVal == _specVal;

    run_parametric_with_cvl_equivalent(f, e);

    assert forall address a. to_mathint(aToken._userState[a].balance) == to_mathint(balanceByToken[aToken][a]);
    
    uint contractVal_ = aToken.balanceOf(e, user);
    uint specVal_ = aTokenBalanceOfCVL(aToken, user, e);
    assert contractVal_ == specVal_;
}

rule scaledBalanceOfEquivalence(method f) 
filtered { f -> f.contract == currentContract && !f.isView && !ignore_func(f) }
{
    env e;
    init_state_invariants();
    address user;
    uint _contractVal = aToken.scaledBalanceOf(user);
    uint _specVal = scaledBalanceOfCVL(aToken, user);
    // this is proven in balanceOfEquivalence
    require forall address a. to_mathint(aToken._userState[a].balance) == to_mathint(balanceByToken[aToken][a]);
    assert _contractVal == _specVal;

    run_parametric_with_cvl_equivalent(f, e);
    
    uint contractVal_ = aToken.scaledBalanceOf(user);
    uint specVal_ = scaledBalanceOfCVL(aToken, user);
    assert contractVal_ == specVal_;
}

// totalSupply equivalence
rule totalSupplyEquivalence(method f)
filtered { f -> f.contract == currentContract && !f.isView && !ignore_func(f) }
{
    env e;
    init_state_invariants();
    // this is actually not enough to check the totalSupply getters, because
    // of rounding that can cause divergence after updates.
    // here, we must resort to make sure that the ghost state matches the
    // low-level state of the AToken. So the proof is a bit more 'specific'
    // per AToken, but that is okay.
    // specifically:
    require to_mathint(aToken._totalSupply) == to_mathint(totalSupplyByToken[aToken]);
    uint _contractVal = aToken.totalSupply(e);
    uint _specVal = aTokenTotalSupplyCVL(aToken, e);
    // given the low-level require, we can assert equivalence already here!
    assert _contractVal == _specVal;

    run_parametric_with_cvl_equivalent(f, e);

    assert to_mathint(aToken._totalSupply) == to_mathint(totalSupplyByToken[aToken]);
    
    uint contractVal_ = aToken.totalSupply(e);
    uint specVal_ = aTokenTotalSupplyCVL(aToken, e);
    assert contractVal_ == specVal_;
}

rule scaledTotalSupplyEquivalence(method f) 
filtered { f -> f.contract == currentContract && !f.isView && !ignore_func(f) }
{
    env e;
    init_state_invariants();
    // this is actually not enough to check the totalSupply getters, because
    // of rounding that can cause divergence after updates.
    // here, we must resort to make sure that the ghost state matches the
    // low-level state of the AToken. So the proof is a bit more 'specific'
    // per AToken, but that is okay.
    // specifically:
    require to_mathint(aToken._totalSupply) == to_mathint(totalSupplyByToken[aToken]);
    
    uint _contractVal = aToken.scaledTotalSupply();
    uint _specVal = scaledTotalSupplyCVL(aToken);
    assert _contractVal == _specVal;

    run_parametric_with_cvl_equivalent(f, e);

    assert to_mathint(aToken._totalSupply) == to_mathint(totalSupplyByToken[aToken]);

    
    uint contractVal_ = aToken.scaledTotalSupply();
    uint specVal_ = scaledTotalSupplyCVL(aToken);
    assert contractVal_ == specVal_;
}

// allowance equivalence
rule allowanceEquivalence(method f)
filtered { f -> f.contract == currentContract && !f.isView && !ignore_func(f) }
{
    env e;
    init_state_invariants();
    address owner;
    address spender;
    uint _contractVal = aToken.allowance(owner, spender);
    uint _specVal = allowanceCVL(aToken, owner, spender);
    require _contractVal == _specVal;

    run_parametric_with_cvl_equivalent(f, e);
    
    uint contractVal_ = aToken.allowance(owner, spender);
    uint specVal_ = allowanceCVL(aToken, owner, spender);
    assert contractVal_ == specVal_;
}

rule listOtherViewFunctions(method viewF)
filtered { viewF -> 
    viewF.contract == currentContract 
    && viewF.isView 
    && viewF.selector != sig:balanceOf(address).selector
    && viewF.selector != sig:scaledBalanceOf(address).selector
    && viewF.selector != sig:totalSupply().selector
    && viewF.selector != sig:allowance(address,address).selector
} {
    env e;
    calldataarg arg;
    viewF(e, arg);
    assert true;
}

// Expected failure in `initialize`, as there are no checks that we assign a legal underlying. (e.g. assigning an AToken's underlying as itself)
invariant aTokensAreNotUnderlyings() 
    forall address a. 
        a == 0 // nothing-token
        || aTokenToUnderlying[a] == 0 // underlying
        || aTokenToUnderlying[aTokenToUnderlying[a]] == 0 // aTokens map to underlyings which map to 0
    filtered { f -> f.contract == currentContract 
        // omit initialize function, we know initialization violates it
        && f.selector != initialize_method_sig()
        }

// quasi-invariant, it must hold after initialize() was called on the AToken
definition currentATokenHasAnUnderlying() returns bool =
    aTokenToUnderlying[aToken] != 0;

rule currentATokenHasAnUnderlyingAfterInitiailization(method f) 
filtered { f -> f.contract == currentContract && f.selector != initialize_method_sig() }
{
    require currentATokenHasAnUnderlying();
    env e;
    calldataarg arg;
    f(e, arg);
    assert currentATokenHasAnUnderlying();
}

// quase-invariant. ERC20 tokens don't have an underlying, AToken/VarDebt/StableDebt must have an underlying.
// it must hold after initialize() was called. 
// (though if it were possible, re-calling it can nullify the underlying)
definition aTokenWithoutUnderlyingIsERC20(address token) returns bool =
    aTokenToUnderlying[token] == 0 <=> tokenToSort[token] == 0;

rule aTokenWithoutUnderlyingIsERC20AfterInitialization(method f)
filtered { f -> f.contract == currentContract && f.selector != initialize_method_sig() }
{
    address token;
    require aTokenWithoutUnderlyingIsERC20(token);
    env e;
    calldataarg arg;
    f(e, arg);
    assert aTokenWithoutUnderlyingIsERC20(token);
}

// xxx all those initialize() failing rules could be prettified if we had an "initialized"
// predicate

// use-me block
/**

use rule balanceOfEquivalence;
use rule scaledBalanceOfEquivalence;
use rule totalSupplyEquivalence;
use rule scaledTotalSupplyEquivalence;
use rule allowanceEquivalence;
use rule listOtherViewFunctions;
use invariant aTokensAreNotUnderlyings;
use rule currentATokenHasAnUnderlyingAfterInitiailization;
use rule aTokenWithoutUnderlyingIsERC20AfterInitialization;

 */
