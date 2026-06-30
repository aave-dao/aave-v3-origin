
/*==============================================================================================
  This is a specification file for the verification of delegation features.
  This file was adapted from AaveTokenV3.sol smart contract to ATOKEN-WITH-DELEGATION smart contract.
  This file is run by the command line: 
                certoraRun certora/conf/token-v3-delegate-HL-invariants.conf
  It uses the harness file: certora/harness/ATokenWithDelegation_Harness.sol

  IMPORTANT:
  ---------
  The rules are verified under the following strong assumption:
              _SymbolicLendingPoolL1.getReserveNormalizedIncome() == RAY().
  That means that the liquidity index is 1.
  This is OK, because ATokenWithDelegation is going to be used on that way.
  =============================================================================================*/

import "base_token_v3.spec";

using DummyERC20_aTokenUnderlying as Underlying;
using SymbolicLendingPoolL1 as _SymbolicLendingPoolL1;

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

ghost index() returns uint256 {
    axiom index()==RAY();
}

ghost rayMul_MI(mathint , mathint) returns uint256 {
    axiom forall mathint x. forall mathint y. to_mathint(rayMul_MI(x,y)) == x ;
}
ghost rayDiv_MI(mathint , mathint) returns uint256 {
    axiom forall mathint x. forall mathint y. to_mathint(rayDiv_MI(x,y)) == x ;
}

/*
methods {
  function _SymbolicLendingPoolL1.getReserveNormalizedIncome(address) external returns (uint256)  => index();

  function rayMul_WRP(uint256 a, uint256 b) external returns (uint256) envfree;
  function rayDiv_WRP(uint256 a, uint256 b) external returns (uint256) envfree;
}

persistent ghost index() returns uint256 {
  // The current design supports only the situation of index()==RAY()
  //  axiom 1==1;
  axiom index()==RAY();
}
*/


//==================================================================================================
//==================================================================================================
//                           ********** GHOSTS and HOOKS **********
//==================================================================================================
//==================================================================================================

persistent ghost mapping(address => mathint) sum_all_voting_delegated_power {
    init_state axiom forall address delegatee. sum_all_voting_delegated_power[delegatee] == 0;
}
persistent ghost mapping(address => mathint) sum_all_proposition_delegated_power {
    init_state axiom forall address delegatee. sum_all_proposition_delegated_power[delegatee] == 0;
}

// =========================================================================
//   mirror_votingDelegatee
// =========================================================================
persistent ghost mapping(address => address) mirror_votingDelegatee { 
    init_state axiom forall address a. mirror_votingDelegatee[a] == 0;
}
hook Sstore _votingDelegatee[KEY address delegator] address new_delegatee (address old_delegatee) {
  mirror_votingDelegatee[delegator] = new_delegatee;
  if ((mirror_delegationMode[delegator]==FULL_POWER_DELEGATED() ||
       mirror_delegationMode[delegator]==VOTING_DELEGATED()) &&
      new_delegatee != old_delegatee) { // if a delegator changes his delegatee
    if (new_delegatee!=0)
      sum_all_voting_delegated_power[new_delegatee] =
        sum_all_voting_delegated_power[new_delegatee] + (mirror_balance[delegator]/(FACTOR())*(FACTOR()));
    if (old_delegatee!=0)
      sum_all_voting_delegated_power[old_delegatee] = 
        sum_all_voting_delegated_power[old_delegatee] - (mirror_balance[delegator]/(FACTOR())*(FACTOR()));
  }
}
hook Sload address val _votingDelegatee[KEY address delegator] {
    require(mirror_votingDelegatee[delegator] == val);
}

// =========================================================================
//   mirror_propositionDelegatee
// =========================================================================
persistent ghost mapping(address => address) mirror_propositionDelegatee { 
    init_state axiom forall address a. mirror_propositionDelegatee[a] == 0;
}
hook Sstore _propositionDelegatee[KEY address delegator] address new_delegatee (address old_delegatee) {
  mirror_propositionDelegatee[delegator] = new_delegatee;
  if ((mirror_delegationMode[delegator]==FULL_POWER_DELEGATED() ||
       mirror_delegationMode[delegator]==PROPOSITION_DELEGATED()) &&
      new_delegatee != old_delegatee) { // if a delegator changes his delegatee
    if (new_delegatee!=0)
      sum_all_proposition_delegated_power[new_delegatee] =
        sum_all_proposition_delegated_power[new_delegatee] + (mirror_balance[delegator]/(FACTOR())*(FACTOR()));
    if (old_delegatee!=0)
      sum_all_proposition_delegated_power[old_delegatee] = 
        sum_all_proposition_delegated_power[old_delegatee] - (mirror_balance[delegator]/(FACTOR())*(FACTOR()));
  }
}
hook Sload address val _propositionDelegatee[KEY address delegator] {
    require(mirror_propositionDelegatee[delegator] == val);
}


