// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';

import {Test, Vm} from 'forge-std/Test.sol';
import {IAaveOracle} from '../../src/contracts/interfaces/IAaveOracle.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {AggregatorInterface} from '../../src/contracts/dependencies/chainlink/AggregatorInterface.sol';

import {AaveV3HorizonEthereum} from './utils/AaveV3HorizonEthereum.sol';

import {IParameterRegistry} from './dependencies/IParameterRegistry.sol';

abstract contract OracleDynamicBoundsTestBase is Test {
  address constant USTB_NEW_AGGREGATOR = 0x267D0DD05fbc989565C521e0B8882f61027FF32A;
  address constant USCC_NEW_AGGREGATOR = 0x2d7Cd12f24bD28684847bF3e4317899a4Db53c58;
  address constant USYC_NEW_AGGREGATOR = 0x3C405e1FE8a6BE5d9b714B8C88Ad913F236B1639;
  address constant JTRSY_NEW_AGGREGATOR = 0xcf8683fFdFC4b871DF35D05bc763F239612e7272;
  address constant JAAA_NEW_AGGREGATOR = 0x3a8E8491236368a582b651786bEdA49BD5c3BA7B;
  address constant VBILL_NEW_AGGREGATOR = 0x04d81C346252E31Ee888393AF6E2037a9a4d70Af;

  struct ExpectedParams {
    uint64 maxExpectedApy;
    uint32 upperBoundTolerance;
    uint32 lowerBoundTolerance;
    uint32 maxDiscount;
    uint80 lookbackWindowSize;
    bool isUpperBoundEnabled;
    bool isLowerBoundEnabled;
    bool isActionTakingEnabled;
  }

  struct NewAggregator {
    address aggregator;
  }

  mapping(address => ExpectedParams) internal expectedParams; // asset => expected params
  mapping(address => NewAggregator) internal newAggregators; // asset => new aggregator

  IAaveOracle internal aaveOracle;
  IParameterRegistry internal parameterRegistry;
  function setUp() public virtual {
    parameterRegistry = IParameterRegistry(AaveV3HorizonEthereum.RWA_ORACLE_PARAMS_REGISTRY);
  }

  function test_asset(address asset, address oracleSource, bool isAdapter) internal {
    oracleSource = test_horizon_adapter(asset, oracleSource, isAdapter);
    test_registry_params(asset);
    test_lookback_data(asset);
    int256 newAggregatorPrice = test_new_aggregator(asset);
    test_matching_price_data(oracleSource, newAggregatorPrice);
  }

  // check that the price from the oracle source is the same as the price from the new aggregator
  function test_matching_price_data(address oracleSource, int256 newAggregatorPrice) internal {
    // current horizon feed price
    (bool success, bytes memory data) = oracleSource.call(
      abi.encodeWithSignature('latestAnswer()')
    );
    require(success, 'Failed to call latestAnswer()');
    int256 price = abi.decode(data, (int256));

    assertApproxEqRel(price, newAggregatorPrice, 1e12, 'price');
  }

  // test param registry params are configured properly
  function test_registry_params(address asset) internal {
    assertEq(parameterRegistry.assetExists(asset), true, 'assetExists');
    (
      uint64 maxExpectedApy,
      uint32 upperBoundTolerance,
      uint32 lowerBoundTolerance,
      uint32 maxDiscount,
      uint80 lookbackWindowSize,
      bool isUpperBoundEnabled,
      bool isLowerBoundEnabled,
      bool isActionTakingEnabled
    ) = parameterRegistry.getParametersForAsset(asset);

    ExpectedParams memory expectedParam = expectedParams[asset];

    assertEq(maxExpectedApy, expectedParam.maxExpectedApy, 'maxExpectedApy');
    assertEq(upperBoundTolerance, expectedParam.upperBoundTolerance, 'upperBoundTolerance');
    assertEq(lowerBoundTolerance, expectedParam.lowerBoundTolerance, 'lowerBoundTolerance');
    assertEq(maxDiscount, expectedParam.maxDiscount, 'maxDiscount');
    assertEq(lookbackWindowSize, expectedParam.lookbackWindowSize, 'lookbackWindowSize');
    assertEq(isUpperBoundEnabled, expectedParam.isUpperBoundEnabled, 'isUpperBoundEnabled');
    assertEq(isLowerBoundEnabled, expectedParam.isLowerBoundEnabled, 'isLowerBoundEnabled');
    assertEq(isActionTakingEnabled, expectedParam.isActionTakingEnabled, 'isActionTakingEnabled');
  }

  /// test that the oracle source from horizon protocol adapter is the same as the oracle address from the param registry
  function test_horizon_adapter(
    address asset,
    address oracleSource,
    bool isAdapter
  ) internal returns (address) {
    bool success;
    bytes memory data;
    if (isAdapter) {
      // if adapter, get oracle source from horizon adapter
      (success, data) = oracleSource.call(abi.encodeWithSignature('source()'));
      require(success, 'Failed to call source()');
      oracleSource = abi.decode(data, (address));
    }
    address paramRegistryOracle = _getParamRegistryOracle(asset);
    assertEq(paramRegistryOracle, oracleSource, 'paramRegistryOracle');

    return oracleSource;
  }

  // test look back data from param registry is valid
  function test_lookback_data(address asset) internal {
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = parameterRegistry.getLookbackData(asset);

    assertGt(roundId, 0, 'lookback roundId');
    assertGt(answer, 0, 'lookback answer');
    assertApproxEqAbs(
      startedAt,
      vm.getBlockTimestamp() - expectedParams[asset].lookbackWindowSize * 1 days, // within expected lookback window
      1 days * 1.5, // account for differences in update times throughout the day
      'lookback startedAt'
    );
    assertApproxEqAbs(
      updatedAt,
      vm.getBlockTimestamp() - expectedParams[asset].lookbackWindowSize * 1 days, // within expected lookback window
      1 days * 1.5, // account for differences in update times throughout the day
      'lookback updatedAt'
    );
    assertGt(answeredInRound, 0, 'lookback answeredInRound');
  }

  // test new aggregator data is valid; enough rounds for lookback window and valid answers
  function test_new_aggregator(address asset) internal returns (int256) {
    address paramRegistryOracle = _getParamRegistryOracle(asset);
    vm.startPrank(paramRegistryOracle); // has access to price feed
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = AggregatorInterface(newAggregators[asset].aggregator).latestRoundData();
    vm.stopPrank();

    assertGt(roundId, expectedParams[asset].lookbackWindowSize, 'roundId');
    assertGt(answer, 0, 'answer');
    assertApproxEqAbs(startedAt, vm.getBlockTimestamp(), 1 days, 'startedAt');
    assertApproxEqAbs(updatedAt, vm.getBlockTimestamp(), 1 days, 'updatedAt');
    assertGt(answeredInRound, expectedParams[asset].lookbackWindowSize, 'answeredInRound');

    return answer;
  }

  // read oracle address from param registry
  function _getParamRegistryOracle(address asset) internal returns (address) {
    return parameterRegistry.getOracle(asset);
  }
}

