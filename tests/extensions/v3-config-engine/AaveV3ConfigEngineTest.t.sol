// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {VmSafe} from 'forge-std/Base.sol';
import {IAaveV3ConfigEngine} from '../../../src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {AaveV3MockListing} from './mocks/AaveV3MockListing.sol';
import {AaveV3MockListingWithEModeCreation} from './mocks/AaveV3MockListingWithEModeCreation.sol';
import {AaveV3MockListingCustom} from './mocks/AaveV3MockListingCustom.sol';
import {AaveV3MockListingCustomWithEModeCreation} from './mocks/AaveV3MockListingCustomWithEModeCreation.sol';
import {AaveV3MockCapUpdate} from './mocks/AaveV3MockCapUpdate.sol';
import {AaveV3MockCollateralUpdate} from './mocks/AaveV3MockCollateralUpdate.sol';
import {AaveV3MockCollateralUpdateNoChange} from './mocks/AaveV3MockCollateralUpdateNoChange.sol';
import {AaveV3MockCollateralUpdateWrongBonus, AaveV3MockCollateralUpdateCorrectBonus} from './mocks/AaveV3MockCollateralUpdateWrongBonus.sol';
import {AaveV3MockCollateralUpdateLtZero} from './mocks/AaveV3MockCollateralUpdateLtZero.sol';
import {AaveV3MockCollateralUpdateLtZeroLiqProtocolFeeOnly} from './mocks/AaveV3MockCollateralUpdateLtZeroLiqProtocolFeeOnly.sol';
import {AaveV3MockBorrowUpdate} from './mocks/AaveV3MockBorrowUpdate.sol';
import {AaveV3MockBorrowUpdateNoChange} from './mocks/AaveV3MockBorrowUpdateNoChange.sol';
import {AaveV3MockRatesUpdate} from './mocks/AaveV3MockRatesUpdate.sol';
import {AaveV3MockPriceFeedUpdate} from './mocks/AaveV3MockPriceFeedUpdate.sol';
import {AaveV3MockPriceFeedUpdateInvalidDecimals} from './mocks/AaveV3MockPriceFeedUpdateInvalidDecimals.sol';
import {MockAggregator18Decimals} from './mocks/MockAggregator18Decimals.sol';
import {AaveV3MockEModeCategoryUpdate, AaveV3MockEModeCategoryUpdateEdgeBonus} from './mocks/AaveV3MockEModeCategoryUpdate.sol';
import {AaveV3MockEModeCategoryUpdateNoChange} from './mocks/AaveV3MockEModeCategoryUpdateNoChange.sol';
import {AaveV3MockAssetEModeUpdate} from './mocks/AaveV3MockAssetEModeUpdate.sol';
import {AaveV3MockEModeCategoryCreation} from './mocks/AaveV3MockEModeCategoryCreation.sol';

import {IPoolConfigurator} from '../../../src/contracts/interfaces/IPoolConfigurator.sol';
import {ATokenInstance} from '../../../src/contracts/instances/ATokenInstance.sol';
import {EModeConfiguration} from '../../../src/contracts/protocol/libraries/configuration/EModeConfiguration.sol';
import {VariableDebtTokenInstance} from '../../../src/contracts/instances/VariableDebtTokenInstance.sol';
import {TestnetProcedures, AaveV3ConfigEngine} from '../../utils/TestnetProcedures.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {MockAggregator} from '../../../src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {IPool, IPoolAddressesProvider} from '../../utils/ProtocolV3TestBase.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {ProtocolV3TestBase, IDefaultInterestRateStrategyV2, ReserveConfig, ReserveTokens} from '../../utils/ProtocolV3TestBase.sol';

