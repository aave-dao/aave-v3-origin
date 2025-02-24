// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.5 <0.9.0;

import {AggregatorInterface} from '../../src/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {IERC20Detailed} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IDefaultInterestRateStrategyV2} from '../../src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import {ReserveConfiguration} from '../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IPoolAddressesProvider} from '../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPoolDataProvider} from '../../src/contracts/interfaces/IPoolDataProvider.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {IAaveOracle} from '../../src/contracts/interfaces/IAaveOracle.sol';
import {DataTypes} from '../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {IPoolConfigurator} from '../../src/contracts/interfaces/IPoolConfigurator.sol';
import {ProxyHelpers} from './ProxyHelpers.sol';
import {DiffUtils} from './DiffUtils.sol';

struct ReserveTokens {
  address aToken;
  address variableDebtToken;
}

interface ExtendedAggregatorV2V3Interface is AggregatorInterface {
  function DECIMALS() external view returns (uint8);

  function version() external view returns (uint256);

  /**
   * @notice Returns the name identifier of the feed
   * @return string name
   * @dev https://github.com/bgd-labs/cl-synchronicity-price-adapter compat
   */
  function name() external view returns (string memory);
}

struct ReserveConfig {
  string symbol;
  address underlying;
  address aToken;
  address variableDebtToken;
  uint256 decimals;
  uint256 ltv;
  uint256 liquidationThreshold;
  uint256 liquidationBonus;
  uint256 liquidationProtocolFee;
  uint256 reserveFactor;
  bool usageAsCollateralEnabled;
  bool borrowingEnabled;
  address interestRateStrategy;
  bool isPaused;
  bool isActive;
  bool isFrozen;
  bool isSiloed;
  bool isBorrowableInIsolation;
  bool isFlashloanable;
  uint256 supplyCap;
  uint256 borrowCap;
  uint256 debtCeiling;
  bool virtualAccActive;
  uint256 virtualBalance;
  uint256 aTokenUnderlyingBalance;
}

struct LocalVars {
  address[] reserves;
  ReserveConfig[] configs;
}

/**
 * only applicable to harmony at this point
 */
