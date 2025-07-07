// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {IPool} from '../../../interfaces/IPool.sol';
import {Errors} from '../helpers/Errors.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {TokenMath} from '../helpers/TokenMath.sol';

/**
 * @title SupplyLogic library
 * @author Aave
 * @notice Implements the base logic for supply/withdraw
 */
library SupplyLogic {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using GPv2SafeERC20 for IERC20;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using TokenMath for uint256;
  using PercentageMath for uint256;

  /**
   * @notice Implements the supply feature. Through `supply()`, users supply assets to the Aave protocol.
   * @dev Emits the `Supply()` event.
   * @dev In the first supply action, `ReserveUsedAsCollateralEnabled()` is emitted, if the asset can be enabled as
   * collateral.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the supply function
   */
  function executeSupply(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteSupplyParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);
    uint256 scaledAmount = params.amount.getATokenMintScaledAmount(reserveCache.nextLiquidityIndex);

    ValidationLogic.validateSupply(reserveCache, reserve, scaledAmount, params.onBehalfOf);

    reserve.updateInterestRatesAndVirtualBalance(
      reserveCache,
      params.asset,
      params.amount,
      0,
      params.interestRateStrategyAddress
    );

    IERC20(params.asset).safeTransferFrom(params.user, reserveCache.aTokenAddress, params.amount);

    // As aToken.mint rounds down the minted shares, we ensure an equivalent of <= params.amount shares is minted.
    bool isFirstSupply = IAToken(reserveCache.aTokenAddress).mint(
      params.user,
      params.onBehalfOf,
      scaledAmount,
      reserveCache.nextLiquidityIndex
    );

    if (isFirstSupply) {
      if (
        ValidationLogic.validateAutomaticUseAsCollateral(
          params.user,
          reservesData,
          reservesList,
          userConfig,
          reserveCache.reserveConfiguration,
          reserveCache.aTokenAddress
        )
      ) {
        userConfig.setUsingAsCollateral(reserve.id, params.asset, params.onBehalfOf, true);
      }
    }

    emit IPool.Supply(
      params.asset,
      params.user,
      params.onBehalfOf,
      params.amount,
      params.referralCode
    );
  }

  /**
   * @notice Implements the withdraw feature. Through `withdraw()`, users redeem their aTokens for the underlying asset
   * previously supplied in the Aave protocol.
   * @dev Emits the `Withdraw()` event.
   * @dev If the user withdraws everything, `ReserveUsedAsCollateralDisabled()` is emitted.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the withdraw function
   * @return The actual amount withdrawn
   */
  function executeWithdraw(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteWithdrawParams memory params
  ) external returns (uint256) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    require(params.to != reserveCache.aTokenAddress, Errors.WithdrawToAToken());

    reserve.updateState(reserveCache);

    uint256 scaledUserBalance = IAToken(reserveCache.aTokenAddress).scaledBalanceOf(params.user);

    uint256 amountToWithdraw;
    uint256 scaledAmountToWithdraw;
    if (params.amount == type(uint256).max) {
      scaledAmountToWithdraw = scaledUserBalance;

      amountToWithdraw = scaledUserBalance.getATokenBalance(reserveCache.nextLiquidityIndex);
    } else {
      scaledAmountToWithdraw = params.amount.getATokenBurnScaledAmount(
        reserveCache.nextLiquidityIndex
      );

      amountToWithdraw = params.amount;
    }

    ValidationLogic.validateWithdraw(reserveCache, scaledAmountToWithdraw, scaledUserBalance);

    reserve.updateInterestRatesAndVirtualBalance(
      reserveCache,
      params.asset,
      0,
      amountToWithdraw,
      params.interestRateStrategyAddress
    );

    // As aToken.burn rounds up the burned shares, we ensure at least an equivalent of >= amountToWithdraw is burned.
    bool zeroBalanceAfterBurn = IAToken(reserveCache.aTokenAddress).burn({
      from: params.user,
      receiverOfUnderlying: params.to,
      amount: amountToWithdraw,
      scaledAmount: scaledAmountToWithdraw,
      index: reserveCache.nextLiquidityIndex
    });

    if (userConfig.isUsingAsCollateral(reserve.id)) {
      if (zeroBalanceAfterBurn) {
        userConfig.setUsingAsCollateral(reserve.id, params.asset, params.user, false);
      }
      if (userConfig.isBorrowingAny()) {
        ValidationLogic.validateHFAndLtvzero(
          reservesData,
          reservesList,
          eModeCategories,
          userConfig,
          params.asset,
          params.user,
          params.oracle,
          params.userEModeCategory
        );
      }
    }

    emit IPool.Withdraw(params.asset, params.user, params.to, amountToWithdraw);

    return amountToWithdraw;
  }

  /**
   * @notice Validates a transfer of aTokens. The sender is subjected to health factor validation to avoid
   * collateralization constraints violation.
   * @dev Emits the `ReserveUsedAsCollateralEnabled()` event for the `to` account, if the asset is being activated as
   * collateral.
   * @dev In case the `from` user transfers everything, `ReserveUsedAsCollateralDisabled()` is emitted for `from`.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
   * @param params The additional parameters needed to execute the finalizeTransfer function
   */
  function executeFinalizeTransfer(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
    DataTypes.FinalizeTransferParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];

    ValidationLogic.validateTransfer(reserve);

    uint256 reserveId = reserve.id;

    if (params.from != params.to && params.scaledAmount != 0) {
      DataTypes.UserConfigurationMap storage fromConfig = usersConfig[params.from];

      if (fromConfig.isUsingAsCollateral(reserveId)) {
        if (params.scaledBalanceFromBefore == params.scaledAmount) {
          fromConfig.setUsingAsCollateral(reserveId, params.asset, params.from, false);
        }
        if (fromConfig.isBorrowingAny()) {
          ValidationLogic.validateHFAndLtvzero(
            reservesData,
            reservesList,
            eModeCategories,
            usersConfig[params.from],
            params.asset,
            params.from,
            params.oracle,
            params.fromEModeCategory
          );
        }
      }

      if (params.scaledBalanceToBefore == 0) {
        DataTypes.UserConfigurationMap storage toConfig = usersConfig[params.to];
        if (
          ValidationLogic.validateAutomaticUseAsCollateral(
            params.from,
            reservesData,
            reservesList,
            toConfig,
            reserve.configuration,
            reserve.aTokenAddress
          )
        ) {
          toConfig.setUsingAsCollateral(reserveId, params.asset, params.to, true);
        }
      }
    }
  }

  /**
   * @notice Executes the 'set as collateral' feature. A user can choose to activate or deactivate an asset as
   * collateral at any point in time. Deactivating an asset as collateral is subjected to the usual health factor
   * checks to ensure collateralization.
   * @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
   * @dev In case the asset is being deactivated as collateral, `ReserveUsedAsCollateralDisabled()` is emitted.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The users configuration mapping that track the supplied/borrowed assets
   * @param user The user calling the method
   * @param asset The address of the asset being configured as collateral
   * @param useAsCollateral True if the user wants to set the asset as collateral, false otherwise
   * @param priceOracle The address of the price oracle
   * @param userEModeCategory The eMode category chosen by the user
   */
  function executeUseReserveAsCollateral(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap storage userConfig,
    address user,
    address asset,
    bool useAsCollateral,
    address priceOracle,
    uint8 userEModeCategory
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[asset];
    DataTypes.ReserveConfigurationMap memory reserveConfigCached = reserve.configuration;

    ValidationLogic.validateSetUseReserveAsCollateral(reserveConfigCached);

    if (useAsCollateral == userConfig.isUsingAsCollateral(reserve.id)) return;

    if (useAsCollateral) {
      // When enabeling a reserve as collateral, we want to ensure the user has at least some collateral
      require(
        IAToken(reserve.aTokenAddress).scaledBalanceOf(user) != 0,
        Errors.UnderlyingBalanceZero()
      );

      require(
        ValidationLogic.validateUseAsCollateral(
          reservesData,
          reservesList,
          userConfig,
          reserveConfigCached
        ),
        Errors.UserInIsolationModeOrLtvZero()
      );

      userConfig.setUsingAsCollateral(reserve.id, asset, user, true);
    } else {
      userConfig.setUsingAsCollateral(reserve.id, asset, user, false);
      ValidationLogic.validateHFAndLtvzero(
        reservesData,
        reservesList,
        eModeCategories,
        userConfig,
        asset,
        user,
        priceOracle,
        userEModeCategory
      );
    }
  }
}
