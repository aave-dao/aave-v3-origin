// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {MockAggregator} from '../../src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {RewardsController} from '../../src/contracts/rewards/RewardsController.sol';
import {EmissionManager} from '../../src/contracts/rewards/EmissionManager.sol';
import {DataTypes} from '../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {ITransferStrategyBase} from '../../src/contracts/rewards/interfaces/ITransferStrategyBase.sol';
import {AggregatorInterface} from '../../src/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {RewardsDataTypes} from '../../src/contracts/rewards/libraries/RewardsDataTypes.sol';
import {PullRewardsTransferStrategy} from '../../src/contracts/rewards/transfer-strategies/PullRewardsTransferStrategy.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract EmissionManagerTest is TestnetProcedures {
  EmissionManager internal manager;
  RewardsController internal rewardsController;
  address internal usdxAToken;

  function setUp() public {
    initTestEnvironment();

    manager = EmissionManager(report.emissionManager);
    rewardsController = RewardsController(report.rewardsControllerProxy);

    usdxAToken = contracts.poolProxy.getReserveAToken(tokenList.usdx);
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
    manager.setRewardOracle(tokenList.usdx, AggregatorInterface(address(mock)));
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
      AggregatorInterface(address(2))
    );

    vm.prank(alice);
    manager.configureAssets(config);
  }

  function test_setClaimer() public {
    vm.prank(poolAdmin);
    manager.setClaimer(bob, alice);
  }
}
