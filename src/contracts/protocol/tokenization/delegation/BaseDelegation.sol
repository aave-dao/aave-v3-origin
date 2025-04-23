// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MessageHashUtils} from 'openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

import {WadRayMath} from '../../libraries/math/WadRayMath.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';

import {IBaseDelegation} from './interfaces/IBaseDelegation.sol';
import {DelegationMode} from '../base/DelegationMode.sol';

/**
 * @notice The contract implements generic delegation functionality for the upcoming governance v3
 * @author BGD Labs
 * @dev to make it's pluggable to any exising token it has a set of virtual functions
 *   for simple access to balances and permit functionality
 * @dev ************ IMPORTANT SECURITY CONSIDERATION ************
 *   current version of the token can be used only with asset which has 18 decimals
 *   and possible totalSupply lower then 4722366482869645213696,
 *   otherwise at least POWER_SCALE_FACTOR should be adjusted !!!
 *   *************************************************************
 */
abstract contract BaseDelegation is IBaseDelegation {
  using WadRayMath for uint256;

  /* STRUCTS */

  /// @notice Stores delegation balances, scaled to a maximum of 8 decimals.
  /// @dev Amounts will be divided by the `POWER_SCALE_FACTOR` global variable
  struct DelegationState {
    uint72 delegatedPropositionBalance;
    uint72 delegatedVotingBalance;
  }

  uint256 public constant POWER_SCALE_FACTOR = 1e10;

  mapping(address => address) internal _votingDelegatee;
  mapping(address => address) internal _propositionDelegatee;

  mapping(address => DelegationState) private _delegationState;

  bytes32 public constant DELEGATE_BY_TYPE_TYPEHASH =
    keccak256(
      'DelegateByType(address delegator,address delegatee,uint8 delegationType,uint256 nonce,uint256 deadline)'
    );
  bytes32 public constant DELEGATE_TYPEHASH =
    keccak256('Delegate(address delegator,address delegatee,uint256 nonce,uint256 deadline)');

  /**
   * @notice returns eip-2612 compatible domain separator
   * @dev we expect that existing tokens, ie Aave, already have, so we want to reuse
   * @return domain separator
   */
  function _getDomainSeparator() internal view virtual returns (bytes32);

  /**
   * @notice Retrieves the delegation mode of a specific user.
   * @param user The address of the user whose delegation mode is being queried.
   */
  function _getUserDelegationMode(address user) internal view virtual returns (DelegationMode);

  /**
   * @notice Retrieves both the scaled balance and delegation mode of a specific user.
   * @param user The address of the user whose balance and delegation mode are being queried.
   */
  function _getUserBalanceAndDelegationMode(
    address user
  ) internal view virtual returns (uint256, DelegationMode);

  /**
   * @notice Sets the delegation mode for a specific user.
   * @param user The address of the user whose delegation mode is being set.
   * @param delegationMode The new delegation mode to set for the user (a `DelegationMode` enum value).
   */
  function _setUserDelegationMode(address user, DelegationMode delegationMode) internal virtual;

  /**
   * @notice increases and return the current nonce of a user
   * @dev should use `return nonce++;` pattern
   * @param user address
   * @return current nonce before increase
   */
  function _incrementNonces(address user) internal virtual returns (uint256);

  /**
   * @notice Retrieves the normalized income of the underlying asset's reserve.
   * @dev This function fetches the current normalized income from the Pool contract,
   *      representing the accumulated interest for the underlying asset.
   */
  function _getReserveNormalizedIncome() internal view virtual returns (uint256);

  /// @inheritdoc IBaseDelegation
  function delegateByType(
    address delegatee,
    GovernancePowerType delegationType
  ) external virtual override {
    _delegateByType({delegator: msg.sender, delegatee: delegatee, delegationType: delegationType});
  }

  /// @inheritdoc IBaseDelegation
  function delegate(address delegatee) external override {
    _delegateByType({
      delegator: msg.sender,
      delegatee: delegatee,
      delegationType: GovernancePowerType.VOTING
    });
    _delegateByType({
      delegator: msg.sender,
      delegatee: delegatee,
      delegationType: GovernancePowerType.PROPOSITION
    });
  }

  /// @inheritdoc IBaseDelegation
  function getDelegateeByType(
    address delegator,
    GovernancePowerType delegationType
  ) external view override returns (address) {
    return
      _getDelegateeByType({
        delegator: delegator,
        delegatorDelegationMode: _getUserDelegationMode(delegator),
        delegationType: delegationType
      });
  }

  /// @inheritdoc IBaseDelegation
  function getDelegates(address delegator) external view override returns (address, address) {
    DelegationMode delegatorDelegationMode = _getUserDelegationMode(delegator);

    return (
      _getDelegateeByType({
        delegator: delegator,
        delegatorDelegationMode: delegatorDelegationMode,
        delegationType: GovernancePowerType.VOTING
      }),
      _getDelegateeByType({
        delegator: delegator,
        delegatorDelegationMode: delegatorDelegationMode,
        delegationType: GovernancePowerType.PROPOSITION
      })
    );
  }

  /// @inheritdoc IBaseDelegation
  function getPowerCurrent(
    address user,
    GovernancePowerType delegationType
  ) public view virtual override returns (uint256) {
    (uint256 userBalance, DelegationMode userDelegationMode) = _getUserBalanceAndDelegationMode(
      user
    );

    uint256 scaledUserOwnPower = uint8(userDelegationMode) & (uint8(delegationType) + 1) == 0
      ? userBalance
      : 0;

    uint256 scaledUserDelegatedPower = _getDelegatedPowerByType(user, delegationType);

    return (scaledUserOwnPower + scaledUserDelegatedPower).rayMul(_getReserveNormalizedIncome());
  }

  /// @inheritdoc IBaseDelegation
  function getPowersCurrent(address user) external view override returns (uint256, uint256) {
    return (
      getPowerCurrent(user, GovernancePowerType.VOTING),
      getPowerCurrent(user, GovernancePowerType.PROPOSITION)
    );
  }

  /// @inheritdoc IBaseDelegation
  function metaDelegateByType(
    address delegator,
    address delegatee,
    GovernancePowerType delegationType,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(delegator != address(0), Errors.ZeroAddressNotValid());
    //solium-disable-next-line
    require(block.timestamp <= deadline, Errors.InvalidExpiration());

    bytes32 digest = MessageHashUtils.toTypedDataHash(
      _getDomainSeparator(),
      keccak256(
        abi.encode(
          DELEGATE_BY_TYPE_TYPEHASH,
          delegator,
          delegatee,
          delegationType,
          _incrementNonces(delegator),
          deadline
        )
      )
    );

    require(delegator == ecrecover(digest, v, r, s), Errors.InvalidSignature());

    _delegateByType(delegator, delegatee, delegationType);
  }

  /// @inheritdoc IBaseDelegation
  function metaDelegate(
    address delegator,
    address delegatee,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(delegator != address(0), Errors.ZeroAddressNotValid());
    //solium-disable-next-line
    require(block.timestamp <= deadline, Errors.InvalidExpiration());

    bytes32 digest = MessageHashUtils.toTypedDataHash(
      _getDomainSeparator(),
      keccak256(
        abi.encode(DELEGATE_TYPEHASH, delegator, delegatee, _incrementNonces(delegator), deadline)
      )
    );

    require(delegator == ecrecover(digest, v, r, s), Errors.InvalidSignature());

    _delegateByType(delegator, delegatee, GovernancePowerType.VOTING);
    _delegateByType(delegator, delegatee, GovernancePowerType.PROPOSITION);
  }

  /**
   * @dev Modifies the delegated power of a `delegatee` account by type (VOTING, PROPOSITION).
   * Passing the impact on the delegation of `delegatee` account before and after to reduce conditionals and not lose
   * any precision.
   * @param impactOnDelegationBefore how much impact a balance of another account had over the delegation of a `delegatee`
   * before an action.
   * For example, if the action is a delegation from one account to another, the impact before the action will be 0.
   * @param impactOnDelegationAfter how much impact a balance of another account will have  over the delegation of a `delegatee`
   * after an action.
   * For example, if the action is a delegation from one account to another, the impact after the action will be the whole balance
   * of the account changing the delegatee.
   * @param delegatee the user whom delegated governance power will be changed
   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
   **/
  function _governancePowerTransferByType(
    uint256 impactOnDelegationBefore,
    uint256 impactOnDelegationAfter,
    address delegatee,
    GovernancePowerType delegationType
  ) internal {
    if (delegatee == address(0)) return;
    if (impactOnDelegationBefore == impactOnDelegationAfter) return;

    uint72 impactOnDelegationBefore72 = SafeCast.toUint72(
      impactOnDelegationBefore / POWER_SCALE_FACTOR
    );
    uint72 impactOnDelegationAfter72 = SafeCast.toUint72(
      impactOnDelegationAfter / POWER_SCALE_FACTOR
    );

    if (delegationType == GovernancePowerType.VOTING) {
      _delegationState[delegatee].delegatedVotingBalance =
        _delegationState[delegatee].delegatedVotingBalance -
        impactOnDelegationBefore72 +
        impactOnDelegationAfter72;
    } else {
      _delegationState[delegatee].delegatedPropositionBalance =
        _delegationState[delegatee].delegatedPropositionBalance -
        impactOnDelegationBefore72 +
        impactOnDelegationAfter72;
    }
  }

  /**
   * @dev performs all state changes related delegation changes on transfer
   * @param from token sender
   * @param to token recipient
   * @param fromBalanceBefore balance of the sender before transfer
   * @param toBalanceBefore balance of the recipient before transfer
   * @param amount amount of tokens sent
   **/
  function _delegationChangeOnTransfer(
    address from,
    address to,
    uint256 fromBalanceBefore,
    uint256 toBalanceBefore,
    uint256 amount
  ) internal {
    if (from == to) {
      return;
    }

    if (from != address(0)) {
      DelegationMode fromUserDelegationMode = _getUserDelegationMode(from);

      if (fromUserDelegationMode != DelegationMode.NO_DELEGATION) {
        uint256 fromBalanceAfter = fromBalanceBefore - amount;

        _governancePowerTransferByType({
          impactOnDelegationBefore: fromBalanceBefore,
          impactOnDelegationAfter: fromBalanceAfter,
          delegatee: _getDelegateeByType({
            delegator: from,
            delegatorDelegationMode: fromUserDelegationMode,
            delegationType: GovernancePowerType.VOTING
          }),
          delegationType: GovernancePowerType.VOTING
        });
        _governancePowerTransferByType({
          impactOnDelegationBefore: fromBalanceBefore,
          impactOnDelegationAfter: fromBalanceAfter,
          delegatee: _getDelegateeByType({
            delegator: from,
            delegatorDelegationMode: fromUserDelegationMode,
            delegationType: GovernancePowerType.PROPOSITION
          }),
          delegationType: GovernancePowerType.PROPOSITION
        });
      }
    }

    if (to != address(0)) {
      DelegationMode toUserDelegationMode = _getUserDelegationMode(to);

      if (toUserDelegationMode != DelegationMode.NO_DELEGATION) {
        uint256 toBalanceAfter = toBalanceBefore + amount;

        _governancePowerTransferByType({
          impactOnDelegationBefore: toBalanceBefore,
          impactOnDelegationAfter: toBalanceAfter,
          delegatee: _getDelegateeByType({
            delegator: to,
            delegatorDelegationMode: toUserDelegationMode,
            delegationType: GovernancePowerType.VOTING
          }),
          delegationType: GovernancePowerType.VOTING
        });
        _governancePowerTransferByType({
          impactOnDelegationBefore: toBalanceBefore,
          impactOnDelegationAfter: toBalanceAfter,
          delegatee: _getDelegateeByType({
            delegator: to,
            delegatorDelegationMode: toUserDelegationMode,
            delegationType: GovernancePowerType.PROPOSITION
          }),
          delegationType: GovernancePowerType.PROPOSITION
        });
      }
    }
  }

  /**
   * @dev Extracts from state and returns delegated governance power (Voting, Proposition)
   * @param user the current user
   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
   **/
  function _getDelegatedPowerByType(
    address user,
    GovernancePowerType delegationType
  ) internal view returns (uint256) {
    return
      POWER_SCALE_FACTOR *
      (
        delegationType == GovernancePowerType.VOTING
          ? _delegationState[user].delegatedVotingBalance
          : _delegationState[user].delegatedPropositionBalance
      );
  }

  /**
   * @dev Extracts from state and returns the delegatee of a delegator by type of governance power (Voting, Proposition)
   * - If the delegator doesn't have any delegatee, returns address(0)
   * @param delegator delegator
   * @param delegatorDelegationMode the current delegation mode of a user
   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
   **/
  function _getDelegateeByType(
    address delegator,
    DelegationMode delegatorDelegationMode,
    GovernancePowerType delegationType
  ) internal view returns (address) {
    if (delegationType == GovernancePowerType.VOTING) {
      return
        /// With the & operation, we cover both VOTING_DELEGATED delegation and FULL_POWER_DELEGATED
        /// as VOTING_DELEGATED is equivalent to 01 in binary and FULL_POWER_DELEGATED is equivalent to 11
        (uint8(delegatorDelegationMode) & uint8(DelegationMode.VOTING_DELEGATED)) != 0
          ? _votingDelegatee[delegator]
          : address(0);
    }
    return
      delegatorDelegationMode >= DelegationMode.PROPOSITION_DELEGATED
        ? _propositionDelegatee[delegator]
        : address(0);
  }

  /**
   * @dev Updates the specific flag which signaling about existence of delegation of governance power (Voting, Proposition)
   * @param user a user to change delegation mode
   * @param userDelegationMode the current delegation mode of a user
   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
   * @param willDelegate next state of delegation
   **/
  function _updateDelegationModeByType(
    address user,
    DelegationMode userDelegationMode,
    GovernancePowerType delegationType,
    bool willDelegate
  ) internal {
    DelegationMode newUserDelegationMode;

    if (willDelegate) {
      // Because GovernancePowerType starts from 0, we should add 1 first, then we apply bitwise OR
      newUserDelegationMode = DelegationMode(
        uint8(userDelegationMode) | (uint8(delegationType) + 1)
      );
    } else {
      // First bitwise NEGATION, ie was 01, after XOR with 11 will be 10,
      // then bitwise AND, which means it will keep only another delegation type if it exists
      newUserDelegationMode = DelegationMode(
        uint8(userDelegationMode) &
          ((uint8(delegationType) + 1) ^ uint8(DelegationMode.FULL_POWER_DELEGATED))
      );
    }

    _setUserDelegationMode(user, newUserDelegationMode);
  }

  /**
   * @dev This is the equivalent of an ERC20 transfer(), but for a power type: an atomic transfer of a balance (power).
   * When needed, it decreases the power of the `delegator` and when needed, it increases the power of the `delegatee`
   * @param delegator delegator
   * @param delegatee the user which delegated power will change
   * @param delegationType the type of delegation (VOTING, PROPOSITION)
   **/
  function _delegateByType(
    address delegator,
    address delegatee,
    GovernancePowerType delegationType
  ) internal {
    // Here we unify the property that delegating power to address(0) == delegating power to yourself == no delegation
    // So from now on, not being delegating is (exclusively) that delegatee == address(0)
    address _delegatee = delegatee == delegator ? address(0) : delegatee;

    (
      uint256 delegatorBalance,
      DelegationMode delegatorDelegationMode
    ) = _getUserBalanceAndDelegationMode(delegator);

    address currentDelegatee = _getDelegateeByType({
      delegator: delegator,
      delegatorDelegationMode: delegatorDelegationMode,
      delegationType: delegationType
    });
    if (_delegatee == currentDelegatee) return;

    bool delegatingNow = currentDelegatee != address(0);
    bool willDelegateAfter = _delegatee != address(0);

    if (delegatingNow) {
      _governancePowerTransferByType({
        impactOnDelegationBefore: delegatorBalance,
        impactOnDelegationAfter: 0,
        delegatee: currentDelegatee,
        delegationType: delegationType
      });
    }

    if (willDelegateAfter) {
      _governancePowerTransferByType({
        impactOnDelegationBefore: 0,
        impactOnDelegationAfter: delegatorBalance,
        delegatee: _delegatee,
        delegationType: delegationType
      });
    }

    if (delegationType == GovernancePowerType.VOTING) {
      _votingDelegatee[delegator] = _delegatee;
    } else {
      _propositionDelegatee[delegator] = _delegatee;
    }

    if (willDelegateAfter != delegatingNow) {
      _updateDelegationModeByType({
        user: delegator,
        userDelegationMode: delegatorDelegationMode,
        delegationType: delegationType,
        willDelegate: willDelegateAfter
      });
    }

    emit DelegateChanged(delegator, _delegatee, delegationType);
  }
}
