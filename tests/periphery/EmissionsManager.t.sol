// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {MockAggregator} from 'aave-v3-core/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {RewardsController} from 'aave-v3-periphery/contracts/rewards/RewardsController.sol';
import {EmissionManager} from 'aave-v3-periphery/contracts/rewards/EmissionManager.sol';
import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {ITransferStrategyBase} from 'aave-v3-periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol';
import {IEACAggregatorProxy} from 'aave-v3-periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol';
import {RewardsDataTypes} from 'aave-v3-periphery/contracts/rewards/libraries/RewardsDataTypes.sol';
import {PullRewardsTransferStrategy} from 'aave-v3-periphery/contracts/rewards/transfer-strategies/PullRewardsTransferStrategy.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract EmissionManagerTest is TestnetProcedures {
  EmissionManager internal manager;
  RewardsController internal rewardsController;
  address internal usdxAToken;

  function setUp() public {
    initTestEnvironment();

    manager = EmissionManager(report.emissionManager);
    rewardsController = RewardsController(report.rewardsControllerProxy);

    DataTypes.ReserveDataLegacy memory reserveData = IPool(report.poolProxy).getReserveData(
      tokenList.usdx
    );

    usdxAToken = reserveData.aTokenAddress;
  }

  function test_new_EmissionManager() public {
    EmissionManager emissionManager = new EmissionManager(alice);
    assertEq(address(emissionManager.getRewardsController()), address(0));
  }

  function test_setEmissionAdmin() public {
    vm.prank(poolAdmin);
    manager.setEmissionAdmin(tokenList.usdx, alice);
    assertEq(manager.getEmissionAdmin(tokenList.usdx), alice);
  }

  function test_setRewardsController() public {
    vm.prank(poolAdmin);
    manager.setRewardsController(address(1));
    assertEq(address(manager.getRewardsController()), address(1));
  }

  function test_setTransferStrategy() public {
    test_configureAssets();

    vm.startPrank(alice);
    manager.setTransferStrategy(
      tokenList.usdx,
      ITransferStrategyBase(
        new PullRewardsTransferStrategy(report.rewardsControllerProxy, alice, carol)
      )
    );
    vm.stopPrank();
  }

  function test_setRewardOracle() public {
    MockAggregator mock = new MockAggregator(2e6);
    test_configureAssets();
    vm.prank(alice);
    manager.setRewardOracle(tokenList.usdx, IEACAggregatorProxy(address(mock)));
  }

  function test_setDistributionEnd() public {
    test_configureAssets();
    vm.prank(alice);
    manager.setDistributionEnd(usdxAToken, tokenList.usdx, 10);
  }

  function test_setEmissionPerSecond() public {
    address[] memory rewards = new address[](1);
    uint88[] memory emissions = new uint88[](1);
    rewards[0] = tokenList.usdx;
    emissions[0] = 0.02e6;

    test_configureAssets();

    vm.prank(alice);
    manager.setEmissionPerSecond(usdxAToken, rewards, emissions);
  }

  function test_configureAssets() public {
    PullRewardsTransferStrategy strat = new PullRewardsTransferStrategy(
      report.rewardsControllerProxy,
      alice,
      carol
    );

    test_setEmissionAdmin();
    RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](
      1
    );
    config[0] = RewardsDataTypes.RewardsConfigInput(
      0.05e6,
      0,
      uint32(block.timestamp + 30 days),
      usdxAToken,
      tokenList.usdx,
      ITransferStrategyBase(strat),
      IEACAggregatorProxy(address(2))
    );

    vm.prank(alice);
    manager.configureAssets(config);
  }

  function test_setClaimer() public {
    vm.prank(poolAdmin);
    manager.setClaimer(bob, alice);
  }
}
