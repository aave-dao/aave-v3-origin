// SPDX-License-Identifier: MIT

/**
  This is an extension of the ATokenWithDelegation with added getters.
 */

pragma solidity ^0.8.0;

import {ATokenWithDelegationInstance} from 'certora/atoken-with-delegation/munged/src/contracts/instances/ATokenWithDelegationInstance.sol';
import {ScaledBalanceTokenBase} from 'certora/atoken-with-delegation/munged/src/contracts/protocol/tokenization/base/ScaledBalanceTokenBase.sol';

import {IPool} from 'certora/atoken-with-delegation/munged/src/contracts/interfaces/IPool.sol';

import {IScaledBalanceToken} from 'certora/atoken-with-delegation/munged/src/contracts/interfaces/IScaledBalanceToken.sol';
import {WadRayMath} from 'certora/atoken-with-delegation/munged/src/contracts/protocol/libraries/math/WadRayMath.sol';
import {DelegationMode} from 'certora/atoken-with-delegation/munged/src/contracts/protocol/tokenization/base/DelegationMode.sol';
import {BaseDelegation} from 'certora/atoken-with-delegation/munged/src/contracts/protocol/tokenization/delegation/BaseDelegation.sol';

contract ATokenWithDelegation_Harness is ATokenWithDelegationInstance {
  using WadRayMath for uint256;

  constructor(
    IPool pool,
    address rewardsController,
    address treasury
  ) ATokenWithDelegationInstance(pool, rewardsController, treasury) {}

  function getBalance(address user) public view returns (uint120) {
    return _userState[user].balance;
  }

  // returns user's delegated proposition balance
  function getDelegatedPropositionBalance(address user) public view returns (uint72) {
    return _getDelegationState(user).delegatedPropositionBalance;
  }

  // returns user's delegated voting balance
  function getDelegatedVotingBalance(address user) public view returns (uint72) {
    return _getDelegationState(user).delegatedVotingBalance;
  }

  //returns user's delegating proposition status
  function isDelegatingProposition(address user) public view returns (bool) {
    return
      _userState[user].delegationMode == DelegationMode.PROPOSITION_DELEGATED ||
      _userState[user].delegationMode == DelegationMode.FULL_POWER_DELEGATED;
  }

  // returns user's delegating voting status
  function isDelegatingVoting(address user) public view returns (bool) {
    return
      _userState[user].delegationMode == DelegationMode.VOTING_DELEGATED ||
      _userState[user].delegationMode == DelegationMode.FULL_POWER_DELEGATED;
  }

  // returns user's voting delegate
  function getVotingDelegatee(address user) public view returns (address) {
    return _votingDelegatee[user];
  }

  // returns user's proposition delegate
  function getPropositionDelegatee(address user) public view returns (address) {
    return _propositionDelegatee[user];
  }

  // returns user's delegation state
  function getDelegationMode(address user) public view returns (DelegationMode) {
    return _userState[user].delegationMode;
  }

  function scaledTotalSupply()
    public
    view
    override(IScaledBalanceToken, ScaledBalanceTokenBase)
    returns (uint256)
  {
    uint256 val = super.scaledTotalSupply();
    return val;
  }

  function additionalData(address user) public view returns (uint128) {
    return _userState[user].additionalData;
  }

  function scaledBalance_to_balance(uint256 bal) public view returns (uint256) {
    return bal.rayMul(POOL.getReserveNormalizedIncome(_underlyingAsset));
  }

  //The following are for the comuunity rules
  function ecrecoverWrapper(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public pure returns (address) {
    return ecrecover(hash, v, r, s);
  }
  /*    
    function computeMetaDelegateHash(address delegator, address delegatee, uint256 deadline, uint256 nonce)
        public view returns (bytes32) {
        bytes32 digest =
            ECDSA.toTypedDataHash(
                                  _getDomainSeparator(),
                                  keccak256(abi.encode(DELEGATE_TYPEHASH, delegator, delegatee, nonce, deadline))
            );
        return digest;
    }

    function computeMetaDelegateByTypeHash(
                                           address delegator,
                                           address delegatee,
                                           GovernancePowerType delegationType,
                                           uint256 deadline,
                                           uint256 nonce
    ) public view returns (bytes32) {
        bytes32 digest = ECDSA.toTypedDataHash(
                                               _getDomainSeparator(),
                                               keccak256(
                                                         abi.encode(
                                                                    DELEGATE_BY_TYPE_TYPEHASH,
                                                                    delegator,
                                                                    delegatee,
                                                                    delegationType,
                                                                    nonce,
                                                                    deadline
                                                         )
                                               )
        );
        
        return digest;
    }
    */
  function getPowerCurrent_BaseDelegation(
    address user,
    GovernancePowerType delegationType
  ) public view virtual returns (uint256) {
    return BaseDelegation.getPowerCurrent(user, delegationType);
  }

  function getNonce(address user) public view returns (uint256) {
    return _nonces[user];
  }

  function rayMul_WRP(uint256 a, uint256 b) external returns (uint256) {
    return a.rayMul(b);
  }
  function rayDiv_WRP(uint256 a, uint256 b) external returns (uint256) {
    return a.rayDiv(b);
  }
}
