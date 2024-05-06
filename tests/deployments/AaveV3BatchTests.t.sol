// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {AaveV3TokensBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3TokensBatch.sol';
import {AaveV3PoolBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3PoolBatch.sol';
import {AaveV3L2PoolBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3L2PoolBatch.sol';
import {AaveV3GettersBatchOne} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3GettersBatchOne.sol';
import {AaveV3GettersBatchTwo} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3GettersBatchTwo.sol';
import {AaveV3PeripheryBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3PeripheryBatch.sol';
import {AaveV3ParaswapBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3ParaswapBatch.sol';
import {AaveV3SetupBatch} from '../../src/deployments/projects/aave-v3-batched/batches/AaveV3SetupBatch.sol';
import {WETH9} from '../../src/contracts/dependencies/weth/WETH9.sol';
import {AugustusRegistryMock} from '../mocks/AugustusRegistryMock.sol';
import {MockParaSwapFeeClaimer} from 'src/contracts/mocks/swap/MockParaSwapFeeClaimer.sol';
import {BatchTestProcedures} from '../utils/BatchTestProcedures.sol';
import {AaveV3BatchOrchestration} from '../../src/deployments/projects/aave-v3-batched/AaveV3BatchOrchestration.sol';

contract AaveV3BatchTests is BatchTestProcedures {
  address deployer;
  address marketOwner;
  address emergencyAdmin;

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

  SetupReport setupReportTwo;

  AaveV3SetupBatch aaveV3SetupOne;

  event ReportLog(MarketReport report);

  function setUp() public {
    deployer = makeAddr('deployer');
    marketOwner = makeAddr('marketOwner');
    poolAdmin = makeAddr('poolAdmin');
    emergencyAdmin = makeAddr('emergencyAdmin');
    bytes32 emptySalt;
    roles = Roles(marketOwner, poolAdmin, emergencyAdmin);
    config = MarketConfig(
      makeAddr('ethUsdOracle'),
      makeAddr('ethUsdOracle'),
      'Testnet Market',
      8,
      address(new AugustusRegistryMock()),
      address(new MockParaSwapFeeClaimer()),
      8080,
      emptySalt,
      address(new WETH9()),
      address(0),
      0.0005e4,
      0.0004e4
    );
    flags = DeployFlags(false);

    (
      marketReportOne,
      gettersReportOne,
      poolReportOne,
      peripheryReportOne,
      paraswapReportOne,
      aaveV3SetupOne
    ) = deployCoreAndPeriphery(roles, config, flags, deployedContracts);
    (, , gettersReportTwo, , setupReportTwo, , , ) = deployAndSetup(
      roles,
      config,
      flags,
      deployedContracts
    );
  }

  function testAaveV3FullBatchOrchestration() public {
    vm.startPrank(deployer);
    MarketReport memory market = AaveV3BatchOrchestration.deployAaveV3(
      deployer,
      roles,
      config,
      flags,
      deployedContracts
    );
    vm.stopPrank();
    checkFullReport(flags, market);
  }

  function test0AaveV3SetupDeployment() public {
    new AaveV3SetupBatch(msg.sender, roles, config, deployedContracts);
  }

  function test1AaveV3GettersDeployment() public {
    new AaveV3GettersBatchOne(
      marketReportOne.poolAddressesProvider,
      config.networkBaseTokenPriceInUsdProxyAggregator,
      config.marketReferenceCurrencyPriceInUsdProxyAggregator
    );

    new AaveV3GettersBatchTwo(
      setupReportTwo.poolProxy,
      roles.poolAdmin,
      config.wrappedNativeToken,
      flags.l2
    );
  }

  function test2AaveV3PoolDeployment() public {
    new AaveV3PoolBatch(marketReportOne.poolAddressesProvider);
  }

  function test2AaveV3L2PoolDeployment() public {
    new AaveV3L2PoolBatch(marketReportOne.poolAddressesProvider);
  }

  function test4PeripheralsRelease() public {
    new AaveV3PeripheryBatch(
      roles.poolAdmin,
      config,
      marketReportOne.poolAddressesProvider,
      address(aaveV3SetupOne)
    );
  }

  function test5PeripheralsRelease() public {
    new AaveV3ParaswapBatch(
      roles.poolAdmin,
      config,
      marketReportOne.poolAddressesProvider,
      peripheryReportOne.treasury
    );
  }

  function test6SetupMarket() public {
    vm.prank(roles.marketOwner);
    aaveV3SetupOne.setupAaveV3Market(
      roles,
      config,
      poolReportOne.poolImplementation,
      poolReportOne.poolConfiguratorImplementation,
      gettersReportOne.protocolDataProvider,
      peripheryReportOne.aaveOracle,
      peripheryReportOne.rewardsControllerImplementation
    );
  }

  function test7TokensMarket() public {
    new AaveV3TokensBatch(setupReportTwo.poolProxy);
  }
}
