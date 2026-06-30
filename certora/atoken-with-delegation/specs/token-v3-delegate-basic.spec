

/*==============================================================================================
  This is a specification file for the verification of delegation features.
  This file was adapted from AaveTokenV3.sol smart contract to ATOKEN-WITH-DELEGATION smart contract.
  This file is run by the command line: 
                certoraRun --send_only certora/conf/token-v3-delegate-basic.conf
  It uses the harness file: certora/harness/ATokenWithDelegation_Harness.sol
  
  IMPORTANT:
  ---------
  The rules are verified under the following strong assumption:
              _SymbolicLendingPoolL1.getReserveNormalizedIncome() == RAY().
  That means that the liquidity index is 1.
  This is OK, because ATokenWithDelegation is going to be used only this way.
  =============================================================================================*/


import "base_token_v3.spec";

using SymbolicLendingPoolL1 as _SymbolicLendingPoolL1;


function normalize_scaled(uint256 scaled_amount) returns mathint {
  return
    rayMul_MI(scaled_amount / FACTOR() * FACTOR() , index() );
}


methods {
  function _SymbolicLendingPoolL1.getReserveNormalizedIncome(address) external returns (uint256)  => index();

  // In the following summarization we assume that all the calls to rayMul/rayDiv are done with b==RAY() (index == 1).
  // We indeed prove that this is the case in file index_EQ_1.spec. (Of course it is true only under the assumprion
  // that the asset has index==1.)
  function _.rayMul(uint256 a,uint256 b) internal => rayMul_MI(a,b) expect uint256 ALL;
  function _.rayDiv(uint256 a,uint256 b) internal => rayDiv_MI(a,b) expect uint256 ALL;

  function rayMul_WRP(uint256 a, uint256 b) external returns (uint256) envfree;
  function rayDiv_WRP(uint256 a, uint256 b) external returns (uint256) envfree;
}

persistent ghost index() returns uint256 {
  //  axiom RAY()<=index() && index()<=2*RAY();
  //  axiom index()==7*RAY(); // || index()==RAY();
  axiom index()==RAY();
}

ghost rayMul_MI(mathint , mathint) returns uint256 {
    axiom forall mathint x. forall mathint y. to_mathint(rayMul_MI(x,y)) == x ;
}
ghost rayDiv_MI(mathint , mathint) returns uint256 {
    axiom forall mathint x. forall mathint y. to_mathint(rayDiv_MI(x,y)) == x ;
}

/*
function rayMul_MI(mathint x, mathint y) returns uint256 {
  uint256 x256 = assert_uint256(x);
  uint256 y256 = assert_uint256(y);
  return rayMul_WRP(x256,y256);
}
function rayDiv_MI(mathint x, mathint y) returns uint256 {
  uint256 x256 = assert_uint256(x);
  uint256 y256 = assert_uint256(y);
  return rayDiv_WRP(x256,y256);
}
*/
/*
    @Rule

    @Description:
        If an account is not receiving delegation of power (one type) from anybody,
        and that account is not delegating that power to anybody, the power of that account
        must be equal to its token balance.

    @Note:

    @Link:
*/

rule powerWhenNotDelegating(address account) {
    mathint balance = balanceOf(account);
    bool isDelegatingVoting = isDelegatingVoting(account);
    bool isDelegatingProposition = isDelegatingProposition(account);
    uint72 dvb = getDelegatedVotingBalance(account);
    uint72 dpb = getDelegatedPropositionBalance(account);

    mathint votingPower = getPowerCurrent(account, VOTING_POWER());
    mathint propositionPower = getPowerCurrent(account, PROPOSITION_POWER());

    assert dvb == 0 && !isDelegatingVoting => votingPower == balance;
    assert dpb == 0 && !isDelegatingProposition => propositionPower == balance;
}


/**
    Account1 and account2 are not delegating power
*/

/*
    @Rule

    @Description:
        Verify correct voting power on token transfers, when both accounts are not delegating

    @Note:

    @Link:
*/


/* ===============================================================
   This function should cover all the possible transfer functions
   ==============================================================*/
function CALL_TRANSFER(env e, address alice, address bob, uint256 amount) {
  uint8 choose;
  
  if (choose ==0) 
    transferFrom(e, alice, bob, amount);
  else {
    uint256 indexx;
    transferOnLiquidation(e, alice, bob, amount, amount, index()); // Since index==1 we assume that scaledAmount==amount
  }
}


