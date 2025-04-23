// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {IPool} from '../../interfaces/IPool.sol';

import {AToken} from './AToken.sol';

import {DelegationMode} from './base/DelegationMode.sol';
import {BaseDelegation} from './delegation/BaseDelegation.sol';

/**
 * @author BGD Labs
 * @notice Designed primarily for Aave aTokens, but can potentially be adapted for other delegation scenarios.
 * @dev This contract extends the AToken contract and specifically handles delegation balances. The core token
 *      balance (principal) is managed by the parent AToken contract.
 */
abstract contract ATokenWithDelegation is AToken, BaseDelegation {
  using WadRayMath for uint256;

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   * @param rewardsController The address of the rewards controller contract
   * @param treasury The address of the treasury.  This is where accrued interest is sent.
   */
  constructor(
    IPool pool,
    address rewardsController,
    address treasury
  ) AToken(pool, rewardsController, treasury) {}

  /* INTERNAL FUNCTIONS */

  /**
   * @notice Transfers tokens and updates delegation balances.  This function overrides the parent `_transfer`
   *         to include delegation logic. It first updates the delegation balances based on the transfer
   *         and then calls the parent's `_transfer` function to perform the actual token transfer.
   * @dev The amount is divided by the index inside this function to perform the scaling.
   * @param from The sender's address.
   * @param to The recipient's address.
   * @param amount The amount of tokens to transfer (non-scaled).
   * @param index The current liquidity index of the reserve.
   */
  function _transfer(
    address from,
    address to,
    uint256 amount,
    uint256 index
  ) internal virtual override {
    _delegationChangeOnTransfer({
      from: from,
      to: to,
      fromBalanceBefore: _userState[from].balance,
      toBalanceBefore: _userState[to].balance,
      amount: uint256(amount).rayDiv(index)
    });

    super._transfer(from, to, amount, index);
  }

  /**
   * @notice Overrides the parent _mint to force delegation balance transfers
   * @param account The address receiving tokens
   * @param amount The amount of tokens to mint (scaled)
   */
  function _mint(address account, uint120 amount) internal override {
    _delegationChangeOnTransfer({
      from: address(0),
      to: account,
      fromBalanceBefore: 0,
      toBalanceBefore: _userState[account].balance,
      amount: amount
    });

    super._mint(account, amount);
  }

  /**
   * @notice Overrides the parent _burn to force delegation balance transfers
   * @param account The account whose tokens are burnt
   * @param amount The amount of tokens to burn (scaled)
   */
  function _burn(address account, uint120 amount) internal override {
    _delegationChangeOnTransfer({
      from: account,
      to: address(0),
      fromBalanceBefore: _userState[account].balance,
      toBalanceBefore: 0,
      amount: amount
    });

    super._burn(account, amount);
  }

  /* INTERNAL VIEW FUNCTIONS */

  /// @inheritdoc BaseDelegation
  function _getDomainSeparator() internal view virtual override returns (bytes32) {
    return DOMAIN_SEPARATOR();
  }

  /// @inheritdoc BaseDelegation
  function _getUserDelegationMode(
    address user
  ) internal view virtual override returns (DelegationMode) {
    return _userState[user].delegationMode;
  }

  /// @inheritdoc BaseDelegation
  function _getUserBalanceAndDelegationMode(
    address user
  ) internal view virtual override returns (uint256, DelegationMode) {
    UserState memory userState = _userState[user];

    return (userState.balance, userState.delegationMode);
  }

  /// @inheritdoc BaseDelegation
  function _setUserDelegationMode(
    address user,
    DelegationMode delegationMode
  ) internal virtual override {
    _userState[user].delegationMode = delegationMode;
  }

  /// @inheritdoc BaseDelegation
  function _incrementNonces(address user) internal virtual override returns (uint256) {
    unchecked {
      // Does not make sense to check because it's not realistic to reach uint256.max in nonce
      return _nonces[user]++;
    }
  }

  /// @inheritdoc BaseDelegation
  function _getReserveNormalizedIncome() internal view virtual override returns (uint256) {
    return POOL.getReserveNormalizedIncome(_underlyingAsset);
  }
}