contract AaveV3ConfigEngineTest is TestnetProcedures, ProtocolV3TestBase {
  using stdStorage for StdStorage;
  address configEngine;

  function setUp() public {
    initTestEnvironment();
    configEngine = report.configEngine;
  }

  function testListings() public {
    address asset = address(new TestnetERC20('1INCH', '1INCH', 18, address(this)));

    address feed = address(new MockAggregator(int256(25e8)));
    AaveV3MockListing payload = new AaveV3MockListing(asset, feed, configEngine);

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineListing',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineListing',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: '1INCH',
      underlying: asset,
      aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      decimals: 18,
      ltv: 82_50,
      liquidationThreshold: 86_00,
      liquidationBonus: 105_00,
      liquidationProtocolFee: 10_00,
      reserveFactor: 10_00,
      usageAsCollateralEnabled: true,
      borrowingEnabled: true,
      interestRateStrategy: AaveV3ConfigEngine(configEngine).DEFAULT_INTEREST_RATE_STRATEGY(),
      isPaused: false,
      isActive: true,
      isFrozen: false,
      isSiloed: false,
      isBorrowableInIsolation: false,
      isFlashloanable: false,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      virtualBalance: 0,
      aTokenUnderlyingBalance: 0
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);

    _noReservesConfigsChangesApartNewListings(allConfigsBefore, allConfigsAfter);

    _validateReserveTokensImpls(
      _findReserveConfigBySymbol(allConfigsAfter, '1INCH'),
      ReserveTokens({
        aToken: address(contracts.aToken),
        variableDebtToken: address(contracts.variableDebtToken)
      })
    );

    _validateAssetSourceOnOracle(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      asset,
      feed
    );

    _validateInterestRateStrategy(
      asset,
      contracts.protocolDataProvider.getInterestRateStrategyAddress(asset),
      AaveV3ConfigEngine(configEngine).DEFAULT_INTEREST_RATE_STRATEGY(),
      IDefaultInterestRateStrategyV2.InterestRateDataRay({
        optimalUsageRatio: _bpsToRay(payload.newListings()[0].rateStrategyParams.optimalUsageRatio),
        baseVariableBorrowRate: _bpsToRay(
          payload.newListings()[0].rateStrategyParams.baseVariableBorrowRate
        ),
        variableRateSlope1: _bpsToRay(
          payload.newListings()[0].rateStrategyParams.variableRateSlope1
        ),
        variableRateSlope2: _bpsToRay(
          payload.newListings()[0].rateStrategyParams.variableRateSlope2
        )
      })
    );
  }

  function testListingWithEModeCategoryCreation() public {
    address asset = address(new TestnetERC20('1INCH', '1INCH', 18, address(this)));

    address feed = address(new MockAggregator(int256(25e8)));
    AaveV3MockListingWithEModeCreation payload = new AaveV3MockListingWithEModeCreation(
      asset,
      feed,
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineListingWithEModeCreation',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineListingWithEModeCreation',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: '1INCH',
      underlying: asset,
      aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      decimals: 18,
      ltv: 82_50,
      liquidationThreshold: 86_00,
      liquidationBonus: 105_00,
      liquidationProtocolFee: 10_00,
      reserveFactor: 10_00,
      usageAsCollateralEnabled: true,
      borrowingEnabled: true,
      interestRateStrategy: AaveV3ConfigEngine(configEngine).DEFAULT_INTEREST_RATE_STRATEGY(),
      isPaused: false,
      isActive: true,
      isFrozen: false,
      isSiloed: false,
      isBorrowableInIsolation: false,
      isFlashloanable: false,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      virtualBalance: 0,
      aTokenUnderlyingBalance: 0
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);

    _noReservesConfigsChangesApartNewListings(allConfigsBefore, allConfigsAfter);

    _validateReserveTokensImpls(
      _findReserveConfigBySymbol(allConfigsAfter, '1INCH'),
      ReserveTokens({
        aToken: address(contracts.aToken),
        variableDebtToken: address(contracts.variableDebtToken)
      })
    );

    _validateAssetSourceOnOracle(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      asset,
      feed
    );

    _validateInterestRateStrategy(
      asset,
      contracts.protocolDataProvider.getInterestRateStrategyAddress(asset),
      AaveV3ConfigEngine(configEngine).DEFAULT_INTEREST_RATE_STRATEGY(),
      IDefaultInterestRateStrategyV2.InterestRateDataRay({
        optimalUsageRatio: _bpsToRay(payload.newListings()[0].rateStrategyParams.optimalUsageRatio),
        baseVariableBorrowRate: _bpsToRay(
          payload.newListings()[0].rateStrategyParams.baseVariableBorrowRate
        ),
        variableRateSlope1: _bpsToRay(
          payload.newListings()[0].rateStrategyParams.variableRateSlope1
        ),
        variableRateSlope2: _bpsToRay(
          payload.newListings()[0].rateStrategyParams.variableRateSlope2
        )
      })
    );

    DataTypes.EModeCategory memory eModeCategoryData;
    eModeCategoryData.ltv = 97_40;
    eModeCategoryData.liquidationThreshold = 97_60;
    eModeCategoryData.liquidationBonus = 101_50; // 100_00 + 1_50
    eModeCategoryData.label = 'Listed Asset EMode';
    eModeCategoryData.collateralBitmap = 8; // 1000
    eModeCategoryData.borrowableBitmap = 8; // 1000

    _validateEmodeCategory(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      1,
      eModeCategoryData
    );
  }

  function testListingsCustom() public {
    address asset = address(new TestnetERC20('PSP', 'PSP', 18, address(this)));

    address feed = address(new MockAggregator(int256(15e8)));
    address aTokenImpl = address(
      new ATokenInstance(contracts.poolProxy, report.rewardsControllerProxy, report.treasury)
    );
    address vTokenImpl = address(
      new VariableDebtTokenInstance(contracts.poolProxy, report.rewardsControllerProxy)
    );

    AaveV3MockListingCustom payload = new AaveV3MockListingCustom(
      asset,
      feed,
      configEngine,
      aTokenImpl,
      vTokenImpl
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineListingCustom',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineListingCustom',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: 'PSP',
      underlying: asset,
      aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      decimals: 18,
      ltv: 82_50,
      liquidationThreshold: 86_00,
      liquidationBonus: 105_00,
      liquidationProtocolFee: 10_00,
      reserveFactor: 10_00,
      usageAsCollateralEnabled: true,
      borrowingEnabled: true,
      interestRateStrategy: AaveV3ConfigEngine(configEngine).DEFAULT_INTEREST_RATE_STRATEGY(),
      isPaused: false,
      isActive: true,
      isFrozen: false,
      isSiloed: false,
      isBorrowableInIsolation: false,
      isFlashloanable: false,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      virtualBalance: 0,
      aTokenUnderlyingBalance: 0
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);

    _noReservesConfigsChangesApartNewListings(allConfigsBefore, allConfigsAfter);

    _validateReserveTokensImpls(
      _findReserveConfigBySymbol(allConfigsAfter, 'PSP'),
      ReserveTokens({aToken: aTokenImpl, variableDebtToken: vTokenImpl})
    );

    _validateAssetSourceOnOracle(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      asset,
      feed
    );

    _validateInterestRateStrategy(
      asset,
      contracts.protocolDataProvider.getInterestRateStrategyAddress(asset),
      AaveV3ConfigEngine(configEngine).DEFAULT_INTEREST_RATE_STRATEGY(),
      IDefaultInterestRateStrategyV2.InterestRateDataRay({
        optimalUsageRatio: _bpsToRay(
          payload.newListingsCustom()[0].base.rateStrategyParams.optimalUsageRatio
        ),
        baseVariableBorrowRate: _bpsToRay(
          payload.newListingsCustom()[0].base.rateStrategyParams.baseVariableBorrowRate
        ),
        variableRateSlope1: _bpsToRay(
          payload.newListingsCustom()[0].base.rateStrategyParams.variableRateSlope1
        ),
        variableRateSlope2: _bpsToRay(
          payload.newListingsCustom()[0].base.rateStrategyParams.variableRateSlope2
        )
      })
    );
  }

  function testListingsCustomWithEModeCategoryCreation() public {
    address asset = address(new TestnetERC20('PSP', 'PSP', 18, address(this)));

    address feed = address(new MockAggregator(int256(15e8)));
    address aTokenImpl = address(
      new ATokenInstance(contracts.poolProxy, report.rewardsControllerProxy, report.treasury)
    );
    address vTokenImpl = address(
      new VariableDebtTokenInstance(contracts.poolProxy, report.rewardsControllerProxy)
    );

    AaveV3MockListingCustomWithEModeCreation payload = new AaveV3MockListingCustomWithEModeCreation(
      asset,
      feed,
      configEngine,
      aTokenImpl,
      vTokenImpl
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineListingCustomWithEModeCreation',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineListingCustomWithEModeCreation',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: 'PSP',
      underlying: asset,
      aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      decimals: 18,
      ltv: 82_50,
      liquidationThreshold: 86_00,
      liquidationBonus: 105_00,
      liquidationProtocolFee: 10_00,
      reserveFactor: 10_00,
      usageAsCollateralEnabled: true,
      borrowingEnabled: true,
      interestRateStrategy: AaveV3ConfigEngine(configEngine).DEFAULT_INTEREST_RATE_STRATEGY(),
      isPaused: false,
      isActive: true,
      isFrozen: false,
      isSiloed: false,
      isBorrowableInIsolation: false,
      isFlashloanable: false,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      virtualBalance: 0,
      aTokenUnderlyingBalance: 0
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);

    _noReservesConfigsChangesApartNewListings(allConfigsBefore, allConfigsAfter);

    _validateReserveTokensImpls(
      _findReserveConfigBySymbol(allConfigsAfter, 'PSP'),
      ReserveTokens({aToken: aTokenImpl, variableDebtToken: vTokenImpl})
    );

    _validateAssetSourceOnOracle(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      asset,
      feed
    );

    _validateInterestRateStrategy(
      asset,
      contracts.protocolDataProvider.getInterestRateStrategyAddress(asset),
      AaveV3ConfigEngine(configEngine).DEFAULT_INTEREST_RATE_STRATEGY(),
      IDefaultInterestRateStrategyV2.InterestRateDataRay({
        optimalUsageRatio: _bpsToRay(
          payload.newListingsCustom()[0].base.rateStrategyParams.optimalUsageRatio
        ),
        baseVariableBorrowRate: _bpsToRay(
          payload.newListingsCustom()[0].base.rateStrategyParams.baseVariableBorrowRate
        ),
        variableRateSlope1: _bpsToRay(
          payload.newListingsCustom()[0].base.rateStrategyParams.variableRateSlope1
        ),
        variableRateSlope2: _bpsToRay(
          payload.newListingsCustom()[0].base.rateStrategyParams.variableRateSlope2
        )
      })
    );

    DataTypes.EModeCategory memory eModeCategoryData;
    eModeCategoryData.ltv = 97_40;
    eModeCategoryData.liquidationThreshold = 97_60;
    eModeCategoryData.liquidationBonus = 101_50; // 100_00 + 1_50
    eModeCategoryData.label = 'Listed Asset EMode';
    eModeCategoryData.collateralBitmap = 8; // 1000
    eModeCategoryData.borrowableBitmap = 8; // 1000

    _validateEmodeCategory(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      1,
      eModeCategoryData
    );
  }

  function testCapsUpdate() public {
    // this asset has been listed before
    address asset = tokenList.usdx;
    AaveV3MockCapUpdate payload = new AaveV3MockCapUpdate(asset, configEngine);

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineCaps',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineCaps',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(allConfigsBefore, asset);

    expectedAssetConfig.supplyCap = 1_000_000;
    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testCollateralsUpdates() public {
    // this asset has been listed before
    address asset = tokenList.usdx;
    AaveV3MockCollateralUpdate payload = new AaveV3MockCollateralUpdate(asset, configEngine);

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineCollateral',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineCollateral',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(allConfigsBefore, asset);

    expectedAssetConfig.ltv = 62_00;
    expectedAssetConfig.liquidationThreshold = 72_00;
    expectedAssetConfig.liquidationBonus = 106_00; // 100_00 + 6_00

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  // TODO manage this after testFail* deprecation.
  // This should not be necessary, but there seems there is no other way
  // of validating that when all collateral params are KEEP_CURRENT, the config
  // engine doesn't call the POOL_CONFIGURATOR.
  // So the solution is expecting the event emitted on the POOL_CONFIGURATOR,
  // and as this doesn't happen, expect the failure of the test
  function testCollateralsUpdatesNoChangeShouldNotEmit() public {
    // this asset has been listed before
    address asset = tokenList.usdx;
    AaveV3MockCollateralUpdateNoChange payload = new AaveV3MockCollateralUpdateNoChange(
      asset,
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    payload.execute();

    VmSafe.Log[] memory emittedLogs = vm.getRecordedLogs();
    assertEq(emittedLogs.length, 0);
  }

  // Same as testCollateralsUpdatesNoChangeShouldNotEmit, but this time should work, as we are not expecting any event emitted
  function testCollateralsUpdatesNoChange() public {
    // this asset has been listed before
    address asset = tokenList.usdx;
    AaveV3MockCollateralUpdateNoChange payload = new AaveV3MockCollateralUpdateNoChange(
      asset,
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineCollateralNoChange',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineCollateralNoChange',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(allConfigsBefore, asset);

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testCollateralUpdateWrongBonus() public {
    address asset = tokenList.usdx;
    AaveV3MockCollateralUpdateWrongBonus payload = new AaveV3MockCollateralUpdateWrongBonus(
      asset,
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    vm.expectRevert(bytes('INVALID_LT_LB_RATIO'));
    payload.execute();
  }

  function testCollateralUpdateCorrectBonus() public {
    address asset = tokenList.usdx;
    AaveV3MockCollateralUpdateCorrectBonus payload = new AaveV3MockCollateralUpdateCorrectBonus(
      asset,
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineCollateralEdgeBonus',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineCollateralEdgeBonus',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(allConfigsBefore, asset);
    expectedAssetConfig.ltv = 62_00;
    expectedAssetConfig.liquidationThreshold = 90_00;
    expectedAssetConfig.liquidationBonus = 111_00; // 100_00 + 11_00

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  /**
   * @notice Tests that attempting to set debtCeiling when base liquidation threshold (lt) is zero
   * should revert with 'DEBT_CEILING_REQUIRES_LT_NON_ZERO'.
   * @dev Even though the asset is enabled as collateral in an eMode category, debtCeiling
   * cannot be set when base lt=0 because debt ceiling (isolation mode) requires the asset
   * to be collateral in base mode.
   */
  function testCollateralUpdateLtZeroDebtCeilingShouldRevert() public {
    // Use existing asset and set lt to 0
    address asset = tokenList.usdx;

    // First, set the asset's lt to 0 (making it non-collateral in base mode)
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(asset, 0, 0, 0);

    // Set an eMode category with lt != 0 to simulate the scenario where
    // an asset has lt=0 in base mode but can be used as collateral in eMode
    contracts.poolConfiguratorProxy.setEModeCategory(10, 80_00, 85_00, 105_00, 'Test eMode');

    // Set the asset to be collateral in the eMode
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(asset, 10, true);
    vm.stopPrank();

    // Attempt to update both liquidationProtocolFee and debtCeiling when base lt=0
    // This should revert because debtCeiling cannot be set when lt=0
    AaveV3MockCollateralUpdateLtZero payload = new AaveV3MockCollateralUpdateLtZero(
      asset,
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    // Expect revert because debtCeiling cannot be set when base lt=0
    vm.expectRevert(bytes('DEBT_CEILING_REQUIRES_LT_NON_ZERO'));
    payload.execute();
  }

  /**
   * @notice Tests that liquidationProtocolFee can be configured independently even when
   * the base liquidation threshold (lt) is zero.
   * @dev This test verifies that liqProtocolFee updates work when base lt=0 but the asset
   * is enabled as collateral in an eMode category.
   */
  function testCollateralUpdateLtZeroLiqProtocolFeeOnly() public {
    // Use existing asset and set lt to 0
    address asset = tokenList.wbtc;

    // First, set the asset's lt to 0 (making it non-collateral in base mode)
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(asset, 0, 0, 0);

    // Set an eMode category with lt != 0
    contracts.poolConfiguratorProxy.setEModeCategory(11, 75_00, 80_00, 105_00, 'Test eMode 2');

    // Set the asset to be collateral in the eMode
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(asset, 11, true);
    vm.stopPrank();

    // Now update only liquidationProtocolFee even though base lt=0
    AaveV3MockCollateralUpdateLtZeroLiqProtocolFeeOnly payload = new AaveV3MockCollateralUpdateLtZeroLiqProtocolFeeOnly(
        asset,
        configEngine
      );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestCollateralLtZeroLiqProtocolFeeOnly',
      IPool(address(contracts.poolProxy))
    );

    // This should succeed - liquidationProtocolFee can be set even when base lt=0
    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestCollateralLtZeroLiqProtocolFeeOnly',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(allConfigsBefore, asset);

    // Verify that liquidationProtocolFee was updated
    expectedAssetConfig.liquidationProtocolFee = 20_00;

    // Base LTV and LT should remain 0
    expectedAssetConfig.ltv = 0;
    expectedAssetConfig.liquidationThreshold = 0;

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testBorrowsUpdates() public {
    address asset = tokenList.usdx;
    AaveV3MockBorrowUpdate payload = new AaveV3MockBorrowUpdate(asset, configEngine);

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineBorrow',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineBorrow',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(allConfigsBefore, asset);
    expectedAssetConfig.reserveFactor = 15_00;
    expectedAssetConfig.borrowingEnabled = true;
    expectedAssetConfig.isFlashloanable = false;

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testBorrowUpdatesNoChange() public {
    address asset = tokenList.usdx;
    AaveV3MockBorrowUpdateNoChange payload = new AaveV3MockBorrowUpdateNoChange(
      asset,
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineBorrowNoChange',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineBorrowNoChange',
      IPool(address(contracts.poolProxy))
    );

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(allConfigsBefore, asset);

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testRateStrategiesUpdates() public {
    address asset = tokenList.usdx;
    AaveV3MockRatesUpdate payload = new AaveV3MockRatesUpdate(asset, configEngine);

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    createConfigurationSnapshot('preTestEngineRates', IPool(address(contracts.poolProxy)));

    payload.execute();

    createConfigurationSnapshot('postTestEngineRates', IPool(address(contracts.poolProxy)));

    _validateInterestRateStrategy(
      asset,
      contracts.protocolDataProvider.getInterestRateStrategyAddress(asset),
      AaveV3ConfigEngine(configEngine).DEFAULT_INTEREST_RATE_STRATEGY(),
      IDefaultInterestRateStrategyV2.InterestRateDataRay({
        optimalUsageRatio: _bpsToRay(payload.rateStrategiesUpdates()[0].params.optimalUsageRatio),
        baseVariableBorrowRate: _bpsToRay(
          payload.rateStrategiesUpdates()[0].params.baseVariableBorrowRate
        ),
        variableRateSlope1: _bpsToRay(payload.rateStrategiesUpdates()[0].params.variableRateSlope1),
        variableRateSlope2: _bpsToRay(payload.rateStrategiesUpdates()[0].params.variableRateSlope2)
      })
    );
  }

  function testPriceFeedsUpdates() public {
    address asset = tokenList.usdx;
    address newFeed = address(new MockAggregator(int256(1.05e8)));
    AaveV3MockPriceFeedUpdate payload = new AaveV3MockPriceFeedUpdate(asset, newFeed, configEngine);

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    createConfigurationSnapshot('preTestEnginePriceFeed', IPool(address(contracts.poolProxy)));

    payload.execute();

    createConfigurationSnapshot('postTestEnginePriceFeed', IPool(address(contracts.poolProxy)));

    _validateAssetSourceOnOracle(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      asset,
      newFeed
    );
  }

  /**
   * @notice Tests that attempting to set a price feed with decimals != 8 reverts with
   * 'FEED_MUST_USE_8_DECIMALS'.
   * @dev The PriceFeedEngine validates that all price feeds must use exactly 8 decimals
   * to ensure consistency across the protocol.
   */
  function testPriceFeedUpdateInvalidDecimalsShouldRevert() public {
    address asset = tokenList.usdx;
    // Create a mock aggregator with 18 decimals instead of 8
    address invalidFeed = address(new MockAggregator18Decimals(int256(1.05e18)));

    AaveV3MockPriceFeedUpdateInvalidDecimals payload = new AaveV3MockPriceFeedUpdateInvalidDecimals(
      asset,
      invalidFeed,
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    // Expect revert because price feed has 18 decimals instead of 8
    vm.expectRevert(bytes('FEED_MUST_USE_8_DECIMALS'));
    payload.execute();
  }

  function testEModeCategoryCreation() public {
    AaveV3MockEModeCategoryCreation payload = new AaveV3MockEModeCategoryCreation(
      tokenList.weth,
      tokenList.usdx,
      tokenList.wbtc,
      tokenList.weth,
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    payload.execute();

    DataTypes.EModeCategory memory prevEmodeCategoryData;
    prevEmodeCategoryData.ltv = 50_00;
    prevEmodeCategoryData.liquidationThreshold = 60_00;
    prevEmodeCategoryData.liquidationBonus = 101_00; // 100_00 + 1_00
    prevEmodeCategoryData.label = 'No assets';

    uint256 bitmap = contracts.poolProxy.getEModeCategoryBorrowableBitmap(1);
    assertEq(bitmap, 0);
    bitmap = contracts.poolProxy.getEModeCategoryCollateralBitmap(1);
    assertEq(bitmap, 0);
    _validateEmodeCategory(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      1,
      prevEmodeCategoryData
    );

    prevEmodeCategoryData.ltv = 97_40;
    prevEmodeCategoryData.liquidationThreshold = 97_60;
    prevEmodeCategoryData.liquidationBonus = 101_50; // 100_00 + 1_50
    prevEmodeCategoryData.label = 'Test';
    prevEmodeCategoryData.collateralBitmap = 5; // 101
    prevEmodeCategoryData.borrowableBitmap = 6; // 110
    _validateEmodeCategory(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      2,
      prevEmodeCategoryData
    );
  }

  function testEModeCategoryUpdates() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);

    AaveV3MockEModeCategoryUpdate payload = new AaveV3MockEModeCategoryUpdate(configEngine);

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    createConfigurationSnapshot(
      'preTestEngineEModeCategoryUpdate',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    createConfigurationSnapshot(
      'postTestEngineEModeCategoryUpdate',
      IPool(address(contracts.poolProxy))
    );

    DataTypes.EModeCategory memory prevEmodeCategoryData;
    prevEmodeCategoryData.ltv = 97_40;
    prevEmodeCategoryData.liquidationThreshold = 97_60;
    prevEmodeCategoryData.liquidationBonus = 101_50; // 100_00 + 1_50
    prevEmodeCategoryData.label = 'ETH Correlated';

    _validateEmodeCategory(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      1,
      prevEmodeCategoryData
    );
  }

  function testEModeCategoryUpdatesWrongBonus() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);

    AaveV3MockEModeCategoryUpdateEdgeBonus payload = new AaveV3MockEModeCategoryUpdateEdgeBonus(
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    vm.expectRevert(bytes('INVALID_LT_LB_RATIO'));
    payload.execute();
  }

  // TODO manage this after testFail* deprecation.
  function testEModeCategoryUpdatesNoChangeShouldNotEmit() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);

    AaveV3MockEModeCategoryUpdateNoChange payload = new AaveV3MockEModeCategoryUpdateNoChange(
      configEngine
    );

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    payload.execute();

    VmSafe.Log[] memory emittedLogs = vm.getRecordedLogs();
    assertEq(emittedLogs.length, 0);
  }

  // Same as testEModeCategoryUpdatesNoChangeShouldNotEmit, but this time should work, as we are not expecting any event emitted
  function testEModeCategoryUpdatesNoChange() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);
    AaveV3MockEModeCategoryUpdateNoChange payload = new AaveV3MockEModeCategoryUpdateNoChange(
      configEngine
    );

    DataTypes.EModeCategoryLegacy memory eModeCategoryDataBefore = contracts
      .poolProxy
      .getEModeCategoryData(1);

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));

    createConfigurationSnapshot(
      'preTestEngineEModeCategoryNoChange',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    createConfigurationSnapshot(
      'postTestEngineEModeCategoryNoChange',
      IPool(address(contracts.poolProxy))
    );

    DataTypes.EModeCategory memory prevEmodeCategoryData;
    prevEmodeCategoryData.ltv = eModeCategoryDataBefore.ltv;
    prevEmodeCategoryData.liquidationThreshold = eModeCategoryDataBefore.liquidationThreshold;
    prevEmodeCategoryData.liquidationBonus = eModeCategoryDataBefore.liquidationBonus;
    prevEmodeCategoryData.label = eModeCategoryDataBefore.label;

    _validateEmodeCategory(
      IPoolAddressesProvider(address(contracts.poolAddressesProvider)),
      1,
      prevEmodeCategoryData
    );
  }

  function testAssetEModeUpdates() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 97_40, 97_60, 101_50, 'ETH Correlated');

    address asset = tokenList.usdx;
    address asset2 = tokenList.wbtc;

    AaveV3MockAssetEModeUpdate payload = new AaveV3MockAssetEModeUpdate(
      asset,
      asset2,
      configEngine
    );

    vm.startPrank(roleList.marketOwner);
    contracts.aclManager.addPoolAdmin(address(payload));
    vm.stopPrank();

    createConfigurationSnapshot(
      'preTestEngineAssetEModeUpdate',
      IPool(address(contracts.poolProxy))
    );

    payload.execute();

    createConfigurationSnapshot(
      'postTestEngineAssetEModeUpdate',
      IPool(address(contracts.poolProxy))
    );

    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(asset);
    uint128 collateralBitmap = contracts.poolProxy.getEModeCategoryCollateralBitmap(1);
    uint128 borrowableBitmap = contracts.poolProxy.getEModeCategoryBorrowableBitmap(1);
    uint128 ltvzeroBitmap = contracts.poolProxy.getEModeCategoryLtvzeroBitmap(1);
    assertEq(EModeConfiguration.isReserveEnabledOnBitmap(collateralBitmap, reserveData.id), false);
    assertEq(EModeConfiguration.isReserveEnabledOnBitmap(borrowableBitmap, reserveData.id), true);
    assertEq(EModeConfiguration.isReserveEnabledOnBitmap(ltvzeroBitmap, reserveData.id), false);
    DataTypes.ReserveDataLegacy memory reserveDataAsset2 = contracts.poolProxy.getReserveData(
      asset2
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(collateralBitmap, reserveDataAsset2.id),
      true
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(borrowableBitmap, reserveDataAsset2.id),
      false
    );
    assertEq(
      EModeConfiguration.isReserveEnabledOnBitmap(ltvzeroBitmap, reserveDataAsset2.id),
      true
    );
  }
}