rule vpTransferWhenBothNotDelegating(address alice, address bob, address charlie, uint256 amount) {
    env e;
    require alice != bob && bob != charlie && alice != charlie;

    bool isAliceDelegatingVoting = isDelegatingVoting(alice);
    bool isBobDelegatingVoting = isDelegatingVoting(bob);

    // both accounts are not delegating
    require !isAliceDelegatingVoting && !isBobDelegatingVoting;

    mathint alicePowerBefore = getPowerCurrent(alice, VOTING_POWER());
    mathint bobPowerBefore = getPowerCurrent(bob, VOTING_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, VOTING_POWER());

    CALL_TRANSFER(e, alice, bob, amount);

    mathint alicePowerAfter = getPowerCurrent(alice, VOTING_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, VOTING_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, VOTING_POWER());

    assert alicePowerAfter == alicePowerBefore - rayMul_MI(rayDiv_MI(amount, index()),index());
    assert bobPowerAfter == bobPowerBefore + rayMul_MI(rayDiv_MI(amount, index()),index());
    assert charliePowerAfter == charliePowerBefore;
}

/*
    @Rule

    @Description:
        Verify correct proposition power on token transfers, when both accounts are not delegating

    @Note:

    @Link:
*/

rule ppTransferWhenBothNotDelegating(address alice, address bob, address charlie, uint256 amount) {
    env e;
    require alice != bob && bob != charlie && alice != charlie;

    bool isAliceDelegatingProposition = isDelegatingProposition(alice);
    bool isBobDelegatingProposition = isDelegatingProposition(bob);

    require !isAliceDelegatingProposition && !isBobDelegatingProposition;

    mathint alicePowerBefore = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint bobPowerBefore = getPowerCurrent(bob, PROPOSITION_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, PROPOSITION_POWER());

    CALL_TRANSFER(e, alice, bob, amount);

    mathint alicePowerAfter = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, PROPOSITION_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, PROPOSITION_POWER());

    assert alicePowerAfter == alicePowerBefore - rayMul_MI(rayDiv_MI(amount, index()),index());
    assert bobPowerAfter == bobPowerBefore + rayMul_MI(rayDiv_MI(amount, index()),index());
    assert charliePowerAfter == charliePowerBefore;
}

/*
    @Rule

    @Description:
        Verify correct voting power after Alice delegates to Bob, when 
        both accounts were not delegating

    @Note:

    @Link:
*/

rule vpDelegateWhenBothNotDelegating(address alice, address bob, address charlie) {
    env e;
    require alice == e.msg.sender;
    require alice != 0 && bob != 0 && charlie != 0;
    require alice != bob && bob != charlie && alice != charlie;

    bool isAliceDelegatingVoting = isDelegatingVoting(alice);
    bool isBobDelegatingVoting = isDelegatingVoting(bob);

    require !isAliceDelegatingVoting && !isBobDelegatingVoting;

    mathint aliceScaledBalance = scaledBalanceOf(alice);
    mathint aliceBalance = balanceOf(alice);
    mathint bobBalance = balanceOf(bob);

    mathint alicePowerBefore = getPowerCurrent(alice, VOTING_POWER());
    mathint bobPowerBefore = getPowerCurrent(bob, VOTING_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, VOTING_POWER());

    delegate(e, bob);

    mathint alicePowerAfter = getPowerCurrent(alice, VOTING_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, VOTING_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, VOTING_POWER());

    assert alicePowerAfter == alicePowerBefore - aliceBalance;
    assert bobPowerAfter == bobPowerBefore +
      rayMul_MI ((aliceScaledBalance / FACTOR()) * FACTOR(), index());
    assert getVotingDelegatee(alice) == bob;
    assert charliePowerAfter == charliePowerBefore;
}


/*
    @Rule

    @Description:
        Verify correct proposition power after Alice delegates to Bob, when 
        both accounts were not delegating

    @Note:

    @Link:
*/

rule ppDelegateWhenBothNotDelegating(address alice, address bob, address charlie) {
    env e;
    require alice == e.msg.sender;
    require alice != 0 && bob != 0 && charlie != 0;
    require alice != bob && bob != charlie && alice != charlie;

    bool isAliceDelegatingProposition = isDelegatingProposition(alice);
    bool isBobDelegatingProposition = isDelegatingProposition(bob);

    require !isAliceDelegatingProposition && !isBobDelegatingProposition;

    mathint aliceScaledBalance = scaledBalanceOf(alice);
    mathint aliceBalance = balanceOf(alice);
    mathint bobBalance = balanceOf(bob);

    mathint alicePowerBefore = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint bobPowerBefore = getPowerCurrent(bob, PROPOSITION_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, PROPOSITION_POWER());

    delegate(e, bob);

    mathint alicePowerAfter = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, PROPOSITION_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, PROPOSITION_POWER());

    assert alicePowerAfter == alicePowerBefore - aliceBalance;
    assert bobPowerAfter == bobPowerBefore +
      rayMul_MI ((aliceScaledBalance / FACTOR()) * FACTOR(), index());
    assert getPropositionDelegatee(alice) == bob;
    assert charliePowerAfter == charliePowerBefore;
}