/// forge-config: default.evm_version = "cancun"
contract OracleDynamicBoundsTest is OracleDynamicBoundsTestBase {
  function setUp() public virtual override {
    super.setUp();
    vm.createSelectFork('mainnet', 23478406);
    _initEnvironment();
  }

  ExpectedParams internal USTB_EXPECTED_PARAMS =
    ExpectedParams({
      maxExpectedApy: 415,
      upperBoundTolerance: 15,
      lowerBoundTolerance: 5,
      maxDiscount: 10,
      lookbackWindowSize: 4,
      isUpperBoundEnabled: true,
      isLowerBoundEnabled: true,
      isActionTakingEnabled: false
    });
  ExpectedParams internal USCC_EXPECTED_PARAMS =
    ExpectedParams({
      maxExpectedApy: 2500,
      upperBoundTolerance: 50,
      lowerBoundTolerance: 10,
      maxDiscount: 40,
      lookbackWindowSize: 4,
      isUpperBoundEnabled: true,
      isLowerBoundEnabled: true,
      isActionTakingEnabled: false
    });
  ExpectedParams internal USYC_EXPECTED_PARAMS =
    ExpectedParams({
      maxExpectedApy: 420,
      upperBoundTolerance: 15,
      lowerBoundTolerance: 5,
      maxDiscount: 10,
      lookbackWindowSize: 4,
      isUpperBoundEnabled: true,
      isLowerBoundEnabled: true,
      isActionTakingEnabled: false
    });
  ExpectedParams internal JTRSY_EXPECTED_PARAMS =
    ExpectedParams({
      maxExpectedApy: 390,
      upperBoundTolerance: 15,
      lowerBoundTolerance: 5,
      maxDiscount: 10,
      lookbackWindowSize: 4,
      isUpperBoundEnabled: true,
      isLowerBoundEnabled: true,
      isActionTakingEnabled: false
    });
  ExpectedParams internal JAAA_EXPECTED_PARAMS =
    ExpectedParams({
      maxExpectedApy: 520,
      upperBoundTolerance: 50,
      lowerBoundTolerance: 10,
      maxDiscount: 75,
      lookbackWindowSize: 4,
      isUpperBoundEnabled: true,
      isLowerBoundEnabled: true,
      isActionTakingEnabled: false
    });
  ExpectedParams internal VBILL_EXPECTED_PARAMS =
    ExpectedParams({
      maxExpectedApy: 0,
      upperBoundTolerance: 10,
      lowerBoundTolerance: 10,
      maxDiscount: 0,
      lookbackWindowSize: 4,
      isUpperBoundEnabled: true,
      isLowerBoundEnabled: true,
      isActionTakingEnabled: false
    });

  function _initEnvironment() internal virtual {
    expectedParams[AaveV3HorizonEthereum.USTB_ADDRESS] = USTB_EXPECTED_PARAMS;
    expectedParams[AaveV3HorizonEthereum.USCC_ADDRESS] = USCC_EXPECTED_PARAMS;
    expectedParams[AaveV3HorizonEthereum.USYC_ADDRESS] = USYC_EXPECTED_PARAMS;
    expectedParams[AaveV3HorizonEthereum.JTRSY_ADDRESS] = JTRSY_EXPECTED_PARAMS;
    expectedParams[AaveV3HorizonEthereum.JAAA_ADDRESS] = JAAA_EXPECTED_PARAMS;
    expectedParams[AaveV3HorizonEthereum.VBILL_ADDRESS] = VBILL_EXPECTED_PARAMS;

    newAggregators[AaveV3HorizonEthereum.USTB_ADDRESS] = NewAggregator({
      aggregator: USTB_NEW_AGGREGATOR
    });
    newAggregators[AaveV3HorizonEthereum.USCC_ADDRESS] = NewAggregator({
      aggregator: USCC_NEW_AGGREGATOR
    });
    newAggregators[AaveV3HorizonEthereum.USYC_ADDRESS] = NewAggregator({
      aggregator: USYC_NEW_AGGREGATOR
    });
    newAggregators[AaveV3HorizonEthereum.JTRSY_ADDRESS] = NewAggregator({
      aggregator: JTRSY_NEW_AGGREGATOR
    });
    newAggregators[AaveV3HorizonEthereum.JAAA_ADDRESS] = NewAggregator({
      aggregator: JAAA_NEW_AGGREGATOR
    });
    newAggregators[AaveV3HorizonEthereum.VBILL_ADDRESS] = NewAggregator({
      aggregator: VBILL_NEW_AGGREGATOR
    });

    aaveOracle = IAaveOracle(
      IPool(AaveV3HorizonEthereum.POOL).ADDRESSES_PROVIDER().getPriceOracle()
    );
  }

  // check that param registry admin are set properly
  function test_registry_admin() external {
    assertEq(parameterRegistry.owner(), AaveV3HorizonEthereum.HORIZON_OPS, 'owner');
    assertEq(parameterRegistry.updater(), AaveV3HorizonEthereum.HORIZON_OPS, 'updater');
  }

  function test_ustb() external virtual {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.USTB_ADDRESS);
    test_asset(AaveV3HorizonEthereum.USTB_ADDRESS, oracleSource, true);
  }

  function test_uscc() external virtual {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.USCC_ADDRESS);
    test_asset(AaveV3HorizonEthereum.USCC_ADDRESS, oracleSource, true);
  }

  function test_usyc() external virtual {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.USYC_ADDRESS);
    test_asset(AaveV3HorizonEthereum.USYC_ADDRESS, oracleSource, false);
  }

  function test_jtrsy() external virtual {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.JTRSY_ADDRESS);
    test_asset(AaveV3HorizonEthereum.JTRSY_ADDRESS, oracleSource, true);
  }

  function test_jaaa() external virtual {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.JAAA_ADDRESS);
    test_asset(AaveV3HorizonEthereum.JAAA_ADDRESS, oracleSource, true);
  }

  function test_vbill() external virtual {
    // VBILL not deployed yet, get price feed directly from lib
    test_asset(AaveV3HorizonEthereum.VBILL_ADDRESS, AaveV3HorizonEthereum.VBILL_PRICE_FEED, false);
  }
}

