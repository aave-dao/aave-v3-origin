/*
    This is a base spec file that includes methods declarations, definitions
    and functions to be included in other spec. There are no rules in this file.
    For more information, visit: https://www.certora.com/

*/

/*

    Declaration of methods of the Aave token contract (and harness)

*/ 

methods {
    function totalSupply()                         external returns (uint256)   envfree;
    function scaledTotalSupply()                   external returns (uint256)   envfree;
    function balanceOf(address)                    external returns (uint256)   envfree;
    function scaledBalanceOf(address)              external returns (uint256)   envfree;
    function allowance(address,address)            external returns (uint256)   envfree;
    function increaseAllowance(address, uint256) external;
    function decreaseAllowance(address, uint256) external;
    function transfer(address,uint256) external;
    function transferFrom(address,address,uint256) external;
    function permit(address,address,uint256,uint256,uint8,bytes32,bytes32) external;

    function getBalance(address user) external returns (uint120) envfree;
    function delegate(address delegatee) external;
    function metaDelegate(address,address,uint256,uint8,bytes32,bytes32) external;
    function metaDelegateByType(address,address,uint8,uint256,uint8,bytes32,bytes32) external;
    function getPowerCurrent(address, IBaseDelegation.GovernancePowerType) external returns (uint256) envfree;

    //function getBalance(address user) external returns (uint104) envfree;
    function getDelegatedPropositionBalance(address user) external returns (uint72) envfree;
    function getDelegatedVotingBalance(address user) external returns (uint72) envfree;
    function isDelegatingProposition(address user) external returns (bool) envfree;
    function isDelegatingVoting(address user) external returns (bool) envfree;
    function getVotingDelegatee(address user) external returns (address) envfree;
    function getPropositionDelegatee(address user) external returns (address) envfree;
    function getDelegationMode(address user) external returns (ATokenWithDelegation_Harness.DelegationMode) envfree;

    function POWER_SCALE_FACTOR() external returns (uint256) envfree;
}

definition VOTING_POWER() returns IBaseDelegation.GovernancePowerType = IBaseDelegation.GovernancePowerType.VOTING;
definition PROPOSITION_POWER() returns IBaseDelegation.GovernancePowerType = IBaseDelegation.GovernancePowerType.PROPOSITION;
definition FACTOR() returns uint256 = POWER_SCALE_FACTOR();

/**

    Definitions of delegation modes

*/
definition NO_DELEGATION()
  returns ATokenWithDelegation_Harness.DelegationMode = ATokenWithDelegation_Harness.DelegationMode.NO_DELEGATION;
definition VOTING_DELEGATED()
  returns ATokenWithDelegation_Harness.DelegationMode = ATokenWithDelegation_Harness.DelegationMode.VOTING_DELEGATED;
definition PROPOSITION_DELEGATED()
  returns ATokenWithDelegation_Harness.DelegationMode = ATokenWithDelegation_Harness.DelegationMode.PROPOSITION_DELEGATED;
definition FULL_POWER_DELEGATED()
  returns ATokenWithDelegation_Harness.DelegationMode = ATokenWithDelegation_Harness.DelegationMode.FULL_POWER_DELEGATED;
definition DELEGATING_VOTING(ATokenWithDelegation_Harness.DelegationMode mode) returns bool = 
    mode == VOTING_DELEGATED() || mode == FULL_POWER_DELEGATED();
definition DELEGATING_PROPOSITION(ATokenWithDelegation_Harness.DelegationMode mode) returns bool =
    mode == PROPOSITION_DELEGATED() || mode == FULL_POWER_DELEGATED();

definition AAVE_MAX_SUPPLY() returns uint256 = 16000000 * 10^18;
definition SCALED_MAX_SUPPLY() returns mathint = AAVE_MAX_SUPPLY() / FACTOR();


/**

    Functions

*/

function normalize(uint256 amount) returns mathint {
    return amount / FACTOR() * FACTOR();
}

function validDelegationMode(address user) returns bool {
    ATokenWithDelegation_Harness.DelegationMode state = getDelegationMode(user);
    return state == ATokenWithDelegation_Harness.DelegationMode.NO_DELEGATION ||
        state == ATokenWithDelegation_Harness.DelegationMode.VOTING_DELEGATED ||
        state == ATokenWithDelegation_Harness.DelegationMode.PROPOSITION_DELEGATED ||
        state == ATokenWithDelegation_Harness.DelegationMode.FULL_POWER_DELEGATED;
}

function validAmount(uint256 amt) returns bool {
    return amt < AAVE_MAX_SUPPLY();
}

definition RAY() returns uint256 = 10^27;

function rayMulCVL(uint256 a, uint256 b) returns mathint {
  mathint ret = (a*b + RAY()/2) / RAY();
  return ret;
}

function rayDivCVL(uint256 a, uint256 b) returns mathint {
  mathint ret = (a*RAY()+b/2) / b;
  return ret;
}