/**
    Account1 is delegating power to delegatee1, account2 is not delegating power to anybody
*/

/*
    @Rule

    @Description:
        Verify correct voting power after a token transfer from Alice to Bob, when 
        Alice was delegating and Bob wasn't

    @Note:

    @Link:
*/

rule vpTransferWhenOnlyOneIsDelegating(address alice, address bob, address charlie, uint256 amount) {
    env e;
    require alice != bob && bob != charlie && alice != charlie;
    require alice!=0; // Can't transfer from address 0

    bool isAliceDelegatingVoting = isDelegatingVoting(alice);
    bool isBobDelegatingVoting = isDelegatingVoting(bob);
    address aliceDelegate = getVotingDelegatee(alice);
    require aliceDelegate != alice && aliceDelegate != 0 && aliceDelegate != bob && aliceDelegate != charlie;

    require isAliceDelegatingVoting && !isBobDelegatingVoting;

    mathint alicePowerBefore = getPowerCurrent(alice, VOTING_POWER());
    // no delegation of anyone to Alice
    require alicePowerBefore == 0;

    mathint bobPowerBefore = getPowerCurrent(bob, VOTING_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, VOTING_POWER());
    mathint aliceDelegatePowerBefore = getPowerCurrent(aliceDelegate, VOTING_POWER());
    mathint aliceScaledBalanceBefore = scaledBalanceOf(alice);

    CALL_TRANSFER(e, alice, bob, amount);

    mathint alicePowerAfter = getPowerCurrent(alice, VOTING_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, VOTING_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, VOTING_POWER());
    mathint aliceDelegatePowerAfter = getPowerCurrent(aliceDelegate, VOTING_POWER());
    mathint aliceScaledBalanceAfter = scaledBalanceOf(alice);

    assert alicePowerBefore == alicePowerAfter;
    assert bobPowerAfter == bobPowerBefore + rayMul_MI(rayDiv_MI(amount, index()),index());
    assert charliePowerBefore == charliePowerAfter;

    uint256 delta = require_uint256(aliceScaledBalanceBefore/FACTOR() - aliceScaledBalanceAfter/FACTOR());
    mathint normalizeDelta = rayMul_MI(delta * FACTOR(), index());
    assert aliceDelegatePowerAfter == aliceDelegatePowerBefore - normalizeDelta;
}


/*
    @Rule

    @Description:
        Verify correct proposition power after a token transfer from Alice to Bob, when 
        Alice was delegating and Bob wasn't

    @Note:

    @Link:
*/

