// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {IInitializableDebtToken} from '../../interfaces/IInitializableDebtToken.sol';
import {IVariableDebtToken} from '../../interfaces/IVariableDebtToken.sol';
import {EIP712Base} from './base/EIP712Base.sol';
import {DebtTokenBase} from './base/DebtTokenBase.sol';
import {ScaledBalanceTokenBase} from './base/ScaledBalanceTokenBase.sol';

/**
 * @title VariableDebtToken
 * @author Aave
 * @notice Implements a variable debt token to track the borrowing positions of users
 * at variable rate mode
 * @dev Transfer and approve functionalities are disabled since its a non-transferable token
 */
abstract contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDebtToken {
  using WadRayMath for uint256;
  using SafeCast for uint256;

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
    uint256 scaledBalance = super.balanceOf(user);

    if (scaledBalance == 0) {
      return 0;
    }

    return scaledBalance.rayMul(POOL.getReserveNormalizedVariableDebt(_underlyingAsset));
  }

  /// @inheritdoc IVariableDebtToken
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external virtual override onlyPool returns (uint256) {
    if (user != onBehalfOf) {
      _decreaseBorrowAllowance(onBehalfOf, user, amount);
    }
    _mintScaled(user, onBehalfOf, amount, index);
    return scaledTotalSupply();
  }

  /// @inheritdoc IVariableDebtToken
  function burn(
    address from,
    uint256 amount,
    uint256 index
  ) external virtual override onlyPool returns (bool, uint256) {
    return (_burnScaled(from, address(0), amount, index), scaledTotalSupply());
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override returns (uint256) {
    return super.totalSupply().rayMul(POOL.getReserveNormalizedVariableDebt(_underlyingAsset));
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
