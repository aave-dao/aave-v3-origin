// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {AaveV3TokensBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3TokensBatch.sol';
import {AaveV3PoolBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3PoolBatch.sol';
import {AaveV3L2PoolBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3L2PoolBatch.sol';
import {AaveV3GettersBatchOne} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3GettersBatchOne.sol';
import {AaveV3GettersBatchTwo} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3GettersBatchTwo.sol';
import {AaveV3PeripheryBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3PeripheryBatch.sol';
import {AaveV3ParaswapBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3ParaswapBatch.sol';
import {AaveV3SetupBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3SetupBatch.sol';
import {AaveV3MiscBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3MiscBatch.sol';
import {AaveV3HelpersBatchOne} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3HelpersBatchOne.sol';
import {AaveV3HelpersBatchTwo} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3HelpersBatchTwo.sol';
import {WETH9} from '../../src/contracts/dependencies/weth/WETH9.sol';
import {AugustusRegistryMock} from '../mocks/AugustusRegistryMock.sol';
import {MockParaSwapFeeClaimer} from '../../src/contracts/mocks/swap/MockParaSwapFeeClaimer.sol';
import {SequencerOracle} from '../../src/contracts/mocks/oracle/SequencerOracle.sol';
import {BatchTestProcedures} from '../utils/BatchTestProcedures.sol';

contract DeploymentsGasLimits is BatchTestProcedures {
  Roles roles;
  MarketConfig config;
  DeployFlags flags;
  MarketReport deployedContracts;

  InitialReport marketReportOne;
  PoolReport poolReportOne;

  AaveV3GettersBatchOne.GettersReportBatchOne gettersReportOne;
  AaveV3GettersBatchTwo.GettersReportBatchTwo gettersReportTwo;

  PeripheryReport peripheryReportOne;
  ParaswapReport paraswapReportOne;
  MiscReport miscReport;
  AaveV3TokensBatch.TokensReport tokensReport;

  SetupReport setupReportTwo;

  AaveV3SetupBatch aaveV3SetupOne;

  event ReportLog(MarketReport report);

  function setUp() public {
    address marketOwner = makeAddr('marketOwner');
    address poolAdmin = makeAddr('poolAdmin');
    address emergencyAdmin = makeAddr('emergencyAdmin');
    bytes32 empty;
    roles = Roles(marketOwner, poolAdmin, emergencyAdmin);

    config = MarketConfig(
      makeAddr('ethUsdOracle'),
      makeAddr('ethUsdOracle'),
      'Testnet Market',
      8,
      address(new AugustusRegistryMock()), // replace with mock of augustus registry
      address(new MockParaSwapFeeClaimer()),
      address(new SequencerOracle(poolAdmin)),
      2 hours, // l2PriceOracleSentinelGracePeriod
      8080,
      empty,
      address(new WETH9()),
      address(0),
      0.0005e4,
      0.0004e4
    );
    flags = DeployFlags(true);

    // Etch the create2 factory
    vm.etch(
      0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7,
      hex'7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3'
    );

    (
      marketReportOne,
      gettersReportOne,
      poolReportOne,
      peripheryReportOne,
      miscReport,
      aaveV3SetupOne
    ) = deployCoreAndPeriphery(roles, config, flags, deployedContracts);

    (
      ,
      ,
      gettersReportTwo,
      ,
      setupReportTwo,
      ,
      miscReport,
      tokensReport,
      paraswapReportOne,
    ) = deployAndSetup(
      roles,
      config,
      flags,
      deployedContracts
    );
  }

  function test0AaveV3SetupDeployment() public {
    new AaveV3SetupBatch(msg.sender, roles, config, deployedContracts);
  }

  function test1AaveV3GettersBatch1Deployment() public {
    new AaveV3GettersBatchOne(
      marketReportOne.poolAddressesProvider,
      config.networkBaseTokenPriceInUsdProxyAggregator,
      config.marketReferenceCurrencyPriceInUsdProxyAggregator
    );
  }

  function test2AaveV3GettersBatch2Deployment() public {
    new AaveV3GettersBatchTwo(
      setupReportTwo.poolProxy,
      roles.poolAdmin,
      config.wrappedNativeToken,
      flags.l2
    );
  }

  function test3AaveV3PoolDeployment() public {
    new AaveV3PoolBatch(marketReportOne.poolAddressesProvider);
  }

  function test4AaveV3L2PoolDeployment() public {
    new AaveV3L2PoolBatch(marketReportOne.poolAddressesProvider);
  }

  function test5PeripheralsRelease() public {
    new AaveV3PeripheryBatch(
      roles.poolAdmin,
      config,
      marketReportOne.poolAddressesProvider,
      address(aaveV3SetupOne)
    );
  }

  function test6MiscDeployment() public {
    new AaveV3MiscBatch(
      flags.l2,
      marketReportOne.poolAddressesProvider,
      config.l2SequencerUptimeFeed,
      config.l2PriceOracleSentinelGracePeriod
    );
  }

  function test7ParaswapDeployment() public {
    new AaveV3ParaswapBatch(
      roles.poolAdmin,
      config,
      marketReportOne.poolAddressesProvider,
      peripheryReportOne.treasury
    );
  }

  function test8SetupMarket() public {
    vm.prank(roles.marketOwner);
    aaveV3SetupOne.setupAaveV3Market(
      roles,
      config,
      poolReportOne.poolImplementation,
      poolReportOne.poolConfiguratorImplementation,
      gettersReportOne.protocolDataProvider,
      peripheryReportOne.aaveOracle,
      peripheryReportOne.rewardsControllerImplementation,
      miscReport.priceOracleSentinel
    );
  }

  function test9TokensMarket() public {
    new AaveV3TokensBatch(setupReportTwo.poolProxy);
  }

  function test10ConfigEngineDeployment() public {
    new AaveV3HelpersBatchOne(
      setupReportTwo.poolProxy,
      setupReportTwo.poolConfiguratorProxy,
      miscReport.defaultInterestRateStrategy,
      peripheryReportOne.aaveOracle,
      setupReportTwo.rewardsControllerProxy,
      peripheryReportOne.treasury,
      tokensReport.aToken,
      tokensReport.variableDebtToken,
      tokensReport.stableDebtToken
    );
  }

  function test11StaticATokenDeployment() public {
    new AaveV3HelpersBatchTwo(
      setupReportTwo.poolProxy,
      setupReportTwo.rewardsControllerProxy,
      peripheryReportOne.proxyAdmin
    );
  }

  function testCheckInitCodeSizeBatchs() public view {
    uint16 maxInitCodeSize = 49152;

    console.log('AaveV3SetupBatch', type(AaveV3SetupBatch).creationCode.length);
    console.log('AaveV3L2PoolBatch', type(AaveV3L2PoolBatch).creationCode.length);
    console.log('AaveV3PoolBatch', type(AaveV3PoolBatch).creationCode.length);
    console.log('AaveV3PeripheryBatch', type(AaveV3PeripheryBatch).creationCode.length);
    console.log('AaveV3MiscBatch', type(AaveV3MiscBatch).creationCode.length);
    console.log('AaveV3ParaswapBatch', type(AaveV3ParaswapBatch).creationCode.length);
    console.log('AaveV3GettersBatchOne', type(AaveV3GettersBatchOne).creationCode.length);
    console.log('AaveV3GettersBatchTwo', type(AaveV3GettersBatchTwo).creationCode.length);
    console.log('AaveV3TokensBatch', type(AaveV3TokensBatch).creationCode.length);
    console.log('AaveV3HelpersBatchOne', type(AaveV3HelpersBatchOne).creationCode.length);
    console.log('AaveV3HelpersBatchTwo', type(AaveV3HelpersBatchTwo).creationCode.length);

    assertLe(
      type(AaveV3SetupBatch).creationCode.length,
      maxInitCodeSize,
      'AaveV3SetupBatch max init code size'
    );
    assertLe(
      type(AaveV3L2PoolBatch).creationCode.length,
      maxInitCodeSize,
      'AaveV3L2PoolBatch max init code size'
    );
    assertLe(
      type(AaveV3PoolBatch).creationCode.length,
      maxInitCodeSize,
      'AaveV3PoolBatch max init code size'
    );
    assertLe(
      type(AaveV3PeripheryBatch).creationCode.length,
      maxInitCodeSize,
      'AaveV3PeripheryBatch max init code size'
    );
    assertLe(
      type(AaveV3MiscBatch).creationCode.length,
      maxInitCodeSize,
      'AaveV3MiscBatch max init code size'
    );
    assertLe(
      type(AaveV3ParaswapBatch).creationCode.length,
      maxInitCodeSize,
      'AaveV3ParaswapBatch max init code size'
    );
    assertLe(
      type(AaveV3GettersBatchOne).creationCode.length,
      maxInitCodeSize,
      'AaveV3GettersBatchOne max init code size'
    );
    assertLe(
      type(AaveV3GettersBatchTwo).creationCode.length,
      maxInitCodeSize,
      'AaveV3GettersBatchTwo max init code size'
    );
    assertLe(
      type(AaveV3TokensBatch).creationCode.length,
      maxInitCodeSize,
      'AaveV3TokensBatch max init code size'
    );
    assertLe(
      type(AaveV3HelpersBatchOne).creationCode.length,
      maxInitCodeSize,
      'AaveV3HelpersBatchOne max init code size'
    );
    assertLe(
      type(AaveV3HelpersBatchTwo).creationCode.length,
      maxInitCodeSize,
      'AaveV3HelpersBatchTwo max init code size'
    );
  }
}