/// forge-config: default.evm_version = "cancun"
contract OracleDynamicBoundsPostMigrationTest is OracleDynamicBoundsTest {
  function setUp() public virtual override {
    super.setUp();
    vm.createSelectFork('mainnet', 23483206);
    _initEnvironment();
  }

  function test_ustb() public virtual override {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.USTB_ADDRESS);
    _printAssetPrice(AaveV3HorizonEthereum.USTB_ADDRESS, oracleSource);
    test_aggregator_from_registry(AaveV3HorizonEthereum.USTB_ADDRESS, USTB_NEW_AGGREGATOR);
  }

  function test_uscc() public virtual override {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.USCC_ADDRESS);
    _printAssetPrice(AaveV3HorizonEthereum.USCC_ADDRESS, oracleSource);
    test_aggregator_from_registry(AaveV3HorizonEthereum.USCC_ADDRESS, USCC_NEW_AGGREGATOR);
  }

  function test_usyc() public virtual override {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.USYC_ADDRESS);
    _printAssetPrice(AaveV3HorizonEthereum.USYC_ADDRESS, oracleSource);
    test_aggregator_from_registry(AaveV3HorizonEthereum.USYC_ADDRESS, USYC_NEW_AGGREGATOR);
  }

  function test_jtrsy() public virtual override {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.JTRSY_ADDRESS);
    _printAssetPrice(AaveV3HorizonEthereum.JTRSY_ADDRESS, oracleSource);
    test_aggregator_from_registry(AaveV3HorizonEthereum.JTRSY_ADDRESS, JTRSY_NEW_AGGREGATOR);
  }

  function test_jaaa() public virtual override {
    address oracleSource = aaveOracle.getSourceOfAsset(AaveV3HorizonEthereum.JAAA_ADDRESS);
    _printAssetPrice(AaveV3HorizonEthereum.JAAA_ADDRESS, oracleSource);
    test_aggregator_from_registry(AaveV3HorizonEthereum.JAAA_ADDRESS, JAAA_NEW_AGGREGATOR);
  }

  function test_vbill() public virtual override {
    _printAssetPrice(AaveV3HorizonEthereum.VBILL_ADDRESS, AaveV3HorizonEthereum.VBILL_PRICE_FEED);
    test_aggregator_from_registry(AaveV3HorizonEthereum.VBILL_ADDRESS, VBILL_NEW_AGGREGATOR);
  }

  function _printAssetPrice(address asset, address oracleSource) internal {
    (bool success, bytes memory data) = oracleSource.call(
      abi.encodeWithSignature('latestAnswer()')
    );
    require(success, 'Failed to call latestAnswer()');
    int256 price = abi.decode(data, (int256));
    console.log('asset %s price %8e', asset, uint256(price));
  }

  // check that oracle from param registry points to new aggregator
  function test_aggregator_from_registry(address asset, address newAggregator) internal {
    address paramRegistryOracle = _getParamRegistryOracle(asset);
    (bool success, bytes memory data) = paramRegistryOracle.call(
      abi.encodeWithSignature('aggregator()')
    );
    require(success, 'Failed to call aggregator()');
    address aggregator = abi.decode(data, (address));
    assertEq(aggregator, newAggregator, 'aggregator');
  }
}
