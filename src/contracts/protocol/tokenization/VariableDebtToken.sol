// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {IInitializableDebtToken} from '../../interfaces/IInitializableDebtToken.sol';
import {IVariableDebtToken} from '../../interfaces/IVariableDebtToken.sol';
import {EIP712Base} from './base/EIP712Base.sol';
import {DebtTokenBase} from './base/DebtTokenBase.sol';
import {ScaledBalanceTokenBase} from './base/ScaledBalanceTokenBase.sol';
import {TokenMath} from '../libraries/helpers/TokenMath.sol';

/**
 * @title VariableDebtToken
 * @author Aave
 * @notice Implements a variable debt token to track the borrowing positions of users
 * at variable rate mode
 * @dev Transfer and approve functionalities are disabled since its a non-transferable token
 */
abstract contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDebtToken {
  using TokenMath for uint256;
  using SafeCast for uint256;

  // @note This gap is made only to add the `__DEPRECATED_AND_NEVER_TO_BE_REUSED` variable
  // The length of this gap can be decreased in order to add new variables
  uint256[3] private __unusedGap;

  // @note deprecated in v3.4.0 upgrade in the GHO vToken.
  // This storage slot can't be used in all vTokens, because the GHO vToken
  // had a mapping here (before v3.4.0) and right now has some non-zero mapping values in this slot.
  // old version: mapping(address => GhoUserState) internal _ghoUserState
  // This storage slot MUST NOT be reused to avoid storage layout conflicts.
  bytes32 private __DEPRECATED_AND_NEVER_TO_BE_REUSED;

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   * @param rewardsController The address of the rewards controller contract
   */
  constructor(
    IPool pool,
    address rewardsController
  )
    DebtTokenBase()
    ScaledBalanceTokenBase(
      pool,
      'VARIABLE_DEBT_TOKEN_IMPL',
      'VARIABLE_DEBT_TOKEN_IMPL',
      0,
      rewardsController
    )
  {
    // Intentionally left blank
  }

  /// @inheritdoc IInitializableDebtToken
  function initialize(
    IPool initializingPool,
    address underlyingAsset,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external virtual;

  /// @inheritdoc IERC20
  function balanceOf(address user) public view virtual override returns (uint256) {
    return
      super.balanceOf(user).getVTokenBalance(
        POOL.getReserveNormalizedVariableDebt(_underlyingAsset)
      );
  }

  /// @inheritdoc IVariableDebtToken
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 scaledAmount,
    uint256 index
  ) external virtual override onlyPool returns (uint256) {
    if (user != onBehalfOf) {
      uint256 borrowAllowance = _borrowAllowances[onBehalfOf][user];
      if (borrowAllowance < amount) {
        revert InsufficientBorrowAllowance(user, borrowAllowance, amount);
      }
      // When borrowing on behalf of a user, the borrower specified an "amount", which is measured in the underlying the user wants to receive.
      // The protocol internally works, with a "scaled down" representation of the amount, which in most cases loses precision.
      // In practice this means that when borrowing `n`, the user might receive `n+m` debt.
      // Similar to the aToken `transferFrom` function, handling this scenario exactly is impossible.
      // While this problem is not solvable without introducing breaking changes, on Aave v3.5 the situation is improved in the following way:
      // - The `correct` amount to be deducted is considered to be `scaledUpCeil(scaledAmount)`. This replicates the behavior on borrow followed by a balanceOf.
      // - To avoid breaking existing integrations, the amount deducted from the allowance is the minimum of the available allowance and the actual up-scaled debt amount.
      uint256 scaledUp = scaledAmount.getVTokenBalance(index);
      _decreaseBorrowAllowance(
        onBehalfOf,
        user,
        borrowAllowance >= scaledUp ? scaledUp : borrowAllowance
      );
    }
    _mintScaled({
      caller: user,
      onBehalfOf: onBehalfOf,
      amountScaled: scaledAmount,
      index: index,
      getTokenBalance: TokenMath.getVTokenBalance
    });
    return scaledTotalSupply();
  }

  /// @inheritdoc IVariableDebtToken
  function burn(
    address from,
    uint256 scaledAmount,
    uint256 index
  ) external virtual override onlyPool returns (bool, uint256) {
    return (
      _burnScaled({
        user: from,
        target: address(0),
        amountScaled: scaledAmount,
        index: index,
        getTokenBalance: TokenMath.getVTokenBalance
      }),
      scaledTotalSupply()
    );
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override returns (uint256) {
    return
      super.totalSupply().getVTokenBalance(POOL.getReserveNormalizedVariableDebt(_underlyingAsset));
  }

  /// @inheritdoc EIP712Base
  function _EIP712BaseId() internal view override returns (string memory) {
    return name();
  }

  /**
   * @dev Being non transferrable, the debt token does not implement any of the
   * standard ERC20 functions for transfer and allowance.
   */
  function transfer(address, uint256) external virtual override returns (bool) {
    revert Errors.OperationNotSupported();
  }

  function allowance(address, address) external view virtual override returns (uint256) {
    revert Errors.OperationNotSupported();
  }

  function approve(address, uint256) external virtual override returns (bool) {
    revert Errors.OperationNotSupported();
  }

  function transferFrom(address, address, uint256) external virtual override returns (bool) {
    revert Errors.OperationNotSupported();
  }

  function increaseAllowance(address, uint256) external virtual override returns (bool) {
    revert Errors.OperationNotSupported();
  }

  function decreaseAllowance(address, uint256) external virtual override returns (bool) {
    revert Errors.OperationNotSupported();
  }

  /// @inheritdoc IVariableDebtToken
  function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
    return _underlyingAsset;
  }
}
