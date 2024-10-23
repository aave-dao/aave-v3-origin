// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {console} from 'forge-std/console.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {IAaveOracle} from '../../src/contracts/interfaces/IAaveOracle.sol';
import {LiquidationLogic} from '../../src/contracts/protocol/libraries/logic/LiquidationLogic.sol';
import {ReserveConfiguration} from '../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {EModeConfiguration} from '../../src/contracts/protocol/libraries/configuration/EModeConfiguration.sol';
import {DataTypes} from '../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from '../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {IERC20Detailed} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';

/**
 * @title LiquidationHelper
 * @author BGD Labs
 * @notice Utility library to be used inside tests, replicating internal contract logic via external calls.
 */
library LiquidationHelper {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /**
   * @notice Returns the required amount of borrows in base currency to reach a certain healthfactor
   */
  function _getRequiredBorrowsForHfBelow(
    IPool pool,
    address user,
    uint256 desiredHf
  ) internal view returns (uint256) {
    (uint256 totalCollateralBase, , , uint256 currentLiquidationThreshold, , ) = pool
      .getUserAccountData(user);
    return (totalCollateralBase.percentMul(currentLiquidationThreshold + 1) * 1e18) / desiredHf;
  }

  struct LocalVars {
    address user;
    uint256 liquidationBonus;
    uint256 userEMode;
    address oracle;
    address vToken;
  }

  function _getLiquidationParams(
    IPool pool,
    address user,
    address collateralAsset,
    address debtAsset,
    uint256 liquidationAmount
  ) internal view returns (uint256, uint256, uint256, uint256) {
    uint256 maxLiquidatableDebt = _getMaxLiquidatableDebt(pool, user, debtAsset);
    return
      _getLiquidationParams(
        pool,
        user,
        collateralAsset,
        debtAsset,
        liquidationAmount,
        maxLiquidatableDebt
      );
  }

  /**
   * replicates LiquidationLogic._calculateAvailableCollateralToLiquidate without direct storage access
   */
  function _getLiquidationParams(
    IPool pool,
    address user,
    address collateralAsset,
    address debtAsset,
    uint256 liquidationAmount,
    uint256 maxLiquidatableDebt
  ) internal view returns (uint256, uint256, uint256, uint256) {
    LocalVars memory local;
    local.user = user;
    maxLiquidatableDebt = liquidationAmount > maxLiquidatableDebt
      ? maxLiquidatableDebt
      : liquidationAmount;
    DataTypes.ReserveDataLegacy memory collateralReserveData = pool.getReserveData(collateralAsset);
    local.liquidationBonus = collateralReserveData.configuration.getLiquidationBonus();
    local.userEMode = pool.getUserEMode(local.user);
    if (local.userEMode != 0) {
      uint128 collateralConfig = pool.getEModeCategoryCollateralBitmap(uint8(local.userEMode));
      if (EModeConfiguration.isReserveEnabledOnBitmap(collateralConfig, collateralReserveData.id)) {
        local.liquidationBonus = pool
          .getEModeCategoryCollateralConfig(uint8(local.userEMode))
          .liquidationBonus;
      }
    }
    local.oracle = pool.ADDRESSES_PROVIDER().getPriceOracle();
    local.vToken = pool.getReserveVariableDebtToken(debtAsset);
    return
      LiquidationLogic._calculateAvailableCollateralToLiquidate(
        collateralReserveData.configuration,
        IAaveOracle(local.oracle).getAssetPrice(collateralAsset),
        10 ** IERC20Detailed(collateralReserveData.aTokenAddress).decimals(),
        IAaveOracle(local.oracle).getAssetPrice(debtAsset),
        10 ** IERC20Detailed(local.vToken).decimals(),
        maxLiquidatableDebt,
        IERC20Detailed(collateralReserveData.aTokenAddress).balanceOf(local.user),
        local.liquidationBonus
      );
  }

  function _getMaxLiquidatableDebt(
    IPool pool,
    address user,
    address debtAsset
  ) internal view returns (uint256) {
    (, uint256 totalDebtInBaseCurrency, , , , uint256 healthFactor) = pool.getUserAccountData(user);
    address oracle = pool.ADDRESSES_PROVIDER().getPriceOracle();
    address vToken = pool.getReserveVariableDebtToken(debtAsset);
    uint256 maxLiquidatableDebt = IERC20Detailed(vToken).balanceOf(user);
    uint256 debtAssetUnits = 10 ** IERC20Detailed(vToken).decimals();
    uint256 debtAssetPrice = IAaveOracle(oracle).getAssetPrice(debtAsset);
    uint256 reserveDebtInBaseCurrency = (debtAssetPrice * maxLiquidatableDebt) / debtAssetUnits;
    if (
      reserveDebtInBaseCurrency >= LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD &&
      healthFactor > LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD
    ) {
      uint256 totalDefaultLiquidatableDebtInBaseCurrency = totalDebtInBaseCurrency.percentMul(
        LiquidationLogic.DEFAULT_LIQUIDATION_CLOSE_FACTOR
      );

      if (reserveDebtInBaseCurrency > totalDefaultLiquidatableDebtInBaseCurrency) {
        maxLiquidatableDebt =
          (totalDefaultLiquidatableDebtInBaseCurrency * debtAssetUnits) /
          debtAssetPrice;
        console.log(maxLiquidatableDebt);
      }
    }
    return maxLiquidatableDebt;
  }
}
