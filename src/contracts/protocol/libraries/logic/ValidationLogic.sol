// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {Address} from '../../../dependencies/openzeppelin/contracts/Address.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {IPriceOracleSentinel} from '../../../interfaces/IPriceOracleSentinel.sol';
import {IPoolAddressesProvider} from '../../../interfaces/IPoolAddressesProvider.sol';
import {IAccessControl} from '../../../dependencies/openzeppelin/contracts/IAccessControl.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {EModeConfiguration} from '../configuration/EModeConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {TokenMath} from '../helpers/TokenMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {GenericLogic} from './GenericLogic.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {IncentivizedERC20} from '../../tokenization/base/IncentivizedERC20.sol';
import {MathUtils} from '../math/MathUtils.sol';

/**
 * @title ValidationLogic library
 * @author Aave
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using TokenMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using GPv2SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using Address for address;

  // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
  // A value of 0.9e4 results in 90%
  uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 0.9e4;

  // Minimum health factor allowed under any circumstance
  // A value of 0.95e18 results in 0.95
  uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 0.95e18;

  /**
   * @dev Minimum health factor to consider a user position healthy
   * A value of 1e18 results in 1
   */
  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

  /**
   * @dev Role identifier for the role allowed to supply isolated reserves as collateral
   */
  bytes32 public constant ISOLATED_COLLATERAL_SUPPLIER_ROLE =
    keccak256('ISOLATED_COLLATERAL_SUPPLIER');

  /**
   * @notice Validates a supply action.
   * @param reserveCache The cached data of the reserve
   * @param scaledAmount The scaledAmount to be supplied
   */
  function validateSupply(
    DataTypes.ReserveCache memory reserveCache,
    DataTypes.ReserveData storage reserve,
    uint256 scaledAmount,
    address onBehalfOf
  ) internal view {
    require(scaledAmount != 0, Errors.InvalidAmount());

    (bool isActive, bool isFrozen, , bool isPaused) = reserveCache.reserveConfiguration.getFlags();
    require(isActive, Errors.ReserveInactive());
    require(!isPaused, Errors.ReservePaused());
    require(!isFrozen, Errors.ReserveFrozen());
    require(onBehalfOf != reserveCache.aTokenAddress, Errors.SupplyToAToken());

    uint256 supplyCap = reserveCache.reserveConfiguration.getSupplyCap();
    require(
      supplyCap == 0 ||
        (
          (IAToken(reserveCache.aTokenAddress).scaledTotalSupply() +
            scaledAmount +
            uint256(reserve.accruedToTreasury)).getATokenBalance(reserveCache.nextLiquidityIndex)
        ) <=
        supplyCap * (10 ** reserveCache.reserveConfiguration.getDecimals()),
      Errors.SupplyCapExceeded()
    );
  }

  /**
   * @notice Validates a withdraw action.
   * @param reserveCache The cached data of the reserve
   * @param scaledAmount The scaled amount to be withdrawn
   * @param scaledUserBalance The scaled balance of the user
   */
  function validateWithdraw(
    DataTypes.ReserveCache memory reserveCache,
    uint256 scaledAmount,
    uint256 scaledUserBalance
  ) internal pure {
    require(scaledAmount != 0, Errors.InvalidAmount());
    require(scaledAmount <= scaledUserBalance, Errors.NotEnoughAvailableUserBalance());

    (bool isActive, , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();
    require(isActive, Errors.ReserveInactive());
    require(!isPaused, Errors.ReservePaused());
  }

  struct ValidateBorrowLocalVars {
    uint256 amount;
    uint256 userDebtInBaseCurrency;
    uint256 availableLiquidity;
    uint256 totalDebt;
    uint256 reserveDecimals;
    uint256 borrowCap;
    uint256 amountInBaseCurrency;
    uint256 assetUnit;
    address siloedBorrowingAddress;
    bool isActive;
    bool isFrozen;
    bool isPaused;
    bool borrowingEnabled;
    bool siloedBorrowingEnabled;
  }

  /**
   * @notice Validates a borrow action.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param params Additional params needed for the validation
   */
  function validateBorrow(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.ValidateBorrowParams memory params
  ) internal view {
    require(params.amountScaled != 0, Errors.InvalidAmount());

    ValidateBorrowLocalVars memory vars;
    vars.amount = params.amountScaled.getVTokenBalance(params.reserveCache.nextVariableBorrowIndex);

    (vars.isActive, vars.isFrozen, vars.borrowingEnabled, vars.isPaused) = params
      .reserveCache
      .reserveConfiguration
      .getFlags();

    require(vars.isActive, Errors.ReserveInactive());
    require(!vars.isPaused, Errors.ReservePaused());
    require(!vars.isFrozen, Errors.ReserveFrozen());
    require(vars.borrowingEnabled, Errors.BorrowingNotEnabled());
    require(
      IERC20(params.reserveCache.aTokenAddress).totalSupply() >= vars.amount,
      Errors.InvalidAmount()
    );

    require(
      params.priceOracleSentinel == address(0) ||
        IPriceOracleSentinel(params.priceOracleSentinel).isBorrowAllowed(),
      Errors.PriceOracleSentinelCheckFailed()
    );

    //validate interest rate mode
    require(
      params.interestRateMode == DataTypes.InterestRateMode.VARIABLE,
      Errors.InvalidInterestRateModeSelected()
    );

    vars.reserveDecimals = params.reserveCache.reserveConfiguration.getDecimals();
    vars.borrowCap = params.reserveCache.reserveConfiguration.getBorrowCap();
    unchecked {
      vars.assetUnit = 10 ** vars.reserveDecimals;
    }

    if (vars.borrowCap != 0) {
      vars.totalDebt = (params.reserveCache.currScaledVariableDebt + params.amountScaled)
        .getVTokenBalance(params.reserveCache.nextVariableBorrowIndex);

      unchecked {
        require(vars.totalDebt <= vars.borrowCap * vars.assetUnit, Errors.BorrowCapExceeded());
      }
    }

    if (params.userEModeCategory != 0) {
      require(
        EModeConfiguration.isReserveEnabledOnBitmap(
          eModeCategories[params.userEModeCategory].borrowableBitmap,
          reservesData[params.asset].id
        ),
        Errors.NotBorrowableInEMode()
      );
    }

    if (params.userConfig.isBorrowingAny()) {
      (vars.siloedBorrowingEnabled, vars.siloedBorrowingAddress) = params
        .userConfig
        .getSiloedBorrowingState(reservesData, reservesList);

      if (vars.siloedBorrowingEnabled) {
        require(vars.siloedBorrowingAddress == params.asset, Errors.SiloedBorrowingViolation());
      } else {
        require(
          !params.reserveCache.reserveConfiguration.getSiloedBorrowing(),
          Errors.SiloedBorrowingViolation()
        );
      }
    }
  }

  /**
   * @notice Validates a repay action.
   * @param user The user initiating the repayment
   * @param reserveCache The cached data of the reserve
   * @param amountSent The amount sent for the repayment. Can be an actual value or type(uint256).max
   * @param onBehalfOf The address of the user sender is repaying for
   * @param debtScaled The borrow scaled balance of the user
   */
  function validateRepay(
    address user,
    DataTypes.ReserveCache memory reserveCache,
    uint256 amountSent,
    DataTypes.InterestRateMode interestRateMode,
    address onBehalfOf,
    uint256 debtScaled
  ) internal pure {
    require(amountSent != 0, Errors.InvalidAmount());
    require(
      interestRateMode == DataTypes.InterestRateMode.VARIABLE,
      Errors.InvalidInterestRateModeSelected()
    );
    require(
      amountSent != type(uint256).max || user == onBehalfOf,
      Errors.NoExplicitAmountToRepayOnBehalf()
    );

    (bool isActive, , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();
    require(isActive, Errors.ReserveInactive());
    require(!isPaused, Errors.ReservePaused());

    require(debtScaled != 0, Errors.NoDebtOfSelectedType());
  }

  /**
   * @notice Validates the action of setting an asset as collateral.
   * @param reserveConfig The config of the reserve
   */
  function validateSetUseReserveAsCollateral(
    DataTypes.ReserveConfigurationMap memory reserveConfig
  ) internal pure {
    (bool isActive, , , bool isPaused) = reserveConfig.getFlags();
    require(isActive, Errors.ReserveInactive());
    require(!isPaused, Errors.ReservePaused());
  }

  /**
   * @notice Validates a flashloan action.
   * @param reservesData The state of all the reserves
   * @param assets The assets being flash-borrowed
   * @param amounts The amounts for each asset being borrowed
   */
  function validateFlashloan(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address[] memory assets,
    uint256[] memory amounts
  ) internal view {
    require(assets.length == amounts.length, Errors.InconsistentFlashloanParams());
    for (uint256 i = 0; i < assets.length; i++) {
      for (uint256 j = i + 1; j < assets.length; j++) {
        require(assets[i] != assets[j], Errors.InconsistentFlashloanParams());
      }
      validateFlashloanSimple(reservesData[assets[i]], amounts[i]);
    }
  }

  /**
   * @notice Validates a flashloan action.
   * @param reserve The state of the reserve
   */
  function validateFlashloanSimple(
    DataTypes.ReserveData storage reserve,
    uint256 amount
  ) internal view {
    DataTypes.ReserveConfigurationMap memory configuration = reserve.configuration;
    require(!configuration.getPaused(), Errors.ReservePaused());
    require(configuration.getActive(), Errors.ReserveInactive());
    require(configuration.getFlashLoanEnabled(), Errors.FlashloanDisabled());
    require(IERC20(reserve.aTokenAddress).totalSupply() >= amount, Errors.InvalidAmount());
  }

  struct ValidateLiquidationCallLocalVars {
    bool collateralReserveActive;
    bool collateralReservePaused;
    bool principalReserveActive;
    bool principalReservePaused;
    bool isCollateralEnabled;
  }

  /**
   * @notice Validates the liquidation action.
   * @param borrowerConfig The user configuration mapping
   * @param collateralReserve The reserve data of the collateral
   * @param debtReserve The reserve data of the debt
   * @param params Additional parameters needed for the validation
   */
  function validateLiquidationCall(
    DataTypes.UserConfigurationMap storage borrowerConfig,
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ReserveData storage debtReserve,
    DataTypes.ValidateLiquidationCallParams memory params
  ) internal view {
    ValidateLiquidationCallLocalVars memory vars;

    require(params.borrower != params.liquidator, Errors.SelfLiquidation());

    (vars.collateralReserveActive, , , vars.collateralReservePaused) = collateralReserve
      .configuration
      .getFlags();

    (vars.principalReserveActive, , , vars.principalReservePaused) = params
      .debtReserveCache
      .reserveConfiguration
      .getFlags();

    require(vars.collateralReserveActive && vars.principalReserveActive, Errors.ReserveInactive());
    require(!vars.collateralReservePaused && !vars.principalReservePaused, Errors.ReservePaused());

    require(
      params.priceOracleSentinel == address(0) ||
        params.healthFactor < MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
        IPriceOracleSentinel(params.priceOracleSentinel).isLiquidationAllowed(),
      Errors.PriceOracleSentinelCheckFailed()
    );

    require(
      collateralReserve.liquidationGracePeriodUntil < uint40(block.timestamp) &&
        debtReserve.liquidationGracePeriodUntil < uint40(block.timestamp),
      Errors.LiquidationGraceSentinelCheckFailed()
    );

    require(
      params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HealthFactorNotBelowThreshold()
    );

    vars.isCollateralEnabled =
      collateralReserve.configuration.getLiquidationThreshold() != 0 &&
      borrowerConfig.isUsingAsCollateral(collateralReserve.id);

    //if collateral isn't enabled as collateral by user, it cannot be liquidated
    require(vars.isCollateralEnabled, Errors.CollateralCannotBeLiquidated());
    require(params.totalDebt != 0, Errors.SpecifiedCurrencyNotBorrowedByUser());
  }

  /**
   * @notice Validates the health factor of a user.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The state of the user for the specific reserve
   * @param user The user to validate health factor of
   * @param userEModeCategory The users active efficiency mode category
   * @param oracle The price oracle
   */
  function validateHealthFactor(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    address user,
    uint8 userEModeCategory,
    address oracle
  ) internal view returns (uint256, bool) {
    (, , , , uint256 healthFactor, bool hasZeroLtvCollateral) = GenericLogic
      .calculateUserAccountData(
        reservesData,
        reservesList,
        eModeCategories,
        DataTypes.CalculateUserAccountDataParams({
          userConfig: userConfig,
          user: user,
          oracle: oracle,
          userEModeCategory: userEModeCategory
        })
      );

    require(
      healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HealthFactorLowerThanLiquidationThreshold()
    );

    return (healthFactor, hasZeroLtvCollateral);
  }

  /**
   * @notice Validates the health factor of a user and the ltv of the asset being borrowed.
   *         The ltv validation is a measure to prevent accidental borrowing close to liquidations.
   *         Sophisticated users can work around this validation in various ways.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The state of the user for the specific reserve
   * @param user The user from which the aTokens are being transferred
   * @param userEModeCategory The users active efficiency mode category
   * @param oracle The price oracle
   */
  function validateHFAndLtv(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    address user,
    uint8 userEModeCategory,
    address oracle
  ) internal view {
    (
      uint256 userCollateralInBaseCurrency,
      uint256 userDebtInBaseCurrency,
      uint256 currentLtv,
      ,
      uint256 healthFactor,

    ) = GenericLogic.calculateUserAccountData(
        reservesData,
        reservesList,
        eModeCategories,
        DataTypes.CalculateUserAccountDataParams({
          userConfig: userConfig,
          user: user,
          oracle: oracle,
          userEModeCategory: userEModeCategory
        })
      );

    require(currentLtv != 0, Errors.LtvValidationFailed());

    require(
      healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HealthFactorLowerThanLiquidationThreshold()
    );

    require(
      userCollateralInBaseCurrency >= userDebtInBaseCurrency.percentDivCeil(currentLtv),
      Errors.CollateralCannotCoverNewBorrow()
    );
  }

  /**
   * @notice Validates the health factor of a user and the ltvzero configuration for the asset being withdrawn/transferred or disabled as collateral.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The state of the user for the specific reserve
   * @param asset The asset for which the ltv will be validated
   * @param from The user from which the aTokens are being transferred
   * @param oracle The price oracle
   * @param userEModeCategory The users active efficiency mode category
   */
  function validateHFAndLtvzero(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    address asset,
    address from,
    address oracle,
    uint8 userEModeCategory
  ) internal view {
    (, bool hasZeroLtvCollateral) = validateHealthFactor(
      reservesData,
      reservesList,
      eModeCategories,
      userConfig,
      from,
      userEModeCategory,
      oracle
    );

    require(
      !hasZeroLtvCollateral || reservesData[asset].configuration.getLtv() == 0,
      Errors.LtvValidationFailed()
    );
  }

  /**
   * @notice Validates a transfer action.
   * @param reserve The reserve object
   */
  function validateTransfer(DataTypes.ReserveData storage reserve) internal view {
    require(!reserve.configuration.getPaused(), Errors.ReservePaused());
  }

  /**
   * @notice Validates a drop reserve action.
   * @param reservesList The addresses of all the active reserves
   * @param reserve The reserve object
   * @param asset The address of the reserve's underlying asset
   */
  function validateDropReserve(
    mapping(uint256 => address) storage reservesList,
    DataTypes.ReserveData storage reserve,
    address asset
  ) internal view {
    require(asset != address(0), Errors.ZeroAddressNotValid());
    require(reserve.id != 0 || reservesList[0] == asset, Errors.AssetNotListed());
    require(
      IERC20(reserve.variableDebtTokenAddress).totalSupply() == 0,
      Errors.VariableDebtSupplyNotZero()
    );
    require(
      IERC20(reserve.aTokenAddress).totalSupply() == 0 && reserve.accruedToTreasury == 0,
      Errors.UnderlyingClaimableRightsNotZero()
    );
  }

  /**
   * @notice Validates the action of setting efficiency mode.
   * @param eModeCategories a mapping storing configurations for all efficiency mode categories
   * @param userConfig the user configuration
   * @param categoryId The id of the category
   */
  function validateSetUserEMode(
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    uint8 categoryId
  ) internal view {
    DataTypes.EModeCategory storage eModeCategory = eModeCategories[categoryId];
    // category is invalid if the liq threshold is not set
    require(
      categoryId == 0 || eModeCategory.liquidationThreshold != 0,
      Errors.InconsistentEModeCategory()
    );

    // eMode can always be enabled if the user hasn't supplied anything
    if (userConfig.isEmpty()) {
      return;
    }

    // if user is trying to set another category than default we require that
    // either the user is not borrowing, or it's borrowing assets of categoryId
    if (categoryId != 0) {
      uint256 i = 0;
      bool isBorrowed = false;
      uint128 cachedBorrowableBitmap = eModeCategory.borrowableBitmap;
      uint256 cachedUserConfig = userConfig.data;
      unchecked {
        while (cachedUserConfig != 0) {
          (cachedUserConfig, isBorrowed, ) = UserConfiguration.getNextFlags(cachedUserConfig);

          if (isBorrowed) {
            require(
              EModeConfiguration.isReserveEnabledOnBitmap(cachedBorrowableBitmap, i),
              Errors.NotBorrowableInEMode()
            );
          }
          ++i;
        }
      }
    }
  }

  /**
   * @notice Validates the action of activating the asset as collateral.
   * @dev Only possible if the asset has non-zero LTV and the user is not in isolation mode
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig the user configuration
   * @param reserveConfig The reserve configuration
   * @return True if the asset can be activated as collateral, false otherwise
   */
  function validateUseAsCollateral(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveConfigurationMap memory reserveConfig
  ) internal view returns (bool) {
    if (reserveConfig.getLtv() == 0) {
      return false;
    }
    if (!userConfig.isUsingAsCollateralAny()) {
      return true;
    }
    (bool isolationModeActive, , ) = userConfig.getIsolationModeState(reservesData, reservesList);

    return (!isolationModeActive && reserveConfig.getDebtCeiling() == 0);
  }

  /**
   * @notice Validates if an asset should be automatically activated as collateral in the following actions: supply,
   * transfer, and liquidate
   * @dev This is used to ensure that isolated assets are not enabled as collateral automatically
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig the user configuration
   * @param reserveConfig The reserve configuration
   * @return True if the asset can be activated as collateral, false otherwise
   */
  function validateAutomaticUseAsCollateral(
    address sender,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveConfigurationMap memory reserveConfig,
    address aTokenAddress
  ) internal view returns (bool) {
    if (reserveConfig.getDebtCeiling() != 0) {
      // ensures only the ISOLATED_COLLATERAL_SUPPLIER_ROLE can enable collateral as side-effect of an action
      IPoolAddressesProvider addressesProvider = IncentivizedERC20(aTokenAddress)
        .POOL()
        .ADDRESSES_PROVIDER();
      if (
        !IAccessControl(addressesProvider.getACLManager()).hasRole(
          ISOLATED_COLLATERAL_SUPPLIER_ROLE,
          sender
        )
      ) return false;
    }
    return validateUseAsCollateral(reservesData, reservesList, userConfig, reserveConfig);
  }
}
