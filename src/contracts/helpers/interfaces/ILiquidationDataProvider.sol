// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../interfaces/IPool.sol';

interface ILiquidationDataProvider {
  /* STRUCTS */

  struct UserPositionFullInfo {
    uint256 totalCollateralInBaseCurrency;
    uint256 totalDebtInBaseCurrency;
    uint256 availableBorrowsInBaseCurrency;
    uint256 currentLiquidationThreshold;
    uint256 ltv;
    uint256 healthFactor;
  }

  struct CollateralFullInfo {
    address aToken;
    uint256 collateralBalance;
    uint256 collateralBalanceInBaseCurrency;
    uint256 price;
    uint256 assetUnit;
  }

  struct DebtFullInfo {
    address variableDebtToken;
    uint256 debtBalance;
    uint256 debtBalanceInBaseCurrency;
    uint256 price;
    uint256 assetUnit;
  }

  struct LiquidationInfo {
    UserPositionFullInfo userInfo;
    CollateralFullInfo collateralInfo;
    DebtFullInfo debtInfo;
    uint256 maxCollateralToLiquidate;
    uint256 maxDebtToLiquidate;
    uint256 liquidationProtocolFee;
    uint256 amountToPassToLiquidationCall;
  }

  struct GetLiquidationInfoLocalVars {
    uint256 liquidationBonus;
    uint256 maxDebtToLiquidate;
    uint256 collateralAmountToLiquidate;
    uint256 debtAmountToLiquidate;
    uint256 liquidationProtocolFee;
  }

  struct AdjustAmountsForGoodLeftoversLocalVars {
    uint256 collateralLeftoverInBaseCurrency;
    uint256 debtLeftoverInBaseCurrency;
    uint256 collateralDecreaseAmountInBaseCurrency;
    uint256 debtDecreaseAmountInBaseCurrency;
    uint256 collateralDecreaseAmount;
    uint256 debtDecreaseAmount;
    uint256 liquidationProtocolFeePercentage;
    uint256 bonusCollateral;
  }

  /* PUBLIC VARIABLES */

  /// @notice The address of the PoolAddressesProvider
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /// @notice The address of the Pool
  function POOL() external view returns (IPool);

  /* EXTERNAL AND PUBLIC FUNCTIONS */

  /// @notice Returns the user position full information
  /// @param user The user address
  /// @return The user position full information
  function getUserPositionFullInfo(
    address user
  ) external view returns (UserPositionFullInfo memory);

  /// @notice Returns the collateral full information for a user
  /// @param user The user address
  /// @param collateralAsset The collateral asset address
  /// @return The collateral full information
  function getCollateralFullInfo(
    address user,
    address collateralAsset
  ) external view returns (CollateralFullInfo memory);

  /// @notice Returns the debt full information for a user
  /// @param user The user address
  /// @param debtAsset The debt asset address
  /// @return The debt full information
  function getDebtFullInfo(
    address user,
    address debtAsset
  ) external view returns (DebtFullInfo memory);

  /// @notice Returns the liquidation information for a user
  /// @param user The user address
  /// @param collateralAsset The collateral asset address
  /// @param debtAsset The debt asset address
  /// @return The liquidation information
  function getLiquidationInfo(
    address user,
    address collateralAsset,
    address debtAsset
  ) external view returns (LiquidationInfo memory);

  /// @notice Returns the liquidation information for a user for a specific max debt amount
  /// @param user The user address
  /// @param collateralAsset The collateral asset address
  /// @param debtAsset The debt asset address
  /// @param debtLiquidationAmount The maximum debt amount to be liquidated
  /// @return The liquidation information
  function getLiquidationInfo(
    address user,
    address collateralAsset,
    address debtAsset,
    uint256 debtLiquidationAmount
  ) external view returns (LiquidationInfo memory);
}