// =========================================================================
//   mirror_delegationMode
// =========================================================================
persistent ghost mapping(address => ATokenWithDelegation_Harness.DelegationMode) mirror_delegationMode { 
    init_state axiom forall address a. mirror_delegationMode[a] ==
        ATokenWithDelegation_Harness.DelegationMode.NO_DELEGATION;
}
hook Sstore _userState[KEY address a].delegationMode ATokenWithDelegation_Harness.DelegationMode newVal (ATokenWithDelegation_Harness.DelegationMode oldVal) {
    mirror_delegationMode[a] = newVal;

    if ( (newVal==VOTING_DELEGATED() || newVal==FULL_POWER_DELEGATED())
         &&
         (oldVal!=VOTING_DELEGATED() && oldVal!=FULL_POWER_DELEGATED())
       ) { // if we start to delegate VOTING now
        sum_all_voting_delegated_power[mirror_votingDelegatee[a]] =
          sum_all_voting_delegated_power[mirror_votingDelegatee[a]] + // nissan: check what if mirror_votingDelegatee[a]==0
            (mirror_balance[a]/(FACTOR())*(FACTOR()));
    }

    if ( (newVal==PROPOSITION_DELEGATED() || newVal==FULL_POWER_DELEGATED())
         &&
         (oldVal!=PROPOSITION_DELEGATED() && oldVal!=FULL_POWER_DELEGATED())
       ) { // if we start to delegate PROPOSITION now
        sum_all_proposition_delegated_power[mirror_propositionDelegatee[a]] =
            sum_all_proposition_delegated_power[mirror_propositionDelegatee[a]] +
            (mirror_balance[a]/(FACTOR())*(FACTOR()));
    }
}
hook Sload ATokenWithDelegation_Harness.DelegationMode val _userState[KEY address a].delegationMode {
    require(mirror_delegationMode[a] == val);
}



// =========================================================================
//   mirror_balance
// =========================================================================
persistent ghost mapping(address => uint120) mirror_balance { 
    init_state axiom forall address a. mirror_balance[a] == 0;
}
hook Sstore _userState[KEY address a].balance uint120 balance (uint120 old_balance) {
    mirror_balance[a] = balance;
    // The code should be:
    // if a delegates to b, sum_all_voting_delegated_power[b] += the diff of balances of a
    if (a!=0 &&
        (mirror_delegationMode[a]==FULL_POWER_DELEGATED() ||
         mirror_delegationMode[a]==VOTING_DELEGATED() )
        )
        sum_all_voting_delegated_power[mirror_votingDelegatee[a]] =  // nissan: check what if mirror_votingDelegatee[a]==0
            sum_all_voting_delegated_power[mirror_votingDelegatee[a]] +
            (balance/ (FACTOR()) * (FACTOR())) - (old_balance/ (FACTOR()) * (FACTOR())) ;

    if (a!=0 &&
        (mirror_delegationMode[a]==FULL_POWER_DELEGATED() ||
         mirror_delegationMode[a]==PROPOSITION_DELEGATED() )
        )
        sum_all_proposition_delegated_power[mirror_propositionDelegatee[a]] =
            sum_all_proposition_delegated_power[mirror_propositionDelegatee[a]] +
            (balance/ (FACTOR()) * (FACTOR())) - (old_balance/ (FACTOR()) * (FACTOR())) ;
}
hook Sload uint120 bal _userState[KEY address a].balance {
    require(mirror_balance[a] == bal);
}



//==================================================================================================
//==================================================================================================
//                           ********** MIRROR CORRECTNESS **********
//==================================================================================================
//==================================================================================================

invariant mirror_votingDelegatee_correct(address a)
    mirror_votingDelegatee[a] == getVotingDelegatee(a);

invariant mirror_propositionDelegatee_correct(address a)
    mirror_propositionDelegatee[a] == getPropositionDelegatee(a);

invariant mirror_delegationMode_correct(address a)
    mirror_delegationMode[a] == getDelegationMode(a);

invariant mirror_balance_correct(address a)
    mirror_balance[a] == getBalance(a);


//==================================================================================================
//==================================================================================================
//                           ********** INVARIANTS **********
//==================================================================================================
//==================================================================================================

invariant user_cant_voting_delegate_to_himself()
    forall address a. a!=0 => mirror_votingDelegatee[a] != a;

