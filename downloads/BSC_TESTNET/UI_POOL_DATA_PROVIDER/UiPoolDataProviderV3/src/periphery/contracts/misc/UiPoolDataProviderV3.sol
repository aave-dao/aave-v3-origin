// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Detailed} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IPoolAddressesProvider} from 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {IAaveOracle} from 'aave-v3-core/contracts/interfaces/IAaveOracle.sol';
import {IAToken} from 'aave-v3-core/contracts/interfaces/IAToken.sol';
import {IVariableDebtToken} from 'aave-v3-core/contracts/interfaces/IVariableDebtToken.sol';
import {IStableDebtToken} from 'aave-v3-core/contracts/interfaces/IStableDebtToken.sol';
import {DefaultReserveInterestRateStrategy} from 'aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol';
import {AaveProtocolDataProvider} from 'aave-v3-core/contracts/misc/AaveProtocolDataProvider.sol';
import {WadRayMath} from 'aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol';
import {ReserveConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {IEACAggregatorProxy} from './interfaces/IEACAggregatorProxy.sol';
import {IERC20DetailedBytes} from './interfaces/IERC20DetailedBytes.sol';
import {IUiPoolDataProviderV3} from './interfaces/IUiPoolDataProviderV3.sol';

contract UiPoolDataProviderV3 is IUiPoolDataProviderV3 {
  using WadRayMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  IEACAggregatorProxy public immutable networkBaseTokenPriceInUsdProxyAggregator;
  IEACAggregatorProxy public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;
  uint256 public constant ETH_CURRENCY_UNIT = 1 ether;
  address public constant MKR_ADDRESS = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

  constructor(
    IEACAggregatorProxy _networkBaseTokenPriceInUsdProxyAggregator,
    IEACAggregatorProxy _marketReferenceCurrencyPriceInUsdProxyAggregator
  ) {
    networkBaseTokenPriceInUsdProxyAggregator = _networkBaseTokenPriceInUsdProxyAggregator;
    marketReferenceCurrencyPriceInUsdProxyAggregator = _marketReferenceCurrencyPriceInUsdProxyAggregator;
  }

  function getReservesList(
    IPoolAddressesProvider provider
  ) public view override returns (address[] memory) {
    IPool pool = IPool(provider.getPool());
    return pool.getReservesList();
  }

  function getReservesData(
    IPoolAddressesProvider provider
  ) public view override returns (AggregatedReserveData[] memory, BaseCurrencyInfo memory) {
    IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
    IPool pool = IPool(provider.getPool());
    AaveProtocolDataProvider poolDataProvider = AaveProtocolDataProvider(
      provider.getPoolDataProvider()
    );

    address[] memory reserves = pool.getReservesList();
    AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);

    for (uint256 i = 0; i < reserves.length; i++) {
      AggregatedReserveData memory reserveData = reservesData[i];
      reserveData.underlyingAsset = reserves[i];

      // reserve current state
      DataTypes.ReserveData memory baseData = pool.getReserveData(reserveData.underlyingAsset);
      //the liquidity index. Expressed in ray
      reserveData.liquidityIndex = baseData.liquidityIndex;
      //variable borrow index. Expressed in ray
      reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
      //the current supply rate. Expressed in ray
      reserveData.liquidityRate = baseData.currentLiquidityRate;
      //the current variable borrow rate. Expressed in ray
      reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
      //the current stable borrow rate. Expressed in ray
      reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
      reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
      reserveData.aTokenAddress = baseData.aTokenAddress;
      reserveData.stableDebtTokenAddress = baseData.stableDebtTokenAddress;
      reserveData.variableDebtTokenAddress = baseData.variableDebtTokenAddress;
      //address of the interest rate strategy
      reserveData.interestRateStrategyAddress = baseData.interestRateStrategyAddress;
      reserveData.priceInMarketReferenceCurrency = oracle.getAssetPrice(
        reserveData.underlyingAsset
      );
      reserveData.priceOracle = oracle.getSourceOfAsset(reserveData.underlyingAsset);
      reserveData.availableLiquidity = IERC20Detailed(reserveData.underlyingAsset).balanceOf(
        reserveData.aTokenAddress
      );
      (
        reserveData.totalPrincipalStableDebt,
        ,
        reserveData.averageStableRate,
        reserveData.stableDebtLastUpdateTimestamp
      ) = IStableDebtToken(reserveData.stableDebtTokenAddress).getSupplyData();
      reserveData.totalScaledVariableDebt = IVariableDebtToken(reserveData.variableDebtTokenAddress)
        .scaledTotalSupply();

      // Due we take the symbol from underlying token we need a special case for $MKR as symbol() returns bytes32
      if (address(reserveData.underlyingAsset) == address(MKR_ADDRESS)) {
        bytes32 symbol = IERC20DetailedBytes(reserveData.underlyingAsset).symbol();
        bytes32 name = IERC20DetailedBytes(reserveData.underlyingAsset).name();
        reserveData.symbol = bytes32ToString(symbol);
        reserveData.name = bytes32ToString(name);
      } else {
        reserveData.symbol = IERC20Detailed(reserveData.underlyingAsset).symbol();
        reserveData.name = IERC20Detailed(reserveData.underlyingAsset).name();
      }

      //stores the reserve configuration
      DataTypes.ReserveConfigurationMap memory reserveConfigurationMap = baseData.configuration;
      uint256 eModeCategoryId;
      (
        reserveData.baseLTVasCollateral,
        reserveData.reserveLiquidationThreshold,
        reserveData.reserveLiquidationBonus,
        reserveData.decimals,
        reserveData.reserveFactor,
        eModeCategoryId
      ) = reserveConfigurationMap.getParams();
      reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;

      (
        reserveData.isActive,
        reserveData.isFrozen,
        reserveData.borrowingEnabled,
        reserveData.stableBorrowRateEnabled,
        reserveData.isPaused
      ) = reserveConfigurationMap.getFlags();

      // interest rates
      try
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
          .getVariableRateSlope1()
      returns (uint256 res) {
        reserveData.variableRateSlope1 = res;
      } catch {}
      try
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
          .getVariableRateSlope2()
      returns (uint256 res) {
        reserveData.variableRateSlope2 = res;
      } catch {}
      try
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
          .getStableRateSlope1()
      returns (uint256 res) {
        reserveData.stableRateSlope1 = res;
      } catch {}
      try
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
          .getStableRateSlope2()
      returns (uint256 res) {
        reserveData.stableRateSlope2 = res;
      } catch {}
      try
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
          .getBaseStableBorrowRate()
      returns (uint256 res) {
        reserveData.baseStableBorrowRate = res;
      } catch {}
      try
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
          .getBaseVariableBorrowRate()
      returns (uint256 res) {
        reserveData.baseVariableBorrowRate = res;
      } catch {}
      try
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
          .OPTIMAL_USAGE_RATIO()
      returns (uint256 res) {
        reserveData.optimalUsageRatio = res;
      } catch {}

      // v3 only
      reserveData.eModeCategoryId = uint8(eModeCategoryId);
      reserveData.debtCeiling = reserveConfigurationMap.getDebtCeiling();
      reserveData.debtCeilingDecimals = poolDataProvider.getDebtCeilingDecimals();
      (reserveData.borrowCap, reserveData.supplyCap) = reserveConfigurationMap.getCaps();

      try poolDataProvider.getFlashLoanEnabled(reserveData.underlyingAsset) returns (
        bool flashLoanEnabled
      ) {
        reserveData.flashLoanEnabled = flashLoanEnabled;
      } catch (bytes memory) {
        reserveData.flashLoanEnabled = true;
      }

      reserveData.isSiloedBorrowing = reserveConfigurationMap.getSiloedBorrowing();
      reserveData.unbacked = baseData.unbacked;
      reserveData.isolationModeTotalDebt = baseData.isolationModeTotalDebt;
      reserveData.accruedToTreasury = baseData.accruedToTreasury;

      DataTypes.EModeCategory memory categoryData = pool.getEModeCategoryData(
        reserveData.eModeCategoryId
      );
      reserveData.eModeLtv = categoryData.ltv;
      reserveData.eModeLiquidationThreshold = categoryData.liquidationThreshold;
      reserveData.eModeLiquidationBonus = categoryData.liquidationBonus;
      // each eMode category may or may not have a custom oracle to override the individual assets price oracles
      reserveData.eModePriceSource = categoryData.priceSource;
      reserveData.eModeLabel = categoryData.label;

      reserveData.borrowableInIsolation = reserveConfigurationMap.getBorrowableInIsolation();
    }

    BaseCurrencyInfo memory baseCurrencyInfo;
    baseCurrencyInfo.networkBaseTokenPriceInUsd = networkBaseTokenPriceInUsdProxyAggregator
      .latestAnswer();
    baseCurrencyInfo.networkBaseTokenPriceDecimals = networkBaseTokenPriceInUsdProxyAggregator
      .decimals();

    try oracle.BASE_CURRENCY_UNIT() returns (uint256 baseCurrencyUnit) {
      baseCurrencyInfo.marketReferenceCurrencyUnit = baseCurrencyUnit;
      baseCurrencyInfo.marketReferenceCurrencyPriceInUsd = int256(baseCurrencyUnit);
    } catch (bytes memory /*lowLevelData*/) {
      baseCurrencyInfo.marketReferenceCurrencyUnit = ETH_CURRENCY_UNIT;
      baseCurrencyInfo
        .marketReferenceCurrencyPriceInUsd = marketReferenceCurrencyPriceInUsdProxyAggregator
        .latestAnswer();
    }

    return (reservesData, baseCurrencyInfo);
  }

  function getUserReservesData(
    IPoolAddressesProvider provider,
    address user
  ) external view override returns (UserReserveData[] memory, uint8) {
    IPool pool = IPool(provider.getPool());
    address[] memory reserves = pool.getReservesList();
    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(user);

    uint8 userEmodeCategoryId = uint8(pool.getUserEMode(user));

    UserReserveData[] memory userReservesData = new UserReserveData[](
      user != address(0) ? reserves.length : 0
    );

    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);

      // user reserve data
      userReservesData[i].underlyingAsset = reserves[i];
      userReservesData[i].scaledATokenBalance = IAToken(baseData.aTokenAddress).scaledBalanceOf(
        user
      );
      userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(i);

      if (userConfig.isBorrowing(i)) {
        userReservesData[i].scaledVariableDebt = IVariableDebtToken(
          baseData.variableDebtTokenAddress
        ).scaledBalanceOf(user);
        userReservesData[i].principalStableDebt = IStableDebtToken(baseData.stableDebtTokenAddress)
          .principalBalanceOf(user);
        if (userReservesData[i].principalStableDebt != 0) {
          userReservesData[i].stableBorrowRate = IStableDebtToken(baseData.stableDebtTokenAddress)
            .getUserStableRate(user);
          userReservesData[i].stableBorrowLastUpdateTimestamp = IStableDebtToken(
            baseData.stableDebtTokenAddress
          ).getUserLastUpdated(user);
        }
      }
    }

    return (userReservesData, userEmodeCategoryId);
  }

  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }
}
