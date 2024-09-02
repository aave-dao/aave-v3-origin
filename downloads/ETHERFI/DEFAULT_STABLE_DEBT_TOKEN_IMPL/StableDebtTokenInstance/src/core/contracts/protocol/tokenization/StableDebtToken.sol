// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {VersionedInitializable} from '../libraries/aave-upgradeability/VersionedInitializable.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IAaveIncentivesController} from '../../interfaces/IAaveIncentivesController.sol';
import {IInitializableDebtToken} from '../../interfaces/IInitializableDebtToken.sol';
import {IStableDebtToken} from '../../interfaces/IStableDebtToken.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {EIP712Base} from './base/EIP712Base.sol';
import {DebtTokenBase} from './base/DebtTokenBase.sol';
import {IncentivizedERC20} from './base/IncentivizedERC20.sol';

/**
 * @title StableDebtToken
 * @author Aave
 * @notice Implements a stable debt token to track the borrowing positions of users
 * at stable rate mode
 * @dev Transfer and approve functionalities are disabled since its a non-transferable token
 */
abstract contract StableDebtToken is DebtTokenBase, IncentivizedERC20, IStableDebtToken {
  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   */
  constructor(
    IPool pool
  ) DebtTokenBase() IncentivizedERC20(pool, 'STABLE_DEBT_TOKEN_IMPL', 'STABLE_DEBT_TOKEN_IMPL', 0) {
    // Intentionally left blank
  }

  /// @inheritdoc IInitializableDebtToken
  function initialize(
    IPool initializingPool,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external virtual;

  /// @inheritdoc IStableDebtToken
  function getAverageStableRate() external pure virtual override returns (uint256) {
    return 0;
  }

  /// @inheritdoc IStableDebtToken
  function getUserLastUpdated(address) external pure virtual override returns (uint40) {
    return 0;
  }

  /// @inheritdoc IStableDebtToken
  function getUserStableRate(address) external pure virtual override returns (uint256) {
    return 0;
  }

  /// @inheritdoc IERC20
  function balanceOf(address) public pure virtual override returns (uint256) {
    return 0;
  }

  /// @inheritdoc IStableDebtToken
  function mint(
    address,
    address,
    uint256,
    uint256
  ) external virtual override onlyPool returns (bool, uint256, uint256) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  /// @inheritdoc IStableDebtToken
  function burn(address, uint256) external virtual override onlyPool returns (uint256, uint256) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  /// @inheritdoc IStableDebtToken
  function getSupplyData() external pure override returns (uint256, uint256, uint256, uint40) {
    return (0, 0, 0, 0);
  }

  /// @inheritdoc IStableDebtToken
  function getTotalSupplyAndAvgRate() external pure override returns (uint256, uint256) {
    return (0, 0);
  }

  /// @inheritdoc IERC20
  function totalSupply() public pure virtual override returns (uint256) {
    return 0;
  }

  /// @inheritdoc IStableDebtToken
  function getTotalSupplyLastUpdated() external pure override returns (uint40) {
    return 0;
  }

  /// @inheritdoc IStableDebtToken
  function principalBalanceOf(address) external pure virtual override returns (uint256) {
    return 0;
  }

  /// @inheritdoc IStableDebtToken
  function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
    return _underlyingAsset;
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
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function allowance(address, address) external view virtual override returns (uint256) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function approve(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function transferFrom(address, address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function increaseAllowance(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function decreaseAllowance(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }
}
