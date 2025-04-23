// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../interfaces/IPool.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';
import {IAToken} from '../interfaces/IAToken.sol';
import {IVariableDebtToken} from '../interfaces/IVariableDebtToken.sol';
import {IDefaultInterestRateStrategyV2} from '../interfaces/IDefaultInterestRateStrategyV2.sol';
import {AaveProtocolDataProvider} from './AaveProtocolDataProvider.sol';
import {WadRayMath} from '../protocol/libraries/math/WadRayMath.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {AggregatorInterface} from '../dependencies/chainlink/AggregatorInterface.sol';
import {IERC20DetailedBytes} from './interfaces/IERC20DetailedBytes.sol';
import {IUiPoolDataProviderV3} from './interfaces/IUiPoolDataProviderV3.sol';

contract UiPoolDataProviderV3 is IUiPoolDataProviderV3 {
  using WadRayMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  AggregatorInterface public immutable networkBaseTokenPriceInUsdProxyAggregator;
  AggregatorInterface public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;
  uint256 public constant ETH_CURRENCY_UNIT = 1 ether;
  address public constant MKR_ADDRESS = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

  constructor(
    AggregatorInterface _networkBaseTokenPriceInUsdProxyAggregator,
    AggregatorInterface _marketReferenceCurrencyPriceInUsdProxyAggregator
  ) {
    networkBaseTokenPriceInUsdProxyAggregator = _networkBaseTokenPriceInUsdProxyAggregator;
    marketReferenceCurrencyPriceInUsdProxyAggregator = _marketReferenceCurrencyPriceInUsdProxyAggregator;
  }

  function getReservesList(
    IPoolAddressesProvider provider
  ) external view override returns (address[] memory) {
    IPool pool = IPool(provider.getPool());
    return pool.getReservesList();
  }

  function getReservesData(
    IPoolAddressesProvider provider
  ) external view override returns (AggregatedReserveData[] memory, BaseCurrencyInfo memory) {
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
      DataTypes.ReserveDataLegacy memory baseData = pool.getReserveData(
        reserveData.underlyingAsset
      );
      //the liquidity index. Expressed in ray
      reserveData.liquidityIndex = baseData.liquidityIndex;
      //variable borrow index. Expressed in ray
      reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
      //the current supply rate. Expressed in ray
      reserveData.liquidityRate = baseData.currentLiquidityRate;
      //the current variable borrow rate. Expressed in ray
      reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
      reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
      reserveData.aTokenAddress = baseData.aTokenAddress;
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
      (
        reserveData.baseLTVasCollateral,
        reserveData.reserveLiquidationThreshold,
        reserveData.reserveLiquidationBonus,
        reserveData.decimals,
        reserveData.reserveFactor
      ) = reserveConfigurationMap.getParams();
      reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;

      (
        reserveData.isActive,
        reserveData.isFrozen,
        reserveData.borrowingEnabled,
        reserveData.isPaused
      ) = reserveConfigurationMap.getFlags();

      // interest rates
      try
        IDefaultInterestRateStrategyV2(reserveData.interestRateStrategyAddress).getInterestRateData(
          reserveData.underlyingAsset
        )
      returns (IDefaultInterestRateStrategyV2.InterestRateDataRay memory res) {
        reserveData.baseVariableBorrowRate = res.baseVariableBorrowRate;
        reserveData.variableRateSlope1 = res.variableRateSlope1;
        reserveData.variableRateSlope2 = res.variableRateSlope2;
        reserveData.optimalUsageRatio = res.optimalUsageRatio;
      } catch {}

      // v3 only
      reserveData.deficit = uint128(pool.getReserveDeficit(reserveData.underlyingAsset));
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
      reserveData.isolationModeTotalDebt = baseData.isolationModeTotalDebt;
      reserveData.accruedToTreasury = baseData.accruedToTreasury;

      reserveData.borrowableInIsolation = reserveConfigurationMap.getBorrowableInIsolation();
      reserveData.virtualUnderlyingBalance = pool.getVirtualUnderlyingBalance(
        reserveData.underlyingAsset
      );
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

  /// @inheritdoc IUiPoolDataProviderV3
  function getEModes(IPoolAddressesProvider provider) external view returns (Emode[] memory) {
    IPool pool = IPool(provider.getPool());
    Emode[] memory tempCategories = new Emode[](256);
    uint8 eModesFound = 0;
    uint8 missCounter = 0;
    for (uint8 i = 1; i < 256; i++) {
      DataTypes.CollateralConfig memory cfg = pool.getEModeCategoryCollateralConfig(i);
      if (cfg.liquidationThreshold != 0) {
        tempCategories[eModesFound] = Emode({
          eMode: DataTypes.EModeCategory({
            ltv: cfg.ltv,
            liquidationThreshold: cfg.liquidationThreshold,
            liquidationBonus: cfg.liquidationBonus,
            label: pool.getEModeCategoryLabel(i),
            collateralBitmap: pool.getEModeCategoryCollateralBitmap(i),
            borrowableBitmap: pool.getEModeCategoryBorrowableBitmap(i)
          }),
          id: i
        });
        ++eModesFound;
        missCounter = 0;
      } else {
        ++missCounter;
      }
      // assumes there will never be a gap > 2 when setting eModes
      if (missCounter > 2) break;
    }
    Emode[] memory categories = new Emode[](eModesFound);
    for (uint8 i = 0; i < eModesFound; i++) {
      categories[i] = tempCategories[i];
    }
    return categories;
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
      DataTypes.ReserveDataLegacy memory baseData = pool.getReserveData(reserves[i]);

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