contract ProtocolV3TestBase is DiffUtils {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /**
   * @dev Generates a markdown compatible snapshot of the whole pool configuration into `/reports`.
   * @param reportName filename suffix for the generated reports.
   * @param pool the pool to be snapshot
   * @return ReserveConfig[] list of configs
   */
  function createConfigurationSnapshot(
    string memory reportName,
    IPool pool
  ) public virtual returns (ReserveConfig[] memory) {
    return createConfigurationSnapshot(reportName, pool, true, true, true, true);
  }

  function createConfigurationSnapshot(
    string memory reportName,
    IPool pool,
    bool reserveConfigs,
    bool strategyConfigs,
    bool eModeConigs,
    bool poolConfigs
  ) public virtual returns (ReserveConfig[] memory) {
    string memory path = string(abi.encodePacked('./reports/', reportName, '.json'));
    // overwrite with empty json to later be extended as foundry does not currently support adding new keys
    vm.writeFile(
      path,
      '{ "eModes": {}, "reserves": {}, "strategies": {}, "poolConfiguration": {}, "raw": {} }'
    );
    vm.serializeUint('root', 'chainId', block.chainid);
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    if (reserveConfigs) _writeReserveConfigs(path, configs, pool);
    if (strategyConfigs) _writeStrategyConfigs(path, configs);
    if (eModeConigs) _writeEModeConfigs(path, pool);
    if (poolConfigs) _writePoolConfiguration(path, pool);

    return configs;
  }

  function _writeEModeConfigs(string memory path, IPool pool) internal virtual {
    // keys for json stringification
    string memory eModesKey = 'emodes';
    string memory content = '{}';
    vm.serializeJson(eModesKey, '{}');
    uint8 emptyCounter = 0;
    for (uint8 i = 0; i < 256; i++) {
      DataTypes.CollateralConfig memory cfg = pool.getEModeCategoryCollateralConfig(i);
      if (cfg.liquidationThreshold == 0) {
        if (++emptyCounter > 2) break;
      } else {
        string memory key = vm.toString(i);
        vm.serializeJson(key, '{}');
        vm.serializeUint(key, 'eModeCategory', i);
        vm.serializeString(key, 'label', pool.getEModeCategoryLabel(i));
        vm.serializeUint(key, 'ltv', cfg.ltv);
        vm.serializeString(
          key,
          'collateralBitmap',
          vm.toString(pool.getEModeCategoryCollateralBitmap(i))
        );
        vm.serializeString(
          key,
          'borrowableBitmap',
          vm.toString(pool.getEModeCategoryBorrowableBitmap(i))
        );
        vm.serializeUint(key, 'liquidationThreshold', cfg.liquidationThreshold);
        string memory object = vm.serializeUint(key, 'liquidationBonus', cfg.liquidationBonus);
        content = vm.serializeString(eModesKey, key, object);
        emptyCounter = 0;
      }
    }
    string memory output = vm.serializeString('root', 'eModes', content);
    vm.writeJson(output, path);
  }

  function _writeStrategyConfigs(
    string memory path,
    ReserveConfig[] memory configs
  ) internal virtual {
    // keys for json stringification
    string memory strategiesKey = 'strategies';
    string memory content = '{}';
    vm.serializeJson(strategiesKey, '{}');

    for (uint256 i = 0; i < configs.length; i++) {
      address asset = configs[i].underlying;
      string memory key = vm.toString(asset);
      vm.serializeJson(key, '{}');
      vm.serializeString(key, 'address', vm.toString(configs[i].interestRateStrategy));
      IDefaultInterestRateStrategyV2 strategy = IDefaultInterestRateStrategyV2(
        configs[i].interestRateStrategy
      );
      vm.serializeString(
        key,
        'baseVariableBorrowRate',
        vm.toString(strategy.getBaseVariableBorrowRate(asset))
      );
      vm.serializeString(
        key,
        'variableRateSlope1',
        vm.toString(strategy.getVariableRateSlope1(asset))
      );
      vm.serializeString(
        key,
        'variableRateSlope2',
        vm.toString(strategy.getVariableRateSlope2(asset))
      );
      vm.serializeString(
        key,
        'maxVariableBorrowRate',
        vm.toString(strategy.getMaxVariableBorrowRate(asset))
      );
      string memory object = vm.serializeString(
        key,
        'optimalUsageRatio',
        vm.toString(strategy.getOptimalUsageRatio(asset))
      );

      content = vm.serializeString(strategiesKey, key, object);
    }
    string memory output = vm.serializeString('root', 'strategies', content);
    vm.writeJson(output, path);
  }

  function _writeReserveConfigs(
    string memory path,
    ReserveConfig[] memory configs,
    IPool pool
  ) internal virtual {
    // keys for json stringification
    string memory reservesKey = 'reserves';
    string memory content = '{}';
    vm.serializeJson(reservesKey, '{}');

    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IAaveOracle oracle = IAaveOracle(addressesProvider.getPriceOracle());
    for (uint256 i = 0; i < configs.length; i++) {
      ReserveConfig memory config = configs[i];
      ExtendedAggregatorV2V3Interface assetOracle = ExtendedAggregatorV2V3Interface(
        oracle.getSourceOfAsset(config.underlying)
      );

      string memory key = vm.toString(config.underlying);
      vm.serializeJson(key, '{}');
      vm.serializeString(key, 'symbol', config.symbol);
      vm.serializeUint(key, 'id', i);
      vm.serializeUint(key, 'ltv', config.ltv);
      vm.serializeUint(key, 'liquidationThreshold', config.liquidationThreshold);
      vm.serializeUint(key, 'liquidationBonus', config.liquidationBonus);
      vm.serializeUint(key, 'liquidationProtocolFee', config.liquidationProtocolFee);
      vm.serializeUint(key, 'reserveFactor', config.reserveFactor);
      vm.serializeUint(key, 'decimals', config.decimals);
      vm.serializeUint(key, 'borrowCap', config.borrowCap);
      vm.serializeUint(key, 'supplyCap', config.supplyCap);
      vm.serializeUint(key, 'debtCeiling', config.debtCeiling);
      vm.serializeBool(key, 'usageAsCollateralEnabled', config.usageAsCollateralEnabled);
      vm.serializeBool(key, 'borrowingEnabled', config.borrowingEnabled);
      vm.serializeBool(key, 'isPaused', config.isPaused);
      vm.serializeBool(key, 'isActive', config.isActive);
      vm.serializeBool(key, 'isFrozen', config.isFrozen);
      vm.serializeBool(key, 'isSiloed', config.isSiloed);
      vm.serializeBool(key, 'isBorrowableInIsolation', config.isBorrowableInIsolation);
      vm.serializeBool(key, 'isFlashloanable', config.isFlashloanable);
      vm.serializeAddress(key, 'interestRateStrategy', config.interestRateStrategy);
      vm.serializeAddress(key, 'underlying', config.underlying);
      vm.serializeAddress(key, 'aToken', config.aToken);
      vm.serializeAddress(key, 'variableDebtToken', config.variableDebtToken);
      vm.serializeString(key, 'aTokenSymbol', IERC20Detailed(config.aToken).symbol());
      vm.serializeString(key, 'aTokenName', IERC20Detailed(config.aToken).name());
      vm.serializeString(
        key,
        'variableDebtTokenSymbol',
        IERC20Detailed(config.variableDebtToken).symbol()
      );
      vm.serializeString(
        key,
        'variableDebtTokenName',
        IERC20Detailed(config.variableDebtToken).name()
      );
      vm.serializeAddress(key, 'oracle', address(assetOracle));
      if (address(assetOracle) != address(0)) {
        try assetOracle.description() returns (string memory name) {
          vm.serializeString(key, 'oracleDescription', name);
        } catch {
          try assetOracle.name() returns (string memory name) {
            vm.serializeString(key, 'oracleName', name);
          } catch {}
        }
        try assetOracle.decimals() returns (uint8 decimals) {
          vm.serializeUint(key, 'oracleDecimals', decimals);
        } catch {
          try assetOracle.DECIMALS() returns (uint8 decimals) {
            vm.serializeUint(key, 'oracleDecimals', decimals);
          } catch {}
        }
      }

      vm.serializeBool(key, 'virtualAccountingActive', config.virtualAccActive);
      vm.serializeString(key, 'virtualBalance', vm.toString(config.virtualBalance));
      vm.serializeString(
        key,
        'aTokenUnderlyingBalance',
        vm.toString(config.aTokenUnderlyingBalance)
      );

      string memory out = vm.serializeString(
        key,
        'oracleLatestAnswer',
        vm.toString(uint256(oracle.getAssetPrice(config.underlying)))
      );
      content = vm.serializeString(reservesKey, key, out);
    }
    string memory output = vm.serializeString('root', 'reserves', content);
    vm.writeJson(output, path);
  }

  function _writePoolConfiguration(string memory path, IPool pool) internal virtual {
    // keys for json stringification
    string memory poolConfigKey = 'poolConfig';

    // addresses provider
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    vm.serializeAddress(poolConfigKey, 'poolAddressesProvider', address(addressesProvider));

    // oracles
    vm.serializeAddress(poolConfigKey, 'oracle', addressesProvider.getPriceOracle());
    vm.serializeAddress(
      poolConfigKey,
      'priceOracleSentinel',
      addressesProvider.getPriceOracleSentinel()
    );

    // pool configurator
    IPoolConfigurator configurator = IPoolConfigurator(addressesProvider.getPoolConfigurator());
    vm.serializeAddress(poolConfigKey, 'poolConfigurator', address(configurator));

    // PoolDataProvider
    IPoolDataProvider pdp = IPoolDataProvider(addressesProvider.getPoolDataProvider());
    vm.serializeAddress(poolConfigKey, 'protocolDataProvider', address(pdp));

    // pool
    string memory content = vm.serializeAddress(poolConfigKey, 'pool', address(pool));

    string memory output = vm.serializeString('root', 'poolConfig', content);
    vm.writeJson(output, path);
  }

  function _getReservesConfigs(IPool pool) internal view virtual returns (ReserveConfig[] memory) {
    LocalVars memory vars;

    vars.reserves = pool.getReservesList();

    vars.configs = new ReserveConfig[](vars.reserves.length);

    for (uint256 i = 0; i < vars.reserves.length; i++) {
      vars.configs[i] = _getStructReserveConfig(pool, vars.reserves[i]);
    }

    return vars.configs;
  }

  function _getStructReserveConfig(
    IPool pool,
    address reserve
  ) internal view virtual returns (ReserveConfig memory) {
    ReserveConfig memory localConfig;
    DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(reserve);
    DataTypes.ReserveDataLegacy memory reserveData = pool.getReserveData(reserve);

    localConfig.underlying = reserve;
    localConfig.aToken = reserveData.aTokenAddress;
    localConfig.variableDebtToken = reserveData.variableDebtTokenAddress;
    localConfig.interestRateStrategy = reserveData.interestRateStrategyAddress;
    (
      localConfig.ltv,
      localConfig.liquidationThreshold,
      localConfig.liquidationBonus,
      localConfig.decimals,
      localConfig.reserveFactor
    ) = configuration.getParams();
    (
      localConfig.isActive,
      localConfig.isFrozen,
      localConfig.borrowingEnabled,
      localConfig.isPaused
    ) = configuration.getFlags();
    if (reserve == 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2) {
      localConfig.symbol = 'MKR';
    } else {
      localConfig.symbol = IERC20Detailed(reserve).symbol();
    }
    localConfig.usageAsCollateralEnabled = localConfig.liquidationThreshold != 0;
    localConfig.isSiloed = configuration.getSiloedBorrowing();
    (localConfig.borrowCap, localConfig.supplyCap) = configuration.getCaps();
    localConfig.debtCeiling = configuration.getDebtCeiling();
    localConfig.liquidationProtocolFee = configuration.getLiquidationProtocolFee();
    localConfig.isBorrowableInIsolation = configuration.getBorrowableInIsolation();

    localConfig.isFlashloanable = configuration.getFlashLoanEnabled();

    // 3.1 configurations
    localConfig.virtualAccActive = configuration.getIsVirtualAccActive();

    if (localConfig.virtualAccActive) {
      localConfig.virtualBalance = pool.getVirtualUnderlyingBalance(reserve);
    }
    localConfig.aTokenUnderlyingBalance = IERC20Detailed(reserve).balanceOf(localConfig.aToken);

    return localConfig;
  }

  // TODO This should probably be simplified with assembly, too much boilerplate
  function _clone(
    ReserveConfig memory config
  ) internal pure virtual returns (ReserveConfig memory) {
    return
      ReserveConfig({
        symbol: config.symbol,
        underlying: config.underlying,
        aToken: config.aToken,
        variableDebtToken: config.variableDebtToken,
        decimals: config.decimals,
        ltv: config.ltv,
        liquidationThreshold: config.liquidationThreshold,
        liquidationBonus: config.liquidationBonus,
        liquidationProtocolFee: config.liquidationProtocolFee,
        reserveFactor: config.reserveFactor,
        usageAsCollateralEnabled: config.usageAsCollateralEnabled,
        borrowingEnabled: config.borrowingEnabled,
        interestRateStrategy: config.interestRateStrategy,
        isPaused: config.isPaused,
        isActive: config.isActive,
        isFrozen: config.isFrozen,
        isSiloed: config.isSiloed,
        isBorrowableInIsolation: config.isBorrowableInIsolation,
        isFlashloanable: config.isFlashloanable,
        supplyCap: config.supplyCap,
        borrowCap: config.borrowCap,
        debtCeiling: config.debtCeiling,
        virtualAccActive: config.virtualAccActive,
        virtualBalance: config.virtualBalance,
        aTokenUnderlyingBalance: config.aTokenUnderlyingBalance
      });
  }

  function _findReserveConfig(
    ReserveConfig[] memory configs,
    address underlying
  ) internal pure virtual returns (ReserveConfig memory) {
    for (uint256 i = 0; i < configs.length; i++) {
      if (configs[i].underlying == underlying) {
        // Important to clone the struct, to avoid unexpected side effect if modifying the returned config
        return _clone(configs[i]);
      }
    }
    revert('RESERVE_CONFIG_NOT_FOUND');
  }

  function _findReserveConfigBySymbol(
    ReserveConfig[] memory configs,
    string memory symbolOfUnderlying
  ) internal pure virtual returns (ReserveConfig memory) {
    for (uint256 i = 0; i < configs.length; i++) {
      if (
        keccak256(abi.encodePacked(configs[i].symbol)) ==
        keccak256(abi.encodePacked(symbolOfUnderlying))
      ) {
        return _clone(configs[i]);
      }
    }
    revert('RESERVE_CONFIG_NOT_FOUND');
  }

  function _validateReserveConfig(
    ReserveConfig memory expectedConfig,
    ReserveConfig[] memory allConfigs
  ) internal pure {
    ReserveConfig memory config = _findReserveConfig(allConfigs, expectedConfig.underlying);
    require(
      keccak256(bytes(config.symbol)) == keccak256(bytes(expectedConfig.symbol)),
      '_validateReserveConfig() : INVALID_SYMBOL'
    );
    require(
      config.underlying == expectedConfig.underlying,
      '_validateReserveConfig() : INVALID_UNDERLYING'
    );
    require(config.decimals == expectedConfig.decimals, '_validateReserveConfig: INVALID_DECIMALS');
    require(config.ltv == expectedConfig.ltv, '_validateReserveConfig: INVALID_LTV');
    require(
      config.liquidationThreshold == expectedConfig.liquidationThreshold,
      '_validateReserveConfig: INVALID_LIQ_THRESHOLD'
    );
    require(
      config.liquidationBonus == expectedConfig.liquidationBonus,
      '_validateReserveConfig: INVALID_LIQ_BONUS'
    );
    require(
      config.liquidationProtocolFee == expectedConfig.liquidationProtocolFee,
      '_validateReserveConfig: INVALID_LIQUIDATION_PROTOCOL_FEE'
    );
    require(
      config.reserveFactor == expectedConfig.reserveFactor,
      '_validateReserveConfig: INVALID_RESERVE_FACTOR'
    );

    require(
      config.usageAsCollateralEnabled == expectedConfig.usageAsCollateralEnabled,
      '_validateReserveConfig: INVALID_USAGE_AS_COLLATERAL'
    );
    require(
      config.borrowingEnabled == expectedConfig.borrowingEnabled,
      '_validateReserveConfig: INVALID_BORROWING_ENABLED'
    );
    require(
      config.isActive == expectedConfig.isActive,
      '_validateReserveConfig: INVALID_IS_ACTIVE'
    );
    require(
      config.isFrozen == expectedConfig.isFrozen,
      '_validateReserveConfig: INVALID_IS_FROZEN'
    );
    require(
      config.isSiloed == expectedConfig.isSiloed,
      '_validateReserveConfig: INVALID_IS_SILOED'
    );
    require(
      config.isBorrowableInIsolation == expectedConfig.isBorrowableInIsolation,
      '_validateReserveConfig: INVALID_IS_BORROWABLE_IN_ISOLATION'
    );
    require(
      config.isFlashloanable == expectedConfig.isFlashloanable,
      '_validateReserveConfig: INVALID_IS_FLASHLOANABLE'
    );
    require(
      config.supplyCap == expectedConfig.supplyCap,
      '_validateReserveConfig: INVALID_SUPPLY_CAP'
    );
    require(
      config.borrowCap == expectedConfig.borrowCap,
      '_validateReserveConfig: INVALID_BORROW_CAP'
    );
    require(
      config.debtCeiling == expectedConfig.debtCeiling,
      '_validateReserveConfig: INVALID_DEBT_CEILING'
    );
    require(
      config.interestRateStrategy == expectedConfig.interestRateStrategy,
      '_validateReserveConfig: INVALID_INTEREST_RATE_STRATEGY'
    );
  }

  function _validateInterestRateStrategy(
    address reserve,
    address interestRateStrategyAddress,
    address expectedStrategy,
    IDefaultInterestRateStrategyV2.InterestRateDataRay memory expectedStrategyValues
  ) internal view {
    IDefaultInterestRateStrategyV2 strategy = IDefaultInterestRateStrategyV2(
      interestRateStrategyAddress
    );

    require(
      address(strategy) == expectedStrategy,
      '_validateInterestRateStrategy() : INVALID_STRATEGY_ADDRESS'
    );

    require(
      strategy.getOptimalUsageRatio(reserve) == expectedStrategyValues.optimalUsageRatio,
      '_validateInterestRateStrategy() : INVALID_OPTIMAL_RATIO'
    );
    require(
      strategy.getBaseVariableBorrowRate(reserve) == expectedStrategyValues.baseVariableBorrowRate,
      '_validateInterestRateStrategy() : INVALID_BASE_VARIABLE_BORROW'
    );
    require(
      strategy.getVariableRateSlope1(reserve) == expectedStrategyValues.variableRateSlope1,
      '_validateInterestRateStrategy() : INVALID_VARIABLE_SLOPE_1'
    );
    require(
      strategy.getVariableRateSlope2(reserve) == expectedStrategyValues.variableRateSlope2,
      '_validateInterestRateStrategy() : INVALID_VARIABLE_SLOPE_2'
    );
  }

  function _noReservesConfigsChangesApartNewListings(
    ReserveConfig[] memory allConfigsBefore,
    ReserveConfig[] memory allConfigsAfter
  ) internal pure {
    for (uint256 i = 0; i < allConfigsBefore.length; i++) {
      _requireNoChangeInConfigs(allConfigsBefore[i], allConfigsAfter[i]);
    }
  }

  function _noReservesConfigsChangesApartFrom(
    ReserveConfig[] memory allConfigsBefore,
    ReserveConfig[] memory allConfigsAfter,
    address assetChangedUnderlying
  ) internal pure {
    require(allConfigsBefore.length == allConfigsAfter.length, 'A_UNEXPECTED_NEW_LISTING_HAPPENED');

    for (uint256 i = 0; i < allConfigsBefore.length; i++) {
      if (assetChangedUnderlying != allConfigsBefore[i].underlying) {
        _requireNoChangeInConfigs(allConfigsBefore[i], allConfigsAfter[i]);
      }
    }
  }

  /// @dev Version in batch, useful when multiple asset changes are expected
  function _noReservesConfigsChangesApartFrom(
    ReserveConfig[] memory allConfigsBefore,
    ReserveConfig[] memory allConfigsAfter,
    address[] memory assetChangedUnderlying
  ) internal pure {
    require(allConfigsBefore.length == allConfigsAfter.length, 'A_UNEXPECTED_NEW_LISTING_HAPPENED');

    for (uint256 i = 0; i < allConfigsBefore.length; i++) {
      bool isAssetExpectedToChange;
      for (uint256 j = 0; j < assetChangedUnderlying.length; j++) {
        if (assetChangedUnderlying[j] == allConfigsBefore[i].underlying) {
          isAssetExpectedToChange = true;
          break;
        }
      }
      if (!isAssetExpectedToChange) {
        _requireNoChangeInConfigs(allConfigsBefore[i], allConfigsAfter[i]);
      }
    }
  }

  function _requireNoChangeInConfigs(
    ReserveConfig memory config1,
    ReserveConfig memory config2
  ) internal pure {
    require(
      keccak256(abi.encodePacked(config1.symbol)) == keccak256(abi.encodePacked(config2.symbol)),
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_SYMBOL_CHANGED'
    );
    require(
      config1.underlying == config2.underlying,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_UNDERLYING_CHANGED'
    );
    require(
      config1.aToken == config2.aToken,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_A_TOKEN_CHANGED'
    );
    require(
      config1.variableDebtToken == config2.variableDebtToken,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_VARIABLE_DEBT_TOKEN_CHANGED'
    );
    require(
      config1.decimals == config2.decimals,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_DECIMALS_CHANGED'
    );
    require(
      config1.ltv == config2.ltv,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LTV_CHANGED'
    );
    require(
      config1.liquidationThreshold == config2.liquidationThreshold,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LIQ_THRESHOLD_CHANGED'
    );
    require(
      config1.liquidationBonus == config2.liquidationBonus,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LIQ_BONUS_CHANGED'
    );
    require(
      config1.liquidationProtocolFee == config2.liquidationProtocolFee,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LIQ_PROTOCOL_FEE_CHANGED'
    );
    require(
      config1.reserveFactor == config2.reserveFactor,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_RESERVE_FACTOR_CHANGED'
    );
    require(
      config1.usageAsCollateralEnabled == config2.usageAsCollateralEnabled,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_USAGE_AS_COLLATERAL_ENABLED_CHANGED'
    );
    require(
      config1.borrowingEnabled == config2.borrowingEnabled,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_BORROWING_ENABLED_CHANGED'
    );
    require(
      config1.interestRateStrategy == config2.interestRateStrategy,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_INTEREST_RATE_STRATEGY_CHANGED'
    );
    require(
      config1.isActive == config2.isActive,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_ACTIVE_CHANGED'
    );
    require(
      config1.isFrozen == config2.isFrozen,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_FROZEN_CHANGED'
    );
    require(
      config1.isSiloed == config2.isSiloed,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_SILOED_CHANGED'
    );
    require(
      config1.isBorrowableInIsolation == config2.isBorrowableInIsolation,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_BORROWABLE_IN_ISOLATION_CHANGED'
    );
    require(
      config1.isFlashloanable == config2.isFlashloanable,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_FLASHLOANABLE_CHANGED'
    );
    require(
      config1.supplyCap == config2.supplyCap,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_SUPPLY_CAP_CHANGED'
    );
    require(
      config1.borrowCap == config2.borrowCap,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_BORROW_CAP_CHANGED'
    );
    require(
      config1.debtCeiling == config2.debtCeiling,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_DEBT_CEILING_CHANGED'
    );
  }

  function _validateCountOfListings(
    uint256 count,
    ReserveConfig[] memory allConfigsBefore,
    ReserveConfig[] memory allConfigsAfter
  ) internal pure {
    require(
      allConfigsBefore.length == allConfigsAfter.length - count,
      '_validateCountOfListings() : INVALID_COUNT_OF_LISTINGS'
    );
  }

  function _validateReserveTokensImpls(
    ReserveConfig memory config,
    ReserveTokens memory expectedImpls
  ) internal {
    require(
      ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(vm, config.aToken) ==
        expectedImpls.aToken,
      '_validateReserveTokensImpls() : INVALID_VARIABLE_DEBT_IMPL'
    );
    require(
      ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
        vm,
        config.variableDebtToken
      ) == expectedImpls.variableDebtToken,
      '_validateReserveTokensImpls() : INVALID_ATOKEN_IMPL'
    );
    vm.stopPrank();
  }

  function _validateAssetSourceOnOracle(
    IPoolAddressesProvider addressesProvider,
    address asset,
    address expectedSource
  ) internal view {
    IAaveOracle oracle = IAaveOracle(addressesProvider.getPriceOracle());

    require(
      oracle.getSourceOfAsset(asset) == expectedSource,
      '_validateAssetSourceOnOracle() : INVALID_PRICE_SOURCE'
    );
  }

  function _validateEmodeCategory(
    IPoolAddressesProvider addressesProvider,
    uint256 category,
    DataTypes.EModeCategory memory expectedCategoryData
  ) internal view {
    address poolAddress = addressesProvider.getPool();
    DataTypes.CollateralConfig memory cfg = IPool(poolAddress).getEModeCategoryCollateralConfig(
      uint8(category)
    );
    require(
      keccak256(bytes(IPool(poolAddress).getEModeCategoryLabel(uint8(category)))) ==
        keccak256(bytes(expectedCategoryData.label)),
      '_validateEmodeCategory(): INVALID_LABEL'
    );
    require(cfg.ltv == expectedCategoryData.ltv, '_validateEmodeCategory(): INVALID_LTV');
    require(
      cfg.liquidationThreshold == expectedCategoryData.liquidationThreshold,
      '_validateEmodeCategory(): INVALID_LT'
    );
    require(
      cfg.liquidationBonus == expectedCategoryData.liquidationBonus,
      '_validateEmodeCategory(): INVALID_LB'
    );
    require(
      IPool(poolAddress).getEModeCategoryCollateralBitmap(uint8(category)) ==
        expectedCategoryData.collateralBitmap,
      '_validateEmodeCategory(): INVALID_LB'
    );
    require(
      IPool(poolAddress).getEModeCategoryBorrowableBitmap(uint8(category)) ==
        expectedCategoryData.borrowableBitmap,
      '_validateEmodeCategory(): INVALID_LB'
    );
  }

  /**
   * @dev forwards time by x blocks
   */
  function _skipBlocks(uint128 blocks) internal {
    vm.roll(block.number + blocks);
    vm.warp(block.timestamp + blocks * 12); // assuming a block is around 12seconds
  }

  function _isInUint256Array(
    uint256[] memory haystack,
    uint256 needle
  ) internal pure returns (bool) {
    for (uint256 i = 0; i < haystack.length; i++) {
      if (haystack[i] == needle) return true;
    }
    return false;
  }

  function _isInAddressArray(
    address[] memory haystack,
    address needle
  ) internal pure returns (bool) {
    for (uint256 i = 0; i < haystack.length; i++) {
      if (haystack[i] == needle) return true;
    }
    return false;
  }
}