invariant user_cant_proposition_delegate_to_himself()
    forall address a. a!=0 => mirror_propositionDelegatee[a] != a;


invariant user_cant_voting_delegate_to_0()
  forall address a. a!=0 =>
  (
   (mirror_delegationMode[a]==FULL_POWER_DELEGATED() || mirror_delegationMode[a]==VOTING_DELEGATED()) =>
    mirror_votingDelegatee[a] != 0
  );

invariant user_cant_proposition_delegate_to_0()
  forall address a. a!=0 =>
  (
   (mirror_delegationMode[a]==FULL_POWER_DELEGATED() || mirror_delegationMode[a]==PROPOSITION_DELEGATED()) =>
    mirror_propositionDelegatee[a] != 0
  );


invariant delegated_voting_balance_of_0_IS_0()
  getDelegatedVotingBalance(0)==0
  filtered {f -> !f.isView && f.contract == currentContract}

invariant delegated_proposition_balance_of_0_IS_0()
  getDelegatedPropositionBalance(0)==0
  filtered {f -> !f.isView && f.contract == currentContract}



invariant sum_all_voting_delegated_power__corectness(address bob) 
  sum_all_voting_delegated_power[bob] == getDelegatedVotingBalance(bob)*FACTOR()
  filtered {f -> !f.isView && f.contract == currentContract} {
  preserved with (env e) {
    requireInvariant delegated_voting_balance_of_0_IS_0();
    requireInvariant user_cant_voting_delegate_to_0();
    requireInvariant user_cant_voting_delegate_to_himself();
  }
}

invariant sum_all_proposition_delegated_power__corectness(address bob) 
  sum_all_proposition_delegated_power[bob] == getDelegatedPropositionBalance(bob)*FACTOR()
  filtered {f -> !f.isView && f.contract == currentContract} {
  preserved with (env e) {
    requireInvariant delegated_proposition_balance_of_0_IS_0();
    requireInvariant user_cant_proposition_delegate_to_0();
    requireInvariant user_cant_proposition_delegate_to_himself();
  }
}

invariant value_of_sum_all_voting_delegated_power_OK(address bob)
  bob!=0 => (
             (0 <= sum_all_voting_delegated_power[bob]
              &&   sum_all_voting_delegated_power[bob]+mirror_balance[bob] < 2^256)
  )
  filtered { f -> !f.isView && f.contract == currentContract} {
  preserved with (env e) {
    requireInvariant sum_all_voting_delegated_power__corectness(bob);
  }
}

invariant value_of_sum_all_proposition_delegated_power_OK(address bob)
  bob!=0 => (
             (0 <= sum_all_proposition_delegated_power[bob]
              &&   sum_all_proposition_delegated_power[bob]+mirror_balance[bob] < 2^256)
  )
  filtered { f -> !f.isView && f.contract == currentContract} {
  preserved with (env e) {
    requireInvariant sum_all_proposition_delegated_power__corectness(bob);
  }
}



// *********************************************************************************************
// THE MAIN INVARIANTS:
// ===================
// The following invariant says that the voting/proposition power of a user is as it should be.
// That is, the sum of all balances of users that delegate to him, plus his balance in case 
// that he is not delegating
// *********************************************************************************************

invariant inv_voting_power_correct(address user) 
    user != 0 =>
    (
     getPowerCurrent(user, VOTING_POWER())
     ==
     rayMul_WRP(assert_uint256(sum_all_voting_delegated_power[user] +
                               ((mirror_delegationMode[user]==FULL_POWER_DELEGATED() ||
                                 mirror_delegationMode[user]==VOTING_DELEGATED()) ? 0 : mirror_balance[user])),index()) 
    )
    filtered { f -> !f.isView && f.contract == currentContract}
{
    preserved with (env e) {
        requireInvariant user_cant_voting_delegate_to_himself();
        requireInvariant sum_all_voting_delegated_power__corectness(user);
    }
}

invariant inv_proposition_power_correct(address user) 
    user != 0 =>
    (
     getPowerCurrent(user, PROPOSITION_POWER())
     ==
     rayMul_WRP(assert_uint256(sum_all_proposition_delegated_power[user] +
                               ((mirror_delegationMode[user]==FULL_POWER_DELEGATED() ||
                                 mirror_delegationMode[user]==PROPOSITION_DELEGATED()) ? 0 : mirror_balance[user])),index()) 
    )
    filtered { f -> !f.isView && f.contract == currentContract}
{
    preserved with (env e) {
        requireInvariant user_cant_proposition_delegate_to_himself();
        requireInvariant sum_all_proposition_delegated_power__corectness(user);
    }
}



