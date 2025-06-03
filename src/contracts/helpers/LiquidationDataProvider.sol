// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';

import {IPool} from '../interfaces/IPool.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IPriceOracleSentinel} from '../interfaces/IPriceOracleSentinel.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';

import {ValidationLogic} from '../protocol/libraries/logic/ValidationLogic.sol';
import {LiquidationLogic} from '../protocol/libraries/logic/LiquidationLogic.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../protocol/libraries/configuration/UserConfiguration.sol';
import {EModeConfiguration} from '../protocol/libraries/configuration/EModeConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from '../protocol/libraries/math/PercentageMath.sol';

import {ILiquidationDataProvider} from './interfaces/ILiquidationDataProvider.sol';

/**
 * @title LiquidationDataProvider
 * @author BGD Labs
 * @notice Utility contract to fetch liquidation parameters.
 */
contract LiquidationDataProvider is ILiquidationDataProvider {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  /* PUBLIC VARIABLES */

  /// @inheritdoc ILiquidationDataProvider
  IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;

  /// @inheritdoc ILiquidationDataProvider
  IPool public immutable override POOL;

  /* CONSTRUCTOR */

  constructor(address pool, address addressesProvider) {
    ADDRESSES_PROVIDER = IPoolAddressesProvider(addressesProvider);
    POOL = IPool(pool);
  }

  /* EXTERNAL AND PUBLIC FUNCTIONS */

  /// @inheritdoc ILiquidationDataProvider
  function getUserPositionFullInfo(
    address user
  ) public view override returns (UserPositionFullInfo memory) {
    UserPositionFullInfo memory userInfo;
    (
      userInfo.totalCollateralInBaseCurrency,
      userInfo.totalDebtInBaseCurrency,
      userInfo.availableBorrowsInBaseCurrency,
      userInfo.currentLiquidationThreshold,
      userInfo.ltv,
      userInfo.healthFactor
    ) = POOL.getUserAccountData(user);

    return userInfo;
  }

  /// @inheritdoc ILiquidationDataProvider
  function getCollateralFullInfo(
    address user,
    address collateralAsset
  ) external view override returns (CollateralFullInfo memory) {
    return _getCollateralFullInfo(user, collateralAsset, ADDRESSES_PROVIDER.getPriceOracle());
  }

  /// @inheritdoc ILiquidationDataProvider
  function getDebtFullInfo(
    address user,
    address debtAsset
  ) external view override returns (DebtFullInfo memory) {
    return _getDebtFullInfo(user, debtAsset, ADDRESSES_PROVIDER.getPriceOracle());
  }

  /// @inheritdoc ILiquidationDataProvider
  function getLiquidationInfo(
    address user,
    address collateralAsset,
    address debtAsset
  ) public view override returns (LiquidationInfo memory) {
    return getLiquidationInfo(user, collateralAsset, debtAsset, type(uint256).max);
  }

  /// @inheritdoc ILiquidationDataProvider
  function getLiquidationInfo(
    address user,
    address collateralAsset,
    address debtAsset,
    uint256 debtLiquidationAmount
  ) public view override returns (LiquidationInfo memory) {
    LiquidationInfo memory liquidationInfo;
    GetLiquidationInfoLocalVars memory localVars;

    liquidationInfo.userInfo = getUserPositionFullInfo(user);

    {
      address oracle = ADDRESSES_PROVIDER.getPriceOracle();
      liquidationInfo.collateralInfo = _getCollateralFullInfo(user, collateralAsset, oracle);
      liquidationInfo.debtInfo = _getDebtFullInfo(user, debtAsset, oracle);
    }

    if (liquidationInfo.debtInfo.debtBalance == 0) {
      return liquidationInfo;
    }

    if (!_canLiquidateThisHealthFactor(liquidationInfo.userInfo.healthFactor)) {
      return liquidationInfo;
    }

    DataTypes.ReserveDataLegacy memory collateralReserveData = POOL.getReserveData(collateralAsset);
    DataTypes.ReserveDataLegacy memory debtReserveData = POOL.getReserveData(debtAsset);

    if (
      !_isReserveReadyForLiquidations({
        reserveAsset: collateralAsset,
        isCollateral: true,
        reserveConfiguration: collateralReserveData.configuration
      }) ||
      !_isReserveReadyForLiquidations({
        reserveAsset: debtAsset,
        isCollateral: false,
        reserveConfiguration: debtReserveData.configuration
      })
    ) {
      return liquidationInfo;
    }

    if (!_isCollateralEnabledForUser(user, collateralReserveData.id)) {
      return liquidationInfo;
    }

    localVars.liquidationBonus = _getLiquidationBonus(
      user,
      collateralReserveData.id,
      collateralReserveData.configuration
    );

    localVars.maxDebtToLiquidate = _getMaxDebtToLiquidate(
      liquidationInfo.userInfo,
      liquidationInfo.collateralInfo,
      liquidationInfo.debtInfo,
      debtLiquidationAmount
    );

    (
      localVars.collateralAmountToLiquidate,
      localVars.debtAmountToLiquidate,
      localVars.liquidationProtocolFee
    ) = _getAvailableCollateralAndDebtToLiquidate(
      localVars.maxDebtToLiquidate,
      localVars.liquidationBonus,
      liquidationInfo.collateralInfo,
      liquidationInfo.debtInfo,
      collateralReserveData.configuration
    );

    (
      liquidationInfo.maxCollateralToLiquidate,
      liquidationInfo.maxDebtToLiquidate,
      liquidationInfo.liquidationProtocolFee
    ) = _adjustAmountsForGoodLeftovers(
      localVars.collateralAmountToLiquidate,
      localVars.debtAmountToLiquidate,
      localVars.liquidationProtocolFee,
      localVars.liquidationBonus,
      liquidationInfo.collateralInfo,
      liquidationInfo.debtInfo,
      collateralReserveData.configuration
    );

    if (
      (liquidationInfo.maxDebtToLiquidate != 0 &&
        liquidationInfo.maxDebtToLiquidate == liquidationInfo.debtInfo.debtBalance) ||
      (liquidationInfo.maxCollateralToLiquidate != 0 &&
        liquidationInfo.maxCollateralToLiquidate ==
        liquidationInfo.collateralInfo.collateralBalance)
    ) {
      liquidationInfo.amountToPassToLiquidationCall = type(uint256).max;
    } else {
      liquidationInfo.amountToPassToLiquidationCall = liquidationInfo.maxDebtToLiquidate;
    }

    return liquidationInfo;
  }

  /* PRIVATE FUNCTIONS */

  function _adjustAmountsForGoodLeftovers(
    uint256 collateralAmountToLiquidate,
    uint256 debtAmountToLiquidate,
    uint256 liquidationProtocolFee,
    uint256 liquidationBonus,
    CollateralFullInfo memory collateralInfo,
    DebtFullInfo memory debtInfo,
    DataTypes.ReserveConfigurationMap memory collateralConfiguration
  ) private pure returns (uint256, uint256, uint256) {
    AdjustAmountsForGoodLeftoversLocalVars memory localVars;

    if (
      collateralAmountToLiquidate + liquidationProtocolFee < collateralInfo.collateralBalance &&
      debtAmountToLiquidate < debtInfo.debtBalance
    ) {
      localVars.collateralLeftoverInBaseCurrency =
        ((collateralInfo.collateralBalance - collateralAmountToLiquidate - liquidationProtocolFee) *
          collateralInfo.price) /
        collateralInfo.assetUnit;

      localVars.debtLeftoverInBaseCurrency =
        ((debtInfo.debtBalance - debtAmountToLiquidate) * debtInfo.price) /
        debtInfo.assetUnit;

      if (
        localVars.collateralLeftoverInBaseCurrency < LiquidationLogic.MIN_LEFTOVER_BASE ||
        localVars.debtLeftoverInBaseCurrency < LiquidationLogic.MIN_LEFTOVER_BASE
      ) {
        localVars.collateralDecreaseAmountInBaseCurrency = localVars
          .collateralLeftoverInBaseCurrency < LiquidationLogic.MIN_LEFTOVER_BASE
          ? LiquidationLogic.MIN_LEFTOVER_BASE - localVars.collateralLeftoverInBaseCurrency
          : 0;

        localVars.debtDecreaseAmountInBaseCurrency = localVars.debtLeftoverInBaseCurrency <
          LiquidationLogic.MIN_LEFTOVER_BASE
          ? LiquidationLogic.MIN_LEFTOVER_BASE - localVars.debtLeftoverInBaseCurrency
          : 0;

        if (
          localVars.collateralDecreaseAmountInBaseCurrency >
          localVars.debtDecreaseAmountInBaseCurrency
        ) {
          localVars.collateralDecreaseAmount =
            (localVars.collateralDecreaseAmountInBaseCurrency * collateralInfo.assetUnit) /
            collateralInfo.price;

          collateralAmountToLiquidate -= localVars.collateralDecreaseAmount;

          debtAmountToLiquidate = ((collateralInfo.price *
            collateralAmountToLiquidate *
            debtInfo.assetUnit) / (debtInfo.price * collateralInfo.assetUnit)).percentDivCeil(
              liquidationBonus
            );
        } else {
          localVars.debtDecreaseAmount =
            (localVars.debtDecreaseAmountInBaseCurrency * debtInfo.assetUnit) /
            debtInfo.price;

          debtAmountToLiquidate -= localVars.debtDecreaseAmount;

          collateralAmountToLiquidate = ((debtInfo.price *
            debtAmountToLiquidate *
            collateralInfo.assetUnit) / (collateralInfo.price * debtInfo.assetUnit)).percentMul(
              liquidationBonus
            );
        }

        localVars.liquidationProtocolFeePercentage = collateralConfiguration
          .getLiquidationProtocolFee();

        if (localVars.liquidationProtocolFeePercentage != 0) {
          localVars.bonusCollateral =
            collateralAmountToLiquidate -
            collateralAmountToLiquidate.percentDiv(liquidationBonus);

          liquidationProtocolFee = localVars.bonusCollateral.percentMul(
            localVars.liquidationProtocolFeePercentage
          );

          collateralAmountToLiquidate -= liquidationProtocolFee;
        }
      }
    }

    return (collateralAmountToLiquidate, debtAmountToLiquidate, liquidationProtocolFee);
  }

  function _getAvailableCollateralAndDebtToLiquidate(
    uint256 maxDebtToLiquidate,
    uint256 liquidationBonus,
    CollateralFullInfo memory collateralInfo,
    DebtFullInfo memory debtInfo,
    DataTypes.ReserveConfigurationMap memory collateralConfiguration
  ) private pure returns (uint256, uint256, uint256) {
    uint256 liquidationProtocolFeePercentage = collateralConfiguration.getLiquidationProtocolFee();

    uint256 maxBaseCollateral = (debtInfo.price * maxDebtToLiquidate * collateralInfo.assetUnit) /
      (collateralInfo.price * debtInfo.assetUnit);

    uint256 maxCollateralToLiquidate = maxBaseCollateral.percentMul(liquidationBonus);

    uint256 collateralAmountToLiquidate;
    uint256 debtAmountToLiquidate;
    if (maxCollateralToLiquidate > collateralInfo.collateralBalance) {
      collateralAmountToLiquidate = collateralInfo.collateralBalance;

      debtAmountToLiquidate = ((collateralInfo.price *
        collateralAmountToLiquidate *
        debtInfo.assetUnit) / (debtInfo.price * collateralInfo.assetUnit)).percentDivCeil(
          liquidationBonus
        );
    } else {
      collateralAmountToLiquidate = maxCollateralToLiquidate;
      debtAmountToLiquidate = maxDebtToLiquidate;
    }

    uint256 liquidationProtocolFee;
    if (liquidationProtocolFeePercentage != 0) {
      uint256 bonusCollateral = collateralAmountToLiquidate -
        collateralAmountToLiquidate.percentDiv(liquidationBonus);

      liquidationProtocolFee = bonusCollateral.percentMul(liquidationProtocolFeePercentage);

      collateralAmountToLiquidate -= liquidationProtocolFee;
    }

    return (collateralAmountToLiquidate, debtAmountToLiquidate, liquidationProtocolFee);
  }

  function _getMaxDebtToLiquidate(
    UserPositionFullInfo memory userInfo,
    CollateralFullInfo memory collateralInfo,
    DebtFullInfo memory debtInfo,
    uint256 debtLiquidationAmount
  ) private pure returns (uint256) {
    uint256 maxDebtToLiquidate = debtInfo.debtBalance;

    if (
      collateralInfo.collateralBalanceInBaseCurrency >=
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD &&
      debtInfo.debtBalanceInBaseCurrency >= LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD &&
      userInfo.healthFactor > LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD
    ) {
      uint256 totalDefaultLiquidatableDebtInBaseCurrency = userInfo
        .totalDebtInBaseCurrency
        .percentMul(LiquidationLogic.DEFAULT_LIQUIDATION_CLOSE_FACTOR);

      if (debtInfo.debtBalanceInBaseCurrency > totalDefaultLiquidatableDebtInBaseCurrency) {
        maxDebtToLiquidate =
          (totalDefaultLiquidatableDebtInBaseCurrency * debtInfo.assetUnit) /
          debtInfo.price;
      }
    }

    return maxDebtToLiquidate < debtLiquidationAmount ? maxDebtToLiquidate : debtLiquidationAmount;
  }

  function _getLiquidationBonus(
    address user,
    uint16 collateralId,
    DataTypes.ReserveConfigurationMap memory collateralConfiguration
  ) private view returns (uint256) {
    uint256 userEModeCategory = POOL.getUserEMode(user);

    uint128 collateralBitmap = POOL.getEModeCategoryCollateralBitmap(uint8(userEModeCategory));

    if (
      userEModeCategory != 0 &&
      EModeConfiguration.isReserveEnabledOnBitmap(collateralBitmap, collateralId)
    ) {
      DataTypes.EModeCategoryLegacy memory eModeCategory = POOL.getEModeCategoryData(
        uint8(userEModeCategory)
      );

      return eModeCategory.liquidationBonus;
    } else {
      return collateralConfiguration.getLiquidationBonus();
    }
  }

  function _isCollateralEnabledForUser(
    address user,
    uint16 collateralId
  ) private view returns (bool) {
    DataTypes.UserConfigurationMap memory userConfiguration = POOL.getUserConfiguration(user);

    return userConfiguration.isUsingAsCollateral(collateralId);
  }

  function _canLiquidateThisHealthFactor(uint256 healthFactor) private view returns (bool) {
    address priceOracleSentinel = ADDRESSES_PROVIDER.getPriceOracleSentinel();

    if (healthFactor >= ValidationLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD) {
      return false;
    }

    if (
      priceOracleSentinel != address(0) &&
      healthFactor >= ValidationLogic.MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD &&
      !IPriceOracleSentinel(priceOracleSentinel).isLiquidationAllowed()
    ) {
      return false;
    }

    return true;
  }

  function _isReserveReadyForLiquidations(
    address reserveAsset,
    bool isCollateral,
    DataTypes.ReserveConfigurationMap memory reserveConfiguration
  ) private view returns (bool) {
    bool isReserveActive = reserveConfiguration.getActive();
    bool isReservePaused = reserveConfiguration.getPaused();

    bool areLiquidationsAllowed = POOL.getLiquidationGracePeriod(reserveAsset) <
      uint40(block.timestamp);

    return
      isReserveActive &&
      !isReservePaused &&
      areLiquidationsAllowed &&
      (isCollateral ? reserveConfiguration.getLiquidationThreshold() != 0 : true);
  }

  function _getCollateralFullInfo(
    address user,
    address reserveAsset,
    address oracle
  ) private view returns (CollateralFullInfo memory) {
    CollateralFullInfo memory collateralInfo;

    collateralInfo.assetUnit = 10 ** IERC20Detailed(reserveAsset).decimals();
    collateralInfo.price = IPriceOracleGetter(oracle).getAssetPrice(reserveAsset);

    collateralInfo.aToken = POOL.getReserveAToken(reserveAsset);

    collateralInfo.collateralBalance = IERC20Detailed(collateralInfo.aToken).balanceOf(user);

    collateralInfo.collateralBalanceInBaseCurrency =
      (collateralInfo.collateralBalance * collateralInfo.price) /
      collateralInfo.assetUnit;

    return collateralInfo;
  }

  function _getDebtFullInfo(
    address user,
    address reserveAsset,
    address oracle
  ) private view returns (DebtFullInfo memory) {
    DebtFullInfo memory debtInfo;

    debtInfo.assetUnit = 10 ** IERC20Detailed(reserveAsset).decimals();
    debtInfo.price = IPriceOracleGetter(oracle).getAssetPrice(reserveAsset);

    debtInfo.variableDebtToken = POOL.getReserveVariableDebtToken(reserveAsset);

    debtInfo.debtBalance = IERC20Detailed(debtInfo.variableDebtToken).balanceOf(user);

    debtInfo.debtBalanceInBaseCurrency =
      (debtInfo.debtBalance * debtInfo.price) /
      debtInfo.assetUnit;

    return debtInfo;
  }
}
