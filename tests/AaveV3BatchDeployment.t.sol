// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import '../src/deployments/interfaces/IMarketReportTypes.sol';

import {AugustusRegistryMock} from './mocks/AugustusRegistryMock.sol';
import {MockParaSwapFeeClaimer} from 'aave-v3-periphery/contracts/mocks/swap/MockParaSwapFeeClaimer.sol';
import {BatchTestProcedures} from './utils/BatchTestProcedures.sol';
import {AaveV3TestListing} from './mocks/AaveV3TestListing.sol';
import {ACLManager} from 'aave-v3-core/contracts/protocol/configuration/ACLManager.sol';
import {WETH9} from 'aave-v3-core/contracts/dependencies/weth/WETH9.sol';
import {IPoolAddressesProvider} from 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IAaveV3ConfigEngine} from 'aave-v3-periphery/contracts/v3-config-engine/IAaveV3ConfigEngine.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {AaveV3ConfigEngine} from 'aave-v3-periphery/contracts/v3-config-engine/AaveV3ConfigEngine.sol';
import {SequencerOracle} from 'aave-v3-core/contracts/mocks/oracle/SequencerOracle.sol';

contract AaveV3BatchDeployment is BatchTestProcedures {
  address public marketOwner;
  address public emergencyAdmin;

  Roles public roles;
  DeployFlags public flags;
  MarketConfig config;
  MarketReport deployedContracts;

  address public weth9;

  function setUp() public {
    bytes32 emptySalt;
    weth9 = address(new WETH9());
    marketOwner = makeAddr('marketOwner');
    poolAdmin = makeAddr('poolAdmin');
    emergencyAdmin = makeAddr('emergencyAdmin');

    roles = Roles(marketOwner, poolAdmin, emergencyAdmin);
    config = MarketConfig(
      makeAddr('ethUsdOracle'),
      makeAddr('ethUsdOracle'),
      'Testnet Market',
      8,
      address(new AugustusRegistryMock()),
      address(new MockParaSwapFeeClaimer()),
      address(0), // l2SequencerUptimeFeed
      0, // l2PriceOracleSentinelGracePeriod
      8080,
      emptySalt,
      weth9,
      address(0),
      0.0005e4,
      0.0004e4
    );
  }

  function testAaveV3BatchDeploymentCheck() public {
    MarketReport memory fullReport = deployAaveV3Testnet(
      marketOwner,
      roles,
      config,
      flags,
      deployedContracts
    );
    checkFullReport(flags, fullReport);

    AaveV3TestListing testnetListingPayload = new AaveV3TestListing(
      IAaveV3ConfigEngine(fullReport.configEngine),
      marketOwner,
      weth9,
      fullReport
    );

    ACLManager manager = ACLManager(fullReport.aclManager);

    vm.prank(poolAdmin);
    manager.addPoolAdmin(address(testnetListingPayload));

    testnetListingPayload.execute();
  }

  function testAaveV3L2BatchDeploymentCheck() public {
    flags.l2 = true;
    config.l2SequencerUptimeFeed = address(new SequencerOracle(poolAdmin));
    config.l2PriceOracleSentinelGracePeriod = 2 hours;

    MarketReport memory fullReport = deployAaveV3Testnet(
      marketOwner,
      roles,
      config,
      flags,
      deployedContracts
    );

    checkFullReport(flags, fullReport);

    AaveV3TestListing testnetListingPayload = new AaveV3TestListing(
      IAaveV3ConfigEngine(fullReport.configEngine),
      marketOwner,
      weth9,
      fullReport
    );

    ACLManager manager = ACLManager(fullReport.aclManager);

    vm.prank(poolAdmin);
    manager.addPoolAdmin(address(testnetListingPayload));

    testnetListingPayload.execute();
  }

  function testAaveV3BatchDeploy() public {
    checkFullReport(
      flags,
      deployAaveV3Testnet(marketOwner, roles, config, flags, deployedContracts)
    );
  }
}
