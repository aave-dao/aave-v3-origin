// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {IPool} from '../../interfaces/IPool.sol';

import {AToken} from './AToken.sol';

import {DelegationMode} from './base/DelegationMode.sol';
import {BaseDelegation} from './delegation/BaseDelegation.sol';

/**
 * @title Aave ERC20 ATokenWithDelegation
 * @author BGD Labs
 * @notice contract that gives a tokens the delegation functionality. For now should only be used for AAVE aToken
 * @dev uint sizes are used taken into account that is tailored for AAVE token. In this AToken child we only update
        delegation balances. Balances amount is taken care of by AToken contract
 */
abstract contract ATokenWithDelegation is AToken, BaseDelegation {
  using WadRayMath for uint256;

  struct ATokenDelegationState {
    uint72 delegatedPropositionBalance;
    uint72 delegatedVotingBalance;
  }

  mapping(address => ATokenDelegationState) internal _delegatedState;

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   * @param rewardsController The address of the rewards controller contract
   * @param treasury The address of the treasury. This is where accrued interest is sent.
   */
  constructor(
    IPool pool,
    address rewardsController,
    address treasury
  ) AToken(pool, rewardsController, treasury) {}

  function _getDomainSeparator() internal view override returns (bytes32) {
    return DOMAIN_SEPARATOR();
  }

  function _getDelegationState(
    address user
  ) internal view override returns (DelegationState memory) {
    return
      DelegationState({
        delegatedPropositionBalance: _delegatedState[user].delegatedPropositionBalance,
        delegatedVotingBalance: _delegatedState[user].delegatedVotingBalance,
        delegationMode: _userState[user].delegationMode
      });
  }

  function _getBalance(address user) internal view override returns (uint256) {
    return _userState[user].balance;
  }

  function _incrementNonces(address user) internal override returns (uint256) {
    unchecked {
      // Does not make sense to check because it's not realistic to reach uint256.max in nonce
      return _nonces[user]++;
    }
  }

  function _setDelegationState(
    address user,
    DelegationState memory delegationState
  ) internal override {
    _userState[user].delegationMode = delegationState.delegationMode;
    _delegatedState[user].delegatedPropositionBalance = delegationState.delegatedPropositionBalance;
    _delegatedState[user].delegatedVotingBalance = delegationState.delegatedVotingBalance;
  }

  /**
   * @notice Transfers tokens and updates delegation balances.  This function overrides the parent `_transfer`
   *         to include delegation logic. It first updates the delegation balances based on the transfer
   *         and then calls the parent's `_transfer` function to perform the actual token transfer.
   * @dev The amount is divided by the index inside this function to perform the scaling.
   * @param from The sender's address.
   * @param to The recipient's address.
   * @param amount The amount of tokens to transfer (non-scaled).
   * @param scaledAmount The amount of tokens to transfer (scaled).
   * @param index The current liquidity index of the reserve.
   */
  function _transfer(
    address from,
    address to,
    uint256 amount,
    uint120 scaledAmount,
    uint256 index
  ) internal override {
    _delegationChangeOnTransfer({
      from: from,
      to: to,
      fromBalanceBefore: _userState[from].balance,
      toBalanceBefore: _userState[to].balance,
      amount: scaledAmount
    });

    super._transfer({
      sender: from,
      recipient: to,
      amount: amount,
      scaledAmount: scaledAmount,
      index: index
    });
  }

  /**
   * @notice Overrides the parent _mint to force delegation balance transfers
   * @param account The address receiving tokens
   * @param amount The amount of tokens to mint (scaled)
   */
  function _mint(address account, uint120 amount) internal override {
    _delegationChangeOnTransfer(address(0), account, 0, _getBalance(account), amount);
    super._mint(account, amount);
  }

  /**
   * @notice Overrides the parent _burn to force delegation balance transfers
   * @param account The account whose tokens are burnt
   * @param amount The amount of tokens to burn (scaled)
   */
  function _burn(address account, uint120 amount) internal override {
    _delegationChangeOnTransfer(account, address(0), _getBalance(account), 0, amount);
    super._burn(account, amount);
  }
}
