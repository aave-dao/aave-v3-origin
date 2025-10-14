import "../aToken.spec";
import "./PoolSummarizationForTokens.spec";
import "./IncentivesControllerForTokens.spec";

import "./generic.spec";
import "./tokenCheckBase.spec";

using VariableDebtTokenInstance as aToken;
using Utilities as utils;


definition ignore_func(method f) returns bool =
  f.selector == sig:initialize(address,address,uint8,string,string,bytes).selector
      ;


methods {
    // envfree declarations
    function utils.nop() external envfree;
    function aToken.scaledBalanceOf(address) external returns uint256 envfree;
    function aToken.scaledTotalSupply() external returns uint256 envfree;
    function aToken.allowance(address,address) external returns uint256 envfree;
    // note that balanceOf and totalSupply are not envfree because the calls to the pool are in fact not envfree,
    // but our current envfree checks are not precise enough for this
}

function not_implemented() {
    assert false, "Not implemented";
}

function dont_care() {
    require false; // to be used for methods we don't model in the summary version anyway
}

definition initialize_method_sig() returns uint32 = sig:initialize(address,address,uint8,string,string,bytes).selector;

// xxx currently missing return value equivalence checks
function run_parametric_with_cvl_equivalent(method f, env e) {
    // note there's a strong assumption the side effects of CVL and Solidity versions are disjoint
    if (f.selector == sig:transfer(address,uint256).selector) {
        address a1;
        uint256 u1;
        aTokenTransferCVL(aToken, a1, u1, e);
        aToken.transfer(e, a1, u1);
    } else if (f.selector == sig:transferFrom(address,address,uint256).selector) {
        address a1;
        address a2;
        uint256 u1;
        // must have the same allowance at the beginning to have the same effect
        require allowanceByToken[aToken][a1][e.msg.sender] == aToken.allowance(e, a1, e.msg.sender);
        aTokenTransferFromCVL(aToken, a1, a2, u1, e);
        aToken.transferFrom(e, a1, a2, u1);
    } else if (f.selector == sig:approve(address,uint256).selector) {
        address a1;
        uint256 u1;
        approveCVL(aToken, e.msg.sender, a1, u1);
        aToken.approve(e, a1, u1);
    } else if (f.selector == sig:decreaseAllowance(address,uint256).selector) {
        address a1;
        uint256 u1;
        decreaseAllowanceCVL(aToken, e.msg.sender, a1, u1);
        aToken.decreaseAllowance(e, a1, u1);
    } else if (f.selector == sig:increaseAllowance(address,uint256).selector) {
        address a1;
        uint256 u1;
        increaseAllowanceCVL(aToken, e.msg.sender, a1, u1);
        aToken.increaseAllowance(e, a1, u1);
    } else if (f.selector == sig:mint(address,address,uint256,uint256).selector) {
        address a1;
        address a2;
        uint256 u1;
        uint256 u2;
        aTokenMintCVL(aToken, a1, a2, u1, u2);
        aToken.mint(e, a1, a2, u1, u2);
    } else if (f.selector == sig:burn(address,uint256,uint256).selector) {
        address a1;
        uint256 u1;
        uint256 u2;
        variableDebtBurnCVL(aToken, a1, u1, u2);
        aToken.burn(e, a1, u1, u2);
        /*    } else if (f.selector == sig:setIncentivesController(address).selector) {
        address a1;
        // no CVL implementation, so nop
        aToken.setIncentivesController(e, a1);*/
    } else if (f.selector == initialize_method_sig()) {
        // we're running all of our equivalence rules on an 'initialized' state of the AToken
        dont_care();
    } else if (f.selector == sig:approveDelegation(address,uint256).selector) {
        address a1;
        uint256 u1;
        // no CVL implementation, so nop
        aToken.approveDelegation(e, a1, u1); // sol implementation to see if it's nop-equivalent for our purposes    
    } else if (f.selector == sig:delegationWithSig(address,address,uint256,uint256,uint8,bytes32,bytes32).selector) {
        address a1;
        address a2;
        uint256 u1;
        uint256 u2;
        uint8 u3;
        bytes32 b1;
        bytes32 b2;
        // no CVL implementation, so nop
        aToken.delegationWithSig(e, a1, a2, u1, u2, u3, b1, b2);
    } else {
        not_implemented();
    }
}

hook Sstore _underlyingAsset address newValue {
    aTokenToUnderlying[aToken] = newValue;
}

invariant aTokenUnderlyingMatchesGhost()
    aToken._underlyingAsset == aTokenToUnderlying[aToken]
    filtered { f -> f.contract == currentContract }


// some methods are not implemented, let's find them so we could omit them from other rules
definition unimplemented(method f) returns bool = 
    f.selector == sig:allowance(address,address).selector
    || f.selector == sig:approve(address,uint256).selector
    || f.selector == sig:decreaseAllowance(address,uint256).selector
    || f.selector == sig:increaseAllowance(address,uint256).selector
    || f.selector == sig:transfer(address,uint256).selector
    || f.selector == sig:transferFrom(address,address,uint256).selector
;
    
use rule alwaysRevert filtered { f -> 
    f.contract == currentContract 
    && unimplemented(f)
}

use builtin rule sanity filtered { f -> f.contract == currentContract && !unimplemented(f) }

function init_state_invariants() {
    requireInvariant aTokensAreNotUnderlyings();
    requireInvariant aTokenUnderlyingMatchesGhost();
    require currentATokenHasAnUnderlying(); // see definition for justification
    require tokenToSort[aToken] == VariableDebtToken_token();
    require forall address a. tokenToSort[a] < 3; // ignore stable tokens for now... xxx
}


use rule balanceOfEquivalence;
use rule scaledBalanceOfEquivalence;
use rule totalSupplyEquivalence;
use rule scaledTotalSupplyEquivalence;
use rule allowanceEquivalence;
use rule listOtherViewFunctions;
use invariant aTokensAreNotUnderlyings;
use rule currentATokenHasAnUnderlyingAfterInitiailization;
use rule aTokenWithoutUnderlyingIsERC20AfterInitialization;
