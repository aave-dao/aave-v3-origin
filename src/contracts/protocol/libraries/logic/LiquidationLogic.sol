// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts//IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {PercentageMath} from '../../libraries/math/PercentageMath.sol';
import {WadRayMath} from '../../libraries/math/WadRayMath.sol';
import {DataTypes} from '../../libraries/types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {GenericLogic} from './GenericLogic.sol';
import {IsolationModeLogic} from './IsolationModeLogic.sol';
import {EModeLogic} from './EModeLogic.sol';
import {UserConfiguration} from '../../libraries/configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../../libraries/configuration/ReserveConfiguration.sol';
import {EModeConfiguration} from '../../libraries/configuration/EModeConfiguration.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';
import {Errors} from '../helpers/Errors.sol';

/**
 * @title LiquidationLogic library
 * @author Aave
 * @notice Implements actions involving management of collateral in the protocol, the main one being the liquidations
 */
library LiquidationLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using GPv2SafeERC20 for IERC20;
  using SafeCast for uint256;

  // See `IPool` for descriptions
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
  event DeficitCreated(address indexed user, address indexed debtAsset, uint256 amount);
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Default percentage of borrower's debt to be repaid in a liquidation.
   * @dev Percentage applied when the users health factor is above `CLOSE_FACTOR_HF_THRESHOLD`
   * Expressed in bps, a value of 0.5e4 results in 50.00%
   */
  uint256 internal constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 0.5e4;

  /**
   * @dev This constant represents the upper bound on the health factor, below(inclusive) which the full amount of debt becomes liquidatable.
   * A value of 0.95e18 results in 0.95
   */
  uint256 public constant CLOSE_FACTOR_HF_THRESHOLD = 0.95e18;

  /**
   * @dev This constant represents a base value threshold.
   * If the total collateral or debt on a position is below this threshold, the close factor is raised to 100%.
   * @notice The default value assumes that the basePrice is usd denominated by 8 decimals and needs to be adjusted in a non USD-denominated pool.
   */
  uint256 public constant MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD = 2000e8;

  /**
   * @dev This constant represents the minimum amount of assets in base currency that need to be leftover after a liquidation, if not clearing a position completely.
   * This parameter is inferred from MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD as the logic is dependent.
   * Assuming a MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD of `n` a liquidation of `n+1` might result in `n/2` leftover which is assumed to be still economically liquidatable.
   * This mechanic was introduced to ensure liquidators don't optimize gas by leaving some wei on the liquidation.
   */
  uint256 public constant MIN_LEFTOVER_BASE = MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD / 2;

  struct LiquidationCallLocalVars {
    uint256 userCollateralBalance;
    uint256 userReserveDebt;
    uint256 actualDebtToLiquidate;
    uint256 actualCollateralToLiquidate;
    uint256 liquidationBonus;
    uint256 healthFactor;
    uint256 liquidationProtocolFeeAmount;
    uint256 totalCollateralInBaseCurrency;
    uint256 totalDebtInBaseCurrency;
    uint256 collateralToLiquidateInBaseCurrency;
    uint256 userReserveDebtInBaseCurrency;
    uint256 debtToRepayInBaseCurrency;
    uint256 collateralAssetPrice;
    uint256 debtAssetPrice;
    uint256 collateralAssetUnit;
    uint256 debtAssetUnit;
    IAToken collateralAToken;
    DataTypes.ReserveCache debtReserveCache;
  }

  /**
   * @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
   * covers `debtToCover` amount of debt of the user getting liquidated, and receives
   * a proportional amount of the `collateralAsset` plus a bonus to cover market risk
   * @dev Emits the `LiquidationCall()` event, and the `DeficitCreated()` event if the liquidation results in bad debt
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param params The additional parameters needed to execute the liquidation function
   */
  function executeLiquidationCall(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.ExecuteLiquidationCallParams memory params
  ) external {
    LiquidationCallLocalVars memory vars;

    DataTypes.ReserveData storage collateralReserve = reservesData[params.collateralAsset];
    DataTypes.ReserveData storage debtReserve = reservesData[params.debtAsset];
    DataTypes.UserConfigurationMap storage userConfig = usersConfig[params.user];
    vars.debtReserveCache = debtReserve.cache();
    debtReserve.updateState(vars.debtReserveCache);

    (
      vars.totalCollateralInBaseCurrency,
      vars.totalDebtInBaseCurrency,
      ,
      ,
      vars.healthFactor,

    ) = GenericLogic.calculateUserAccountData(
      reservesData,
      reservesList,
      eModeCategories,
      DataTypes.CalculateUserAccountDataParams({
        userConfig: userConfig,
        reservesCount: params.reservesCount,
        user: params.user,
        oracle: params.priceOracle,
        userEModeCategory: params.userEModeCategory
      })
    );

    vars.collateralAToken = IAToken(collateralReserve.aTokenAddress);
    vars.userCollateralBalance = vars.collateralAToken.balanceOf(params.user);
    vars.userReserveDebt = IERC20(vars.debtReserveCache.variableDebtTokenAddress).balanceOf(
      params.user
    );

    ValidationLogic.validateLiquidationCall(
      userConfig,
      collateralReserve,
      debtReserve,
      DataTypes.ValidateLiquidationCallParams({
        debtReserveCache: vars.debtReserveCache,
        totalDebt: vars.userReserveDebt,
        healthFactor: vars.healthFactor,
        priceOracleSentinel: params.priceOracleSentinel
      })
    );

    if (
      params.userEModeCategory != 0 &&
      EModeConfiguration.isReserveEnabledOnBitmap(
        eModeCategories[params.userEModeCategory].collateralBitmap,
        collateralReserve.id
      )
    ) {
      vars.liquidationBonus = eModeCategories[params.userEModeCategory].liquidationBonus;
    } else {
      vars.liquidationBonus = collateralReserve.configuration.getLiquidationBonus();
    }
    vars.collateralAssetPrice = IPriceOracleGetter(params.priceOracle).getAssetPrice(
      params.collateralAsset
    );
    vars.debtAssetPrice = IPriceOracleGetter(params.priceOracle).getAssetPrice(params.debtAsset);
    vars.collateralAssetUnit = 10 ** collateralReserve.configuration.getDecimals();
    vars.debtAssetUnit = 10 ** vars.debtReserveCache.reserveConfiguration.getDecimals();

    vars.userReserveDebtInBaseCurrency =
      (vars.userReserveDebt * vars.debtAssetPrice) /
      vars.debtAssetUnit;

    // by default whole debt in the reserve could be liquidated
    uint256 maxLiquidatableDebt = vars.userReserveDebt;
    // but if debt is above or equal MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD and health factor CLOSE_FACTOR_HF_THRESHOLD
    // this amount may be adjusted
    if (
      vars.userReserveDebtInBaseCurrency >= MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD &&
      vars.healthFactor > CLOSE_FACTOR_HF_THRESHOLD
    ) {
      uint256 totalDefaultLiquidatableDebtInBaseCurrency = vars.totalDebtInBaseCurrency.percentMul(
        DEFAULT_LIQUIDATION_CLOSE_FACTOR
      );

      // if the debt is more then DEFAULT_LIQUIDATION_CLOSE_FACTOR % of the whole,
      // then we CAN liquidate only up to DEFAULT_LIQUIDATION_CLOSE_FACTOR %
      if (vars.userReserveDebtInBaseCurrency > totalDefaultLiquidatableDebtInBaseCurrency) {
        maxLiquidatableDebt =
          (totalDefaultLiquidatableDebtInBaseCurrency * vars.debtAssetUnit) /
          vars.debtAssetPrice;
      }
    }

    vars.actualDebtToLiquidate = params.debtToCover > maxLiquidatableDebt
      ? maxLiquidatableDebt
      : params.debtToCover;

    (
      vars.actualCollateralToLiquidate,
      vars.actualDebtToLiquidate,
      vars.liquidationProtocolFeeAmount,
      vars.collateralToLiquidateInBaseCurrency,
      vars.debtToRepayInBaseCurrency
    ) = _calculateAvailableCollateralToLiquidate(
      collateralReserve.configuration,
      vars.collateralAssetPrice,
      vars.collateralAssetUnit,
      vars.debtAssetPrice,
      vars.debtAssetUnit,
      vars.actualDebtToLiquidate,
      vars.userCollateralBalance,
      vars.liquidationBonus
    );

    // to prevent accumulation of dust on the protocol, it is enforced that you either
    // 1. liquidate all debt
    // 2. liquidate all collateral
    // 3. leave more than MIN_LEFTOVER_BASE of collateral & debt
    if (
      vars.actualDebtToLiquidate < vars.userReserveDebt &&
      vars.actualCollateralToLiquidate + vars.liquidationProtocolFeeAmount <
      vars.userCollateralBalance
    ) {
      bool isDebtMoreThanLeftoverThreshold = ((vars.userReserveDebt - vars.actualDebtToLiquidate) *
        vars.debtAssetPrice) /
        vars.debtAssetUnit >=
        MIN_LEFTOVER_BASE;

      bool isCollateralMoreThanLeftoverThreshold = ((vars.userCollateralBalance -
        vars.actualCollateralToLiquidate) * vars.collateralAssetPrice) /
        vars.collateralAssetUnit >=
        MIN_LEFTOVER_BASE;

      require(
        isDebtMoreThanLeftoverThreshold && isCollateralMoreThanLeftoverThreshold,
        Errors.MUST_NOT_LEAVE_DUST
      );
    }

    // If the collateral being liquidated is equal to the user balance,
    // we set the currency as not being used as collateral anymore
    // For the special case of msg.sender == params.user (self liquidation)
    // the collateral will only be disabled if it would not be automatically reenabled upon supplying
    if (
      vars.actualCollateralToLiquidate + vars.liquidationProtocolFeeAmount ==
      vars.userCollateralBalance &&
      !(msg.sender == params.user &&
        params.receiveAToken &&
        ValidationLogic.validateAutomaticUseAsCollateral(
          reservesData,
          reservesList,
          userConfig,
          collateralReserve.configuration,
          address(vars.collateralAToken)
        ))
    ) {
      userConfig.setUsingAsCollateral(collateralReserve.id, false);
      emit ReserveUsedAsCollateralDisabled(params.collateralAsset, params.user);
    }

    bool hasNoCollateralLeft = vars.totalCollateralInBaseCurrency ==
      vars.collateralToLiquidateInBaseCurrency;
    _burnDebtTokens(
      vars.debtReserveCache,
      debtReserve,
      userConfig,
      params.user,
      params.debtAsset,
      vars.userReserveDebt,
      vars.actualDebtToLiquidate,
      hasNoCollateralLeft
    );

    // IsolationModeTotalDebt only discounts `actualDebtToLiquidate`, not the fully burned amount in case of deficit creation.
    // This is by design as otherwise debt debt ceiling would render ineffective if a collateral asset faces bad debt events.
    // The governance can decide the raise the ceiling to discount manifested deficit.
    IsolationModeLogic.updateIsolatedDebtIfIsolated(
      reservesData,
      reservesList,
      userConfig,
      vars.debtReserveCache,
      vars.actualDebtToLiquidate
    );

    if (params.receiveAToken) {
      _liquidateATokens(reservesData, reservesList, usersConfig, collateralReserve, params, vars);
    } else {
      _burnCollateralATokens(collateralReserve, params, vars);
    }

    // Transfer fee to treasury if it is non-zero
    if (vars.liquidationProtocolFeeAmount != 0) {
      uint256 liquidityIndex = collateralReserve.getNormalizedIncome();
      uint256 scaledDownLiquidationProtocolFee = vars.liquidationProtocolFeeAmount.rayDiv(
        liquidityIndex
      );
      uint256 scaledDownUserBalance = vars.collateralAToken.scaledBalanceOf(params.user);
      // To avoid trying to send more aTokens than available on balance, due to 1 wei imprecision
      if (scaledDownLiquidationProtocolFee > scaledDownUserBalance) {
        vars.liquidationProtocolFeeAmount = scaledDownUserBalance.rayMul(liquidityIndex);
      }
      vars.collateralAToken.transferOnLiquidation(
        params.user,
        vars.collateralAToken.RESERVE_TREASURY_ADDRESS(),
        vars.liquidationProtocolFeeAmount
      );
    }

    // burn bad debt if necessary
    // Each additional debt asset already adds around ~75k gas to the liquidation.
    // To keep the liquidation gas under control, 0 usd collateral positions are not touched, as there is no immediate benefit in burning or transfering to treasury.
    if (hasNoCollateralLeft && userConfig.isBorrowingAny()) {
      _burnBadDebt(reservesData, reservesList, userConfig, params.reservesCount, params.user);
    }

    // Transfers the debt asset being repaid to the aToken, where the liquidity is kept
    IERC20(params.debtAsset).safeTransferFrom(
      msg.sender,
      vars.debtReserveCache.aTokenAddress,
      vars.actualDebtToLiquidate
    );

    IAToken(vars.debtReserveCache.aTokenAddress).handleRepayment(
      msg.sender,
      params.user,
      vars.actualDebtToLiquidate
    );

    emit LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      vars.actualDebtToLiquidate,
      vars.actualCollateralToLiquidate,
      msg.sender,
      params.receiveAToken
    );
  }

  /**
   * @notice Burns the collateral aTokens and transfers the underlying to the liquidator.
   * @dev   The function also updates the state and the interest rate of the collateral reserve.
   * @param collateralReserve The data of the collateral reserve
   * @param params The additional parameters needed to execute the liquidation function
   * @param vars The executeLiquidationCall() function local vars
   */
  function _burnCollateralATokens(
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ExecuteLiquidationCallParams memory params,
    LiquidationCallLocalVars memory vars
  ) internal {
    DataTypes.ReserveCache memory collateralReserveCache = collateralReserve.cache();
    collateralReserve.updateState(collateralReserveCache);
    collateralReserve.updateInterestRatesAndVirtualBalance(
      collateralReserveCache,
      params.collateralAsset,
      0,
      vars.actualCollateralToLiquidate
    );

    // Burn the equivalent amount of aToken, sending the underlying to the liquidator
    vars.collateralAToken.burn(
      params.user,
      msg.sender,
      vars.actualCollateralToLiquidate,
      collateralReserveCache.nextLiquidityIndex
    );
  }

  /**
   * @notice Liquidates the user aTokens by transferring them to the liquidator.
   * @dev   The function also checks the state of the liquidator and activates the aToken as collateral
   *        as in standard transfers if the isolation mode constraints are respected.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
   * @param collateralReserve The data of the collateral reserve
   * @param params The additional parameters needed to execute the liquidation function
   * @param vars The executeLiquidationCall() function local vars
   */
  function _liquidateATokens(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ExecuteLiquidationCallParams memory params,
    LiquidationCallLocalVars memory vars
  ) internal {
    uint256 liquidatorPreviousATokenBalance = IERC20(vars.collateralAToken).balanceOf(msg.sender);
    vars.collateralAToken.transferOnLiquidation(
      params.user,
      msg.sender,
      vars.actualCollateralToLiquidate
    );

    if (liquidatorPreviousATokenBalance == 0) {
      DataTypes.UserConfigurationMap storage liquidatorConfig = usersConfig[msg.sender];
      if (
        ValidationLogic.validateAutomaticUseAsCollateral(
          reservesData,
          reservesList,
          liquidatorConfig,
          collateralReserve.configuration,
          collateralReserve.aTokenAddress
        )
      ) {
        liquidatorConfig.setUsingAsCollateral(collateralReserve.id, true);
        emit ReserveUsedAsCollateralEnabled(params.collateralAsset, msg.sender);
      }
    }
  }

  /**
   * @notice Burns the debt tokens of the user up to the amount being repaid by the liquidator
   * or the entire debt if the user is in a bad debt scenario.
   * @dev The function alters the `debtReserveCache` state in `vars` to update the debt related data.
   * @param debtReserveCache The cached debt reserve parameters
   * @param debtReserve The storage pointer of the debt reserve parameters
   * @param userConfig The pointer of the user configuration
   * @param user The user address
   * @param debtAsset The debt asset address
   * @param actualDebtToLiquidate The actual debt to liquidate
   * @param hasNoCollateralLeft The flag representing, will user will have no collateral left after liquidation
   */
  function _burnDebtTokens(
    DataTypes.ReserveCache memory debtReserveCache,
    DataTypes.ReserveData storage debtReserve,
    DataTypes.UserConfigurationMap storage userConfig,
    address user,
    address debtAsset,
    uint256 userReserveDebt,
    uint256 actualDebtToLiquidate,
    bool hasNoCollateralLeft
  ) internal {
    // Prior v3.1, there were cases where, after liquidation, the `isBorrowing` flag was left on
    // even after the user debt was fully repaid, so to avoid this function reverting in the `_burnScaled`
    // (see ScaledBalanceTokenBase contract), we check for any debt remaining.
    if (userReserveDebt != 0) {
      debtReserveCache.nextScaledVariableDebt = IVariableDebtToken(
        debtReserveCache.variableDebtTokenAddress
      ).burn(
          user,
          hasNoCollateralLeft ? userReserveDebt : actualDebtToLiquidate,
          debtReserveCache.nextVariableBorrowIndex
        );
    }

    uint256 outstandingDebt = userReserveDebt - actualDebtToLiquidate;
    if (hasNoCollateralLeft && outstandingDebt != 0) {
      debtReserve.deficit += outstandingDebt.toUint128();
      emit DeficitCreated(user, debtAsset, outstandingDebt);

      outstandingDebt = 0;
    }

    if (outstandingDebt == 0) {
      userConfig.setBorrowing(debtReserve.id, false);
    }

    debtReserve.updateInterestRatesAndVirtualBalance(
      debtReserveCache,
      debtAsset,
      actualDebtToLiquidate,
      0
    );
  }

  struct AvailableCollateralToLiquidateLocalVars {
    uint256 maxCollateralToLiquidate;
    uint256 baseCollateral;
    uint256 bonusCollateral;
    uint256 collateralAmount;
    uint256 debtAmountNeeded;
    uint256 liquidationProtocolFeePercentage;
    uint256 liquidationProtocolFee;
    uint256 collateralToLiquidateInBaseCurrency;
    uint256 debtToRepayInBaseCurrency;
    uint256 debtAssetPrice;
    uint256 collateralAssetPrice;
  }

  /**
   * @notice Calculates how much of a specific collateral can be liquidated, given
   * a certain amount of debt asset.
   * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
   *   otherwise it might fail.
   * @param collateralReserveConfiguration The data of the collateral reserve
   * @param collateralAssetPrice The price of the underlying asset used as collateral
   * @param collateralAssetUnit The asset units of the collateral
   * @param debtAssetPrice The price of the underlying borrowed asset to be repaid with the liquidation
   * @param debtAssetUnit The asset units of the debt
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param userCollateralBalance The collateral balance for the specific `collateralAsset` of the user being liquidated
   * @param liquidationBonus The collateral bonus percentage to receive as result of the liquidation
   * @return The maximum amount that is possible to liquidate given all the liquidation constraints (user balance, close factor)
   * @return The amount to repay with the liquidation
   * @return The fee taken from the liquidation bonus amount to be paid to the protocol
   * @return The collateral amount to liquidate in the base currency used by the price feed
   * @return The amount to repay with the liquidation in the base currency used by the price feed
   */
  function _calculateAvailableCollateralToLiquidate(
    DataTypes.ReserveConfigurationMap memory collateralReserveConfiguration,
    uint256 collateralAssetPrice,
    uint256 collateralAssetUnit,
    uint256 debtAssetPrice,
    uint256 debtAssetUnit,
    uint256 debtToCover,
    uint256 userCollateralBalance,
    uint256 liquidationBonus
  ) internal pure returns (uint256, uint256, uint256, uint256, uint256) {
    AvailableCollateralToLiquidateLocalVars memory vars;
    vars.debtAssetPrice = debtAssetPrice;
    vars.collateralAssetPrice = collateralAssetPrice;
    vars.liquidationProtocolFeePercentage = collateralReserveConfiguration
      .getLiquidationProtocolFee();

    // This is the base collateral to liquidate based on the given debt to cover
    vars.baseCollateral =
      ((vars.debtAssetPrice * debtToCover * collateralAssetUnit)) /
      (vars.collateralAssetPrice * debtAssetUnit);

    vars.maxCollateralToLiquidate = vars.baseCollateral.percentMul(liquidationBonus);

    if (vars.maxCollateralToLiquidate > userCollateralBalance) {
      vars.collateralAmount = userCollateralBalance;
      vars.debtAmountNeeded = ((vars.collateralAssetPrice * vars.collateralAmount * debtAssetUnit) /
        (vars.debtAssetPrice * collateralAssetUnit)).percentDiv(liquidationBonus);
    } else {
      vars.collateralAmount = vars.maxCollateralToLiquidate;
      vars.debtAmountNeeded = debtToCover;
    }

    vars.collateralToLiquidateInBaseCurrency =
      (vars.collateralAmount * vars.collateralAssetPrice) /
      collateralAssetUnit;

    vars.debtToRepayInBaseCurrency = (vars.debtAmountNeeded * debtAssetPrice) / debtAssetUnit;

    if (vars.liquidationProtocolFeePercentage != 0) {
      vars.bonusCollateral =
        vars.collateralAmount -
        vars.collateralAmount.percentDiv(liquidationBonus);

      vars.liquidationProtocolFee = vars.bonusCollateral.percentMul(
        vars.liquidationProtocolFeePercentage
      );
      vars.collateralAmount -= vars.liquidationProtocolFee;
    }
    return (
      vars.collateralAmount,
      vars.debtAmountNeeded,
      vars.liquidationProtocolFee,
      vars.collateralToLiquidateInBaseCurrency,
      vars.debtToRepayInBaseCurrency
    );
  }

  /**
   * @notice Remove a user's bad debt by burning debt tokens.
   * @dev This function iterates through all active reserves where the user has a debt position,
   * updates their state, and performs the necessary burn.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration
   * @param reservesCount The total number of valid reserves
   * @param user The user from which the debt will be burned.
   */
  function _burnBadDebt(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    uint256 reservesCount,
    address user
  ) internal {
    for (uint256 i; i < reservesCount; i++) {
      if (!userConfig.isBorrowing(i)) {
        continue;
      }

      address reserveAddress = reservesList[i];
      if (reserveAddress == address(0)) {
        continue;
      }

      DataTypes.ReserveData storage currentReserve = reservesData[reserveAddress];
      DataTypes.ReserveCache memory reserveCache = currentReserve.cache();
      if (!reserveCache.reserveConfiguration.getActive()) continue;

      currentReserve.updateState(reserveCache);

      _burnDebtTokens(
        reserveCache,
        currentReserve,
        userConfig,
        user,
        reserveAddress,
        IERC20(reserveCache.variableDebtTokenAddress).balanceOf(user),
        0,
        true
      );
    }
  }
}
