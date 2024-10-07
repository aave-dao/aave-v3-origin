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
  event BadDebtBurned(address indexed user, address indexed debtAsset, uint256 amount);
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
   * @dev Maximum percentage of borrower's debt to be repaid in a liquidation
   * @dev Percentage applied when the users health factor is below `CLOSE_FACTOR_HF_THRESHOLD`
   * Expressed in bps, a value of 1e4 results in 100.00%
   */
  uint256 public constant MAX_LIQUIDATION_CLOSE_FACTOR = 1e4;

  /**
   * @dev This constant represents below which health factor value it is possible to liquidate
   * an amount of debt corresponding to `MAX_LIQUIDATION_CLOSE_FACTOR`.
   * A value of 0.95e18 results in 0.95
   */
  uint256 public constant CLOSE_FACTOR_HF_THRESHOLD = 0.95e18;

  struct LiquidationCallLocalVars {
    uint256 userCollateralBalance;
    uint256 userTotalDebt;
    uint256 actualDebtToLiquidate;
    uint256 actualCollateralToLiquidate;
    uint256 liquidationBonus;
    uint256 healthFactor;
    uint256 liquidationProtocolFeeAmount;
    uint256 totalCollateralInBaseCurrency;
    uint256 totalDebtInBaseCurrency;
    uint256 collateralToLiquidateInBaseCurrency;
    uint256 debtToRepayInBaseCurrency;
    address collateralPriceSource;
    address debtPriceSource;
    IAToken collateralAToken;
    DataTypes.ReserveCache debtReserveCache;
  }

  /**
   * @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
   * covers `debtToCover` amount of debt of the user getting liquidated, and receives
   * a proportional amount of the `collateralAsset` plus a bonus to cover market risk
   * @dev Emits the `LiquidationCall()` event, and the `BadDebtBurned()` event if the liquidation results in bad debt
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

    (vars.userTotalDebt, vars.actualDebtToLiquidate) = _calculateDebt(
      vars.debtReserveCache,
      params,
      vars.healthFactor
    );

    ValidationLogic.validateLiquidationCall(
      userConfig,
      collateralReserve,
      debtReserve,
      DataTypes.ValidateLiquidationCallParams({
        debtReserveCache: vars.debtReserveCache,
        totalDebt: vars.userTotalDebt,
        healthFactor: vars.healthFactor,
        priceOracleSentinel: params.priceOracleSentinel
      })
    );

    vars.collateralAToken = IAToken(collateralReserve.aTokenAddress);
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

    vars.userCollateralBalance = vars.collateralAToken.balanceOf(params.user);

    (
      vars.actualCollateralToLiquidate,
      vars.actualDebtToLiquidate,
      vars.liquidationProtocolFeeAmount,
      vars.collateralToLiquidateInBaseCurrency,
      vars.debtToRepayInBaseCurrency
    ) = _calculateAvailableCollateralToLiquidate(
      collateralReserve,
      vars.debtReserveCache,
      params.collateralAsset,
      params.debtAsset,
      vars.actualDebtToLiquidate,
      vars.userCollateralBalance,
      vars.liquidationBonus,
      IPriceOracleGetter(params.priceOracle)
    );

    bool isBadDebt = _isBadDebtScenario(
      vars.totalCollateralInBaseCurrency,
      vars.collateralToLiquidateInBaseCurrency,
      vars.totalDebtInBaseCurrency,
      vars.debtToRepayInBaseCurrency
    );

    if (vars.userTotalDebt == vars.actualDebtToLiquidate || isBadDebt) {
      userConfig.setBorrowing(debtReserve.id, false);
    }

    // If the collateral being liquidated is equal to the user balance,
    // we set the currency as not being used as collateral anymore
    if (
      vars.actualCollateralToLiquidate + vars.liquidationProtocolFeeAmount ==
      vars.userCollateralBalance
    ) {
      userConfig.setUsingAsCollateral(collateralReserve.id, false);
      emit ReserveUsedAsCollateralDisabled(params.collateralAsset, params.user);
    }

    _burnDebtTokens(params, vars, debtReserve, isBadDebt);

    debtReserve.updateInterestRatesAndVirtualBalance(
      vars.debtReserveCache,
      params.debtAsset,
      vars.actualDebtToLiquidate,
      0
    );

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
    if (isBadDebt && userConfig.isBorrowingAny()) {
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
   * @notice Validates a user's bad debt situation and subsequently burning the debt.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The state of the user for the specific reserve
   * @param user The user to burn the bad debt
   * @param userEModeCategory The users active efficiency mode category
   * @param reservesCount The number of available reserves
   * @param oracle The price oracle
   */
  function executeBadDebtCleanup(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap storage userConfig,
    address user,
    uint8 userEModeCategory,
    uint256 reservesCount,
    address oracle
  ) external {
    ValidationLogic.validateUserBadDebt(
      reservesData,
      reservesList,
      eModeCategories,
      DataTypes.CalculateUserAccountDataParams({
        userConfig: userConfig,
        reservesCount: reservesCount,
        user: user,
        oracle: oracle,
        userEModeCategory: userEModeCategory
      })
    );
    _burnBadDebt(reservesData, reservesList, userConfig, reservesCount, user);
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
   * @param params The additional parameters needed to execute the liquidation function
   * @param vars the executeLiquidationCall() function local vars
   */
  function _burnDebtTokens(
    DataTypes.ExecuteLiquidationCallParams memory params,
    LiquidationCallLocalVars memory vars,
    DataTypes.ReserveData storage debtReserve,
    bool isBadDebt
  ) internal {
    vars.debtReserveCache.nextScaledVariableDebt = IVariableDebtToken(
      vars.debtReserveCache.variableDebtTokenAddress
    ).burn(
        params.user,
        isBadDebt ? vars.userTotalDebt : vars.actualDebtToLiquidate,
        vars.debtReserveCache.nextVariableBorrowIndex
      );

    if (isBadDebt) {
      debtReserve.deficit += (vars.userTotalDebt - vars.actualDebtToLiquidate).toUint128();
      emit BadDebtBurned(
        params.user,
        params.debtAsset,
        vars.userTotalDebt - vars.actualDebtToLiquidate
      );
    }
  }

  /**
   * @notice Calculates the total debt of the user and the actual amount to liquidate depending on the health factor
   * and corresponding close factor.
   * @dev If the Health Factor is below CLOSE_FACTOR_HF_THRESHOLD, the close factor is increased to MAX_LIQUIDATION_CLOSE_FACTOR
   * @param debtReserveCache The reserve cache data object of the debt reserve
   * @param params The additional parameters needed to execute the liquidation function
   * @param healthFactor The health factor of the position
   * @return The total debt of the user
   * @return The actual debt to liquidate as a function of the closeFactor
   */
  function _calculateDebt(
    DataTypes.ReserveCache memory debtReserveCache,
    DataTypes.ExecuteLiquidationCallParams memory params,
    uint256 healthFactor
  ) internal view returns (uint256, uint256) {
    uint256 userVariableDebt = IERC20(debtReserveCache.variableDebtTokenAddress).balanceOf(
      params.user
    );

    uint256 closeFactor = healthFactor > CLOSE_FACTOR_HF_THRESHOLD
      ? DEFAULT_LIQUIDATION_CLOSE_FACTOR
      : MAX_LIQUIDATION_CLOSE_FACTOR;

    uint256 maxLiquidatableDebt = userVariableDebt.percentMul(closeFactor);

    uint256 actualDebtToLiquidate = params.debtToCover > maxLiquidatableDebt
      ? maxLiquidatableDebt
      : params.debtToCover;

    return (userVariableDebt, actualDebtToLiquidate);
  }

  struct AvailableCollateralToLiquidateLocalVars {
    uint256 collateralPrice;
    uint256 debtAssetPrice;
    uint256 maxCollateralToLiquidate;
    uint256 baseCollateral;
    uint256 bonusCollateral;
    uint256 debtAssetDecimals;
    uint256 collateralDecimals;
    uint256 collateralAssetUnit;
    uint256 debtAssetUnit;
    uint256 collateralAmount;
    uint256 debtAmountNeeded;
    uint256 liquidationProtocolFeePercentage;
    uint256 liquidationProtocolFee;
    uint256 collateralToLiquidateInBaseCurrency;
    uint256 debtToRepayInBaseCurrency;
  }

  /**
   * @notice Calculates how much of a specific collateral can be liquidated, given
   * a certain amount of debt asset.
   * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
   *   otherwise it might fail.
   * @param collateralReserve The data of the collateral reserve
   * @param debtReserveCache The cached data of the debt reserve
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
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
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ReserveCache memory debtReserveCache,
    address collateralAsset,
    address debtAsset,
    uint256 debtToCover,
    uint256 userCollateralBalance,
    uint256 liquidationBonus,
    IPriceOracleGetter oracle
  ) internal view returns (uint256, uint256, uint256, uint256, uint256) {
    AvailableCollateralToLiquidateLocalVars memory vars;

    vars.collateralPrice = oracle.getAssetPrice(collateralAsset);
    vars.debtAssetPrice = oracle.getAssetPrice(debtAsset);

    vars.collateralDecimals = collateralReserve.configuration.getDecimals();
    vars.debtAssetDecimals = debtReserveCache.reserveConfiguration.getDecimals();

    unchecked {
      vars.collateralAssetUnit = 10 ** vars.collateralDecimals;
      vars.debtAssetUnit = 10 ** vars.debtAssetDecimals;
    }

    vars.liquidationProtocolFeePercentage = collateralReserve
      .configuration
      .getLiquidationProtocolFee();

    // This is the base collateral to liquidate based on the given debt to cover
    vars.baseCollateral =
      ((vars.debtAssetPrice * debtToCover * vars.collateralAssetUnit)) /
      (vars.collateralPrice * vars.debtAssetUnit);

    vars.maxCollateralToLiquidate = vars.baseCollateral.percentMul(liquidationBonus);

    if (vars.maxCollateralToLiquidate > userCollateralBalance) {
      vars.collateralAmount = userCollateralBalance;
      vars.debtAmountNeeded = ((vars.collateralPrice * vars.collateralAmount * vars.debtAssetUnit) /
        (vars.debtAssetPrice * vars.collateralAssetUnit)).percentDiv(liquidationBonus);
    } else {
      vars.collateralAmount = vars.maxCollateralToLiquidate;
      vars.debtAmountNeeded = debtToCover;
    }

    vars.collateralToLiquidateInBaseCurrency =
      (vars.collateralAmount * vars.collateralPrice) /
      vars.collateralAssetUnit;

    vars.debtToRepayInBaseCurrency =
      (vars.debtAmountNeeded * vars.debtAssetPrice) /
      vars.debtAssetUnit;

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
   * @notice Checks whether a liquidation will result in a bad debt situation for the user.
   * @dev This function is invoked during the liquidation, after calculating the amounts related
   * to collateral and debt that are to be liquidated and repaid, respectively.
   * @param totalCollateralInBaseCurrency The total collateral of the user in the base currency used by the price feed
   * @param collateralToLiquidateInBaseCurrency The collateral to liquidate in the base currency used by the price feed
   * @param totalDebtInBaseCurrency The total debt of the user in the base currency used by the price feed
   * @param debtToRepayInBaseCurrency  The amount to repay with the liquidation in the base currency used by the price feed
   * @return True if the liquidation will result in bad debt, false otherwise
   */
  function _isBadDebtScenario(
    uint256 totalCollateralInBaseCurrency,
    uint256 collateralToLiquidateInBaseCurrency,
    uint256 totalDebtInBaseCurrency,
    uint256 debtToRepayInBaseCurrency
  ) internal pure returns (bool) {
    bool collateralIsZeroAfterLiquidation = totalCollateralInBaseCurrency ==
      collateralToLiquidateInBaseCurrency;
    bool debtIsZeroAfterLiquidation = totalDebtInBaseCurrency == debtToRepayInBaseCurrency;
    return collateralIsZeroAfterLiquidation && !debtIsZeroAfterLiquidation;
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

      currentReserve.updateState(reserveCache);
      currentReserve.updateInterestRatesAndVirtualBalance(reserveCache, reserveAddress, 0, 0);

      userConfig.setBorrowing(i, false);

      IVariableDebtToken vToken = IVariableDebtToken(currentReserve.variableDebtTokenAddress);
      // Fetch the scaled balance first as it is more gas-efficient
      uint256 userDebt = vToken.scaledBalanceOf(user);
      // Prior v3.1, there were cases where, after liquidation, the `isBorrowing` flag was left on
      // even after the user debt was fully repaid, so to avoid this function reverting in the `_burnScaled`
      // (see ScaledBalanceTokenBase contract), we check for any debt remaining.
      if (userDebt != 0) {
        // Scale up the debt balance
        userDebt = userDebt.rayMul(reserveCache.nextVariableBorrowIndex);
        vToken.burn(user, userDebt, reserveCache.nextVariableBorrowIndex);
        currentReserve.deficit += userDebt.toUint128();
        emit BadDebtBurned(user, reserveAddress, userDebt);
      }
    }
  }
}