rule ppTransferWhenOnlyOneIsDelegating(address alice, address bob, address charlie, uint256 amount) {
    env e;
    require alice != bob && bob != charlie && alice != charlie;
    require alice!=0; // Can't transfer from address 0

    bool isAliceDelegatingProposition = isDelegatingProposition(alice);
    bool isBobDelegatingProposition = isDelegatingProposition(bob);
    address aliceDelegate = getPropositionDelegatee(alice);
    require aliceDelegate != alice && aliceDelegate != 0 && aliceDelegate != bob && aliceDelegate != charlie;

    require isAliceDelegatingProposition && !isBobDelegatingProposition;

    mathint alicePowerBefore = getPowerCurrent(alice, PROPOSITION_POWER());
    // no delegation of anyone to Alice
    require alicePowerBefore == 0;

    mathint bobPowerBefore = getPowerCurrent(bob, PROPOSITION_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint aliceDelegatePowerBefore = getPowerCurrent(aliceDelegate, PROPOSITION_POWER());
    mathint aliceScaledBalanceBefore = scaledBalanceOf(alice);

    CALL_TRANSFER(e, alice, bob, amount);

    mathint alicePowerAfter = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, PROPOSITION_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint aliceDelegatePowerAfter = getPowerCurrent(aliceDelegate, PROPOSITION_POWER());
    mathint aliceScaledBalanceAfter = scaledBalanceOf(alice);

    // still zero
    assert alicePowerBefore == alicePowerAfter;
    assert bobPowerAfter == bobPowerBefore + rayMul_MI(rayDiv_MI(amount, index()),index());
    assert charliePowerBefore == charliePowerAfter;

    uint256 delta = require_uint256(aliceScaledBalanceBefore/FACTOR() - aliceScaledBalanceAfter/FACTOR());
    mathint normalizeDelta = rayMul_MI(delta * FACTOR(), index());
    assert aliceDelegatePowerAfter == aliceDelegatePowerBefore - normalizeDelta;
}


/*
    @Rule

    @Description:
        Verify correct voting power after Alice stops delegating, when 
        Alice was delegating and Bob wasn't

    @Note:

    @Link:
*/
rule vpStopDelegatingWhenOnlyOneIsDelegating(address alice, address charlie) {
    env e;
    require alice != charlie;
    require alice == e.msg.sender;

    bool isAliceDelegatingVoting = isDelegatingVoting(alice);
    address aliceDelegate = getVotingDelegatee(alice);

    require isAliceDelegatingVoting && aliceDelegate != alice && aliceDelegate != 0 && aliceDelegate != charlie;

    mathint alicePowerBefore = getPowerCurrent(alice, VOTING_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, VOTING_POWER());
    mathint aliceDelegatePowerBefore = getPowerCurrent(aliceDelegate, VOTING_POWER());

    delegate(e, 0);

    mathint alicePowerAfter = getPowerCurrent(alice, VOTING_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, VOTING_POWER());
    mathint aliceDelegatePowerAfter = getPowerCurrent(aliceDelegate, VOTING_POWER());

    assert alicePowerAfter == alicePowerBefore + balanceOf(alice);
    assert aliceDelegatePowerAfter == aliceDelegatePowerBefore - normalize_scaled(scaledBalanceOf(alice));
    assert charliePowerAfter == charliePowerBefore;
}

/*
    @Rule

    @Description:
        Verify correct proposition power after Alice stops delegating, when 
        Alice was delegating and Bob wasn't

    @Note:

    @Link:
*/
rule ppStopDelegatingWhenOnlyOneIsDelegating(address alice, address charlie) {
    env e;
    require alice != charlie;
    require alice == e.msg.sender;

    bool isAliceDelegatingProposition = isDelegatingProposition(alice);
    address aliceDelegate = getPropositionDelegatee(alice);

    require isAliceDelegatingProposition && aliceDelegate != alice && aliceDelegate != 0 && aliceDelegate != charlie;

    mathint alicePowerBefore = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint aliceDelegatePowerBefore = getPowerCurrent(aliceDelegate, PROPOSITION_POWER());

    delegate(e, 0);

    mathint alicePowerAfter = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint aliceDelegatePowerAfter = getPowerCurrent(aliceDelegate, PROPOSITION_POWER());

    assert alicePowerAfter == alicePowerBefore + balanceOf(alice);
    assert aliceDelegatePowerAfter == aliceDelegatePowerBefore - normalize_scaled(scaledBalanceOf(alice));
    assert charliePowerAfter == charliePowerBefore;
}

/*
    @Rule

    @Description:
        Verify correct voting power after Alice delegates

    @Note:

    @Link:
*/
rule vpChangeDelegateWhenOnlyOneIsDelegating(address alice, address delegate2, address charlie) {
    env e;
    require alice != charlie && alice != delegate2 && charlie != delegate2;
    require alice == e.msg.sender;

    bool isAliceDelegatingVoting = isDelegatingVoting(alice);
    address aliceDelegate = getVotingDelegatee(alice);
    require aliceDelegate != alice && aliceDelegate != 0 && aliceDelegate != delegate2 && 
        delegate2 != 0 && delegate2 != charlie && aliceDelegate != charlie;

    require isAliceDelegatingVoting;

    mathint alicePowerBefore = getPowerCurrent(alice, VOTING_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, VOTING_POWER());
    mathint aliceDelegatePowerBefore = getPowerCurrent(aliceDelegate, VOTING_POWER());
    mathint delegate2PowerBefore = getPowerCurrent(delegate2, VOTING_POWER());

    delegate(e, delegate2);

    mathint alicePowerAfter = getPowerCurrent(alice, VOTING_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, VOTING_POWER());
    mathint aliceDelegatePowerAfter = getPowerCurrent(aliceDelegate, VOTING_POWER());
    mathint delegate2PowerAfter = getPowerCurrent(delegate2, VOTING_POWER());
    address aliceDelegateAfter = getVotingDelegatee(alice);

    assert alicePowerBefore == alicePowerAfter;
    assert aliceDelegatePowerAfter == aliceDelegatePowerBefore - normalize_scaled(scaledBalanceOf(alice));
    assert delegate2PowerAfter == delegate2PowerBefore + normalize_scaled(scaledBalanceOf(alice));
    assert aliceDelegateAfter == delegate2;
    assert charliePowerAfter == charliePowerBefore;
}

/*
    @Rule

    @Description:
        Verify correct proposition power after Alice delegates

    @Note:

    @Link:
*/
rule ppChangeDelegateWhenOnlyOneIsDelegating(address alice, address delegate2, address charlie) {
    env e;
    require alice != charlie && alice != delegate2 && charlie != delegate2;
    require alice == e.msg.sender;

    bool isAliceDelegatingVoting = isDelegatingProposition(alice);
    address aliceDelegate = getPropositionDelegatee(alice);
    require aliceDelegate != alice && aliceDelegate != 0 && aliceDelegate != delegate2 && 
        delegate2 != 0 && delegate2 != charlie && aliceDelegate != charlie;

    require isAliceDelegatingVoting;

    mathint alicePowerBefore = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint aliceDelegatePowerBefore = getPowerCurrent(aliceDelegate, PROPOSITION_POWER());
    mathint delegate2PowerBefore = getPowerCurrent(delegate2, PROPOSITION_POWER());

    delegate(e, delegate2);

    mathint alicePowerAfter = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint aliceDelegatePowerAfter = getPowerCurrent(aliceDelegate, PROPOSITION_POWER());
    mathint delegate2PowerAfter = getPowerCurrent(delegate2, PROPOSITION_POWER());
    address aliceDelegateAfter = getPropositionDelegatee(alice);

    assert alicePowerBefore == alicePowerAfter;
    assert aliceDelegatePowerAfter == aliceDelegatePowerBefore - normalize_scaled(scaledBalanceOf(alice));
    assert delegate2PowerAfter == delegate2PowerBefore + normalize_scaled(scaledBalanceOf(alice));
    assert aliceDelegateAfter == delegate2;
    assert charliePowerAfter == charliePowerBefore;
}

/*
    @Rule

    @Description:
        Verify correct voting power after Alice transfers to Bob, when only Bob was delegating

    @Note:

    @Link:
*/

rule vpOnlyAccount2IsDelegating(address alice, address bob, address charlie, uint256 amount) {
    env e;
    require alice != bob && bob != charlie && alice != charlie;
    require alice!=0; // Can't transfer from address 0
    require bob!=0; // address 0 can't have a delegatee

    bool isAliceDelegatingVoting = isDelegatingVoting(alice);
    bool isBobDelegatingVoting = isDelegatingVoting(bob);
    address bobDelegate = getVotingDelegatee(bob);
    require bobDelegate != bob && bobDelegate != 0 && bobDelegate != alice && bobDelegate != charlie;

    require !isAliceDelegatingVoting && isBobDelegatingVoting;

    mathint alicePowerBefore = getPowerCurrent(alice, VOTING_POWER());
    mathint bobPowerBefore = getPowerCurrent(bob, VOTING_POWER());
    require bobPowerBefore == 0;
    mathint charliePowerBefore = getPowerCurrent(charlie, VOTING_POWER());
    mathint bobDelegatePowerBefore = getPowerCurrent(bobDelegate, VOTING_POWER());
    uint256 bobBalanceBefore = balanceOf(bob);
    uint256 bobScaledBalanceBefore = scaledBalanceOf(bob);

    CALL_TRANSFER(e, alice, bob, amount);

    mathint alicePowerAfter = getPowerCurrent(alice, VOTING_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, VOTING_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, VOTING_POWER());
    mathint bobDelegatePowerAfter = getPowerCurrent(bobDelegate, VOTING_POWER());
    uint256 bobScaledBalanceAfter = scaledBalanceOf(bob);

    assert alicePowerAfter == alicePowerBefore - rayMul_MI(rayDiv_MI(amount,index()),index());
    assert bobPowerAfter == 0;
    assert bobDelegatePowerAfter == bobDelegatePowerBefore -
      normalize_scaled(bobScaledBalanceBefore) + normalize_scaled(bobScaledBalanceAfter);

    assert charliePowerAfter == charliePowerBefore;
}

/*
    @Rule

    @Description:
        Verify correct proposition power after Alice transfers to Bob, when only Bob was delegating

    @Note:

    @Link:
*/

rule ppOnlyAccount2IsDelegating(address alice, address bob, address charlie, uint256 amount) {
    env e;
    require alice != bob && bob != charlie && alice != charlie;
    require alice!=0; // Can't transfer from address 0
    require bob!=0; // address 0 can't have a delegatee

    bool isAliceDelegating = isDelegatingProposition(alice);
    bool isBobDelegating = isDelegatingProposition(bob);
    address bobDelegate = getPropositionDelegatee(bob);
    require bobDelegate != bob && bobDelegate != 0 && bobDelegate != alice && bobDelegate != charlie;

    require !isAliceDelegating && isBobDelegating;

    mathint alicePowerBefore = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint bobPowerBefore = getPowerCurrent(bob, PROPOSITION_POWER());
    require bobPowerBefore == 0;
    mathint charliePowerBefore = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint bobDelegatePowerBefore = getPowerCurrent(bobDelegate, PROPOSITION_POWER());
    uint256 bobScaledBalanceBefore = scaledBalanceOf(bob);

    CALL_TRANSFER(e, alice, bob, amount);

    mathint alicePowerAfter = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, PROPOSITION_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint bobDelegatePowerAfter = getPowerCurrent(bobDelegate, PROPOSITION_POWER());
    uint256 bobScaledBalanceAfter = scaledBalanceOf(bob);

    assert alicePowerAfter == alicePowerBefore - rayMul_MI(rayDiv_MI(amount,index()),index());
    assert bobPowerAfter == 0;
    assert bobDelegatePowerAfter == bobDelegatePowerBefore -
      normalize_scaled(bobScaledBalanceBefore) + normalize_scaled(bobScaledBalanceAfter);

    assert charliePowerAfter == charliePowerBefore;
}



/*
    @Rule

    @Description:
        Verify correct proposition power after Alice transfers to Bob, when both Alice
        and Bob were delegating

    @Note:

    @Link:
*/
rule ppTransferWhenBothAreDelegating(address alice, address bob, address charlie, uint256 amount) {
    env e;
    require alice != bob && bob != charlie && alice != charlie;
    
    require alice!=0; // Can't transfer from address 0
    require bob!=0; // address 0 can't have a delegatee

    bool isAliceDelegating = isDelegatingProposition(alice);
    bool isBobDelegating = isDelegatingProposition(bob);
    require isAliceDelegating && isBobDelegating;
    address aliceDelegate = getPropositionDelegatee(alice);
    address bobDelegate = getPropositionDelegatee(bob);
    require aliceDelegate != alice && aliceDelegate != 0 && aliceDelegate != bob && aliceDelegate != charlie;
    require bobDelegate != bob && bobDelegate != 0 && bobDelegate != alice && bobDelegate != charlie;
    require aliceDelegate != bobDelegate;

    mathint alicePowerBefore = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint bobPowerBefore = getPowerCurrent(bob, PROPOSITION_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint aliceDelegatePowerBefore = getPowerCurrent(aliceDelegate, PROPOSITION_POWER());
    mathint bobDelegatePowerBefore = getPowerCurrent(bobDelegate, PROPOSITION_POWER());
    uint256 aliceScaledBalanceBefore = scaledBalanceOf(alice);
    uint256 bobScaledBalanceBefore = scaledBalanceOf(bob);

    CALL_TRANSFER(e, alice, bob, amount);

    mathint alicePowerAfter = getPowerCurrent(alice, PROPOSITION_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, PROPOSITION_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, PROPOSITION_POWER());
    mathint aliceDelegatePowerAfter = getPowerCurrent(aliceDelegate, PROPOSITION_POWER());
    mathint bobDelegatePowerAfter = getPowerCurrent(bobDelegate, PROPOSITION_POWER());
    uint256 aliceScaledBalanceAfter = scaledBalanceOf(alice);
    uint256 bobScaledBalanceAfter = scaledBalanceOf(bob);

    assert charliePowerAfter == charliePowerBefore;
    assert alicePowerAfter == alicePowerBefore;
    assert bobPowerAfter == bobPowerBefore;
    assert aliceDelegatePowerAfter == aliceDelegatePowerBefore -
      normalize_scaled(aliceScaledBalanceBefore) + normalize_scaled(aliceScaledBalanceAfter);

    uint256 delta = assert_uint256(bobScaledBalanceAfter/FACTOR() - bobScaledBalanceBefore/FACTOR());
    mathint normalizeDelta = rayMul_MI(delta * FACTOR(), index());
    assert bobDelegatePowerAfter == bobDelegatePowerBefore + normalizeDelta;
}



/*
    @Rule

    @Description:
        Verify correct voting power after Alice transfers to Bob, when both Alice
        and Bob were delegating

    @Note:

    @Link:
*/
rule vpTransferWhenBothAreDelegating(address alice, address bob, address charlie, uint256 amount) {
    env e;
    require alice != bob && bob != charlie && alice != charlie;
    require alice!=0; // Can't transfer from address 0
    require bob!=0; // address 0 can't have a delegatee

    bool isAliceDelegatingVoting = isDelegatingVoting(alice);
    bool isBobDelegatingVoting = isDelegatingVoting(bob);
    require isAliceDelegatingVoting && isBobDelegatingVoting;
    address aliceDelegate = getVotingDelegatee(alice);
    address bobDelegate = getVotingDelegatee(bob);
    require aliceDelegate != alice && aliceDelegate != 0 && aliceDelegate != bob && aliceDelegate != charlie;
    require bobDelegate != bob && bobDelegate != 0 && bobDelegate != alice && bobDelegate != charlie;
    require aliceDelegate != bobDelegate;

    mathint alicePowerBefore = getPowerCurrent(alice, VOTING_POWER());
    mathint bobPowerBefore = getPowerCurrent(bob, VOTING_POWER());
    mathint charliePowerBefore = getPowerCurrent(charlie, VOTING_POWER());
    mathint aliceDelegatePowerBefore = getPowerCurrent(aliceDelegate, VOTING_POWER());
    mathint bobDelegatePowerBefore = getPowerCurrent(bobDelegate, VOTING_POWER());
    uint256 aliceScaledBalanceBefore = scaledBalanceOf(alice);
    uint256 bobScaledBalanceBefore = scaledBalanceOf(bob);

    CALL_TRANSFER(e, alice, bob, amount);

    mathint alicePowerAfter = getPowerCurrent(alice, VOTING_POWER());
    mathint bobPowerAfter = getPowerCurrent(bob, VOTING_POWER());
    mathint charliePowerAfter = getPowerCurrent(charlie, VOTING_POWER());
    mathint aliceDelegatePowerAfter = getPowerCurrent(aliceDelegate, VOTING_POWER());
    mathint bobDelegatePowerAfter = getPowerCurrent(bobDelegate, VOTING_POWER());
    uint256 aliceBalanceAfter = balanceOf(alice);
    uint256 bobBalanceAfter = balanceOf(bob);
    uint256 aliceScaledBalanceAfter = scaledBalanceOf(alice);
    uint256 bobScaledBalanceAfter = scaledBalanceOf(bob);

    assert charliePowerAfter == charliePowerBefore;
    assert alicePowerAfter == alicePowerBefore;
    assert bobPowerAfter == bobPowerBefore;
    assert aliceDelegatePowerAfter == aliceDelegatePowerBefore -
      normalize_scaled(aliceScaledBalanceBefore) + normalize_scaled(aliceScaledBalanceAfter);

    uint256 delta = assert_uint256(bobScaledBalanceAfter/FACTOR() - bobScaledBalanceBefore/FACTOR());
    mathint normalizeDelta = rayMul_MI(delta * FACTOR(), index());
    assert bobDelegatePowerAfter == bobDelegatePowerBefore + normalizeDelta;
    
}


/*
    @Rule

    @Description:
        Verify that an account's delegate changes only as a result of a call to
        the delegation functions

    @Note:

    @Link:
*/
rule votingDelegateChanges(address alice, method f) {
    env e;
    calldataarg args;

    address aliceVotingDelegateBefore = getVotingDelegatee(alice);
    address alicePropDelegateBefore = getPropositionDelegatee(alice);

    f(e, args);

    address aliceVotingDelegateAfter = getVotingDelegatee(alice);
    address alicePropDelegateAfter = getPropositionDelegatee(alice);

    // only these four function may change the delegate of an address
    assert aliceVotingDelegateAfter != aliceVotingDelegateBefore || alicePropDelegateBefore != alicePropDelegateAfter =>
        f.selector == sig:delegate(address).selector || 
        f.selector == sig:delegateByType(address,IBaseDelegation.GovernancePowerType).selector ||
        f.selector == sig:metaDelegate(address,address,uint256,uint8,bytes32,bytes32).selector ||
        f.selector == sig:metaDelegateByType(address,address,IBaseDelegation.GovernancePowerType,uint256,uint8,bytes32,bytes32).selector;
}

/*
    @Rule

    @Description:
        Verify that an account's voting and proposition power changes only as a result of a call to
        the delegation,transfer,mint,burn functions

    @Note:

    @Link:
*/
rule votingPowerChanges(address alice, method f) 
  filtered { f -> !f.isView && f.contract == currentContract}
{
  env e;
  calldataarg args;
  
  uint aliceVotingPowerBefore = getPowerCurrent(alice, VOTING_POWER());
  uint alicePropPowerBefore = getPowerCurrent(alice, PROPOSITION_POWER());
  
  f(e, args);
  
  uint aliceVotingPowerAfter = getPowerCurrent(alice, VOTING_POWER());
  uint alicePropPowerAfter = getPowerCurrent(alice, PROPOSITION_POWER());
  
  // only the following function may change the power of an address
  assert aliceVotingPowerAfter != aliceVotingPowerBefore || alicePropPowerAfter != alicePropPowerBefore =>
    f.selector == sig:delegate(address).selector || 
    f.selector == sig:delegateByType(address,IBaseDelegation.GovernancePowerType).selector ||
    f.selector == sig:metaDelegate(address,address,uint256,uint8,bytes32,bytes32).selector ||
    f.selector == sig:metaDelegateByType(address,address,IBaseDelegation.GovernancePowerType,uint256,uint8,bytes32,bytes32).selector ||
    f.selector == sig:transfer(address,uint256).selector ||
    f.selector == sig:transferFrom(address,address,uint256).selector ||
    f.selector == sig:transferOnLiquidation(address,address,uint256,uint256,uint256).selector ||
    f.selector == sig:burn(address,address,uint256,uint256,uint256).selector ||
    f.selector == sig:mint(address,address,uint256,uint256).selector ||
    f.selector == sig:mintToTreasury(uint256,uint256).selector
    ;
}

/*
    @Rule

    @Description:
        Verify that only delegate() and metaDelegate() may change both voting and
        proposition delegates of an account at once.

    @Note:

    @Link:
*/
rule delegationTypeIndependence(address who, method f) filtered { f -> !f.isView } {
    address _delegateeV = getVotingDelegatee(who);
    address _delegateeP = getPropositionDelegatee(who);
    
    env e;
    calldataarg arg;
    f(e, arg);
    
    address delegateeV_ = getVotingDelegatee(who);
    address delegateeP_ = getPropositionDelegatee(who);
    assert _delegateeV != delegateeV_ && _delegateeP != delegateeP_ =>
        (f.selector == sig:delegate(address).selector ||
         f.selector == sig:metaDelegate(address,address,uint256,uint8,bytes32,bytes32).selector),
        "one delegatee type stays the same, unless delegate or delegateBySig was called";
}

/*
    @Rule

    @Description:
        Verifies that delegating twice to the same delegate changes the delegate's
        voting power only once.

    @Note:

    @Link:
*/
rule cantDelegateTwice(address _delegate) {
    env e;

    address delegateBeforeV = getVotingDelegatee(e.msg.sender);
    address delegateBeforeP = getPropositionDelegatee(e.msg.sender);
    require delegateBeforeV != _delegate && delegateBeforeV != e.msg.sender && delegateBeforeV != 0;
    require delegateBeforeP != _delegate && delegateBeforeP != e.msg.sender && delegateBeforeP != 0;
    require _delegate != e.msg.sender && _delegate != 0 && e.msg.sender != 0;
    require getDelegationMode(e.msg.sender) == FULL_POWER_DELEGATED();

    mathint votingPowerBefore = getPowerCurrent(_delegate, VOTING_POWER());
    mathint propPowerBefore = getPowerCurrent(_delegate, PROPOSITION_POWER());
    
    delegate(e, _delegate);
    
    mathint votingPowerAfter = getPowerCurrent(_delegate, VOTING_POWER());
    mathint propPowerAfter = getPowerCurrent(_delegate, PROPOSITION_POWER());

    delegate(e, _delegate);

    mathint votingPowerAfter2 = getPowerCurrent(_delegate, VOTING_POWER());
    mathint propPowerAfter2 = getPowerCurrent(_delegate, PROPOSITION_POWER());

    assert votingPowerAfter == votingPowerBefore + normalize_scaled(scaledBalanceOf(e.msg.sender));
    assert propPowerAfter == propPowerBefore + normalize_scaled(scaledBalanceOf(e.msg.sender));
    assert votingPowerAfter2 == votingPowerAfter && propPowerAfter2 == propPowerAfter;
}

/*
    @Rule

    @Description:
        transfer and transferFrom change voting/proposition power identically

    @Note:

    @Link:
*/
rule transferAndTransferFromPowerEquivalence(address bob, uint amount) {
    env e1;
    env e2;
    storage init = lastStorage;

    address alice;
    require alice == e1.msg.sender;

    uint aliceVotingPowerBefore = getPowerCurrent(alice, VOTING_POWER());
    uint alicePropPowerBefore = getPowerCurrent(alice, PROPOSITION_POWER());

    transfer(e1, bob, amount);

    uint aliceVotingPowerAfterTransfer = getPowerCurrent(alice, VOTING_POWER());
    uint alicePropPowerAfterTransfer = getPowerCurrent(alice, PROPOSITION_POWER());

    transferFrom(e2, alice, bob, amount) at init;

    uint aliceVotingPowerAfterTransferFrom = getPowerCurrent(alice, VOTING_POWER());
    uint alicePropPowerAfterTransferFrom = getPowerCurrent(alice, PROPOSITION_POWER());

    assert aliceVotingPowerAfterTransfer == aliceVotingPowerAfterTransferFrom &&
           alicePropPowerAfterTransfer == alicePropPowerAfterTransferFrom;

}

