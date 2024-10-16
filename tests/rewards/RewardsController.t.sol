// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {MockAggregator} from '../../src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {RewardsController, RewardsDistributor} from '../../src/contracts/rewards/RewardsController.sol';
import {EmissionManager} from '../../src/contracts/rewards/EmissionManager.sol';
import {DataTypes} from '../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {IAToken, IERC20} from '../../src/contracts/protocol/tokenization/AToken.sol';
import {ITransferStrategyBase} from '../../src/contracts/rewards/interfaces/ITransferStrategyBase.sol';
import {AggregatorInterface} from '../../src/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {RewardsDataTypes} from '../../src/contracts/rewards/libraries/RewardsDataTypes.sol';
import {PullRewardsTransferStrategy} from '../../src/contracts/rewards/transfer-strategies/PullRewardsTransferStrategy.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract RewardsControllerTest is TestnetProcedures {
  event ClaimerSet(address indexed user, address indexed claimer);
  event RewardsClaimed(
    address indexed user,
    address indexed reward,
    address indexed to,
    address claimer,
    uint256 amount
  );
  event TransferStrategyInstalled(address indexed reward, address indexed transferStrategy);
  event RewardOracleUpdated(address indexed reward, address indexed rewardOracle);
  event AssetConfigUpdated(
    address indexed asset,
    address indexed reward,
    uint256 oldEmission,
    uint256 newEmission,
    uint256 oldDistributionEnd,
    uint256 newDistributionEnd,
    uint256 assetIndex
  );
  event Accrued(
    address indexed asset,
    address indexed reward,
    address indexed user,
    uint256 assetIndex,
    uint256 userIndex,
    uint256 rewardsAccrued
  );

  EmissionManager internal manager;
  RewardsController internal rewardsController;
  address internal usdxAToken;

  function setUp() public {
    initTestEnvironment();

    manager = EmissionManager(report.emissionManager);
    rewardsController = RewardsController(report.rewardsControllerProxy);

    vm.prank(poolAdmin);
    manager.setEmissionAdmin(tokenList.usdx, alice);

    usdxAToken = contracts.poolProxy.getReserveAToken(tokenList.usdx);
  }

  function test_new_RewardsController() public returns (RewardsController) {
    EmissionManager emissionManager = new EmissionManager(alice);
    RewardsController controller = new RewardsController(address(emissionManager));
    assertEq(controller.EMISSION_MANAGER(), address(emissionManager));
    assertEq(controller.getEmissionManager(), address(emissionManager));

    return controller;
  }

  function test_initialize_no_op() public {
    RewardsController controller = test_new_RewardsController();
    controller.initialize(address(0));
  }

  function test_reverts_initialize_twice() public {
    RewardsController controller = test_new_RewardsController();
    controller.initialize(address(0));

    vm.expectRevert();
    controller.initialize(address(0));
  }

  function test_setTransferStrategy_PullRewardsTransferStrategy() public {
    test_configureAssets();

    ITransferStrategyBase transferStrategy = ITransferStrategyBase(
      new PullRewardsTransferStrategy(report.rewardsControllerProxy, alice, carol)
    );

    vm.expectEmit(address(rewardsController));
    emit TransferStrategyInstalled(tokenList.usdx, address(transferStrategy));

    vm.prank(alice);
    manager.setTransferStrategy(tokenList.usdx, transferStrategy);

    assertEq(rewardsController.getTransferStrategy(tokenList.usdx), address(transferStrategy));
    assertEq(PullRewardsTransferStrategy(address(transferStrategy)).getRewardsVault(), carol);
  }

  function test_setRewardOracle() public {
    MockAggregator mock = new MockAggregator(2e6);
    test_configureAssets();

    vm.expectEmit(address(rewardsController));
    emit RewardOracleUpdated(tokenList.usdx, address(mock));

    vm.prank(alice);
    manager.setRewardOracle(tokenList.usdx, AggregatorInterface(address(mock)));

    assertEq(rewardsController.getRewardOracle(tokenList.usdx), address(mock));
  }

  function test_setDistributionEnd() public {
    test_configureAssets();

    (uint256 index, uint256 emissionPerSecond, , uint256 distributionEnd) = rewardsController
      .getRewardsData(usdxAToken, tokenList.usdx);

    vm.expectEmit(address(rewardsController));
    emit AssetConfigUpdated(
      usdxAToken,
      tokenList.usdx,
      emissionPerSecond,
      emissionPerSecond,
      distributionEnd,
      10,
      index
    );

    vm.prank(alice);
    manager.setDistributionEnd(usdxAToken, tokenList.usdx, 10);

    assertEq(rewardsController.getDistributionEnd(usdxAToken, tokenList.usdx), 10);
  }

  function test_setEmissionPerSecond() public {
    address[] memory rewards = new address[](1);
    uint88[] memory emissions = new uint88[](1);
    rewards[0] = tokenList.usdx;
    emissions[0] = 0.02e6;

    test_configureAssets();

    (uint256 index, uint256 emissionPerSecond, , uint256 distributionEnd) = rewardsController
      .getRewardsData(usdxAToken, tokenList.usdx);

    vm.expectEmit(address(rewardsController));
    emit AssetConfigUpdated(
      usdxAToken,
      tokenList.usdx,
      emissionPerSecond,
      emissions[0],
      distributionEnd,
      distributionEnd,
      index
    );

    vm.prank(alice);
    manager.setEmissionPerSecond(usdxAToken, rewards, emissions);
  }

  function test_configureAssets() public {
    PullRewardsTransferStrategy strat = new PullRewardsTransferStrategy(
      report.rewardsControllerProxy,
      alice,
      carol
    );

    vm.prank(carol);
    IERC20(tokenList.usdx).approve(address(strat), UINT256_MAX);

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

    vm.expectEmit(address(rewardsController));
    emit AssetConfigUpdated(
      usdxAToken,
      tokenList.usdx,
      0,
      config[0].emissionPerSecond,
      0,
      config[0].distributionEnd,
      0
    );

    vm.prank(alice);
    manager.configureAssets(config);

    assertEq((rewardsController.getRewardsList()).length, 1);
    assertEq((rewardsController.getRewardsList())[0], tokenList.usdx);
    assertEq((rewardsController.getRewardsByAsset(usdxAToken))[0], tokenList.usdx);
    assertEq((rewardsController.getRewardsByAsset(usdxAToken)).length, 1);
  }

  function test_setClaimer() public {
    vm.expectEmit(address(rewardsController));
    emit ClaimerSet(alice, bob);

    vm.prank(poolAdmin);
    manager.setClaimer(alice, bob);

    assertEq(rewardsController.getClaimer(alice), bob);
  }

  function test_claimRewards() public {
    test_configureAssets();
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    vm.warp(block.timestamp + 1 days);
    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;
    uint256 totalRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);
    assertGt(totalRewards, 0);

    uint256 aliceBalance = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(rewardsController));
    emit RewardsClaimed(alice, tokenList.usdx, alice, alice, totalRewards);

    vm.prank(alice);
    rewardsController.claimRewards(assets, totalRewards, alice, tokenList.usdx);
    assertEq(IERC20(tokenList.usdx).balanceOf(alice), aliceBalance + totalRewards);
  }

  function test_claimRewards_partial() public {
    test_configureAssets();
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    vm.warp(block.timestamp + 1 days);
    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;
    uint256 totalRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);
    assertGt(totalRewards, 0);

    uint256 claimAmount = totalRewards / 3;

    uint256 aliceBalance = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(rewardsController));
    emit RewardsClaimed(alice, tokenList.usdx, alice, alice, claimAmount);

    vm.prank(alice);
    rewardsController.claimRewards(assets, claimAmount, alice, tokenList.usdx);
    assertEq(IERC20(tokenList.usdx).balanceOf(alice), aliceBalance + claimAmount);
  }

  function test_claimRewards_zero() public {
    test_configureAssets();

    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;
    uint256 totalRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);
    assertEq(totalRewards, 0);

    uint256 aliceBalance = IERC20(tokenList.usdx).balanceOf(alice);

    vm.prank(alice);
    rewardsController.claimRewards(assets, 0, alice, tokenList.usdx);
    assertEq(IERC20(tokenList.usdx).balanceOf(alice), aliceBalance);
  }

  function test_claimRewards_zero_with_rewards() public {
    test_configureAssets();

    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;
    uint256 totalRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);
    assertEq(totalRewards, 0);

    uint256 aliceBalance = IERC20(tokenList.usdx).balanceOf(alice);

    vm.prank(alice);
    rewardsController.claimRewards(assets, 1, alice, tokenList.usdx);
    assertEq(IERC20(tokenList.usdx).balanceOf(alice), aliceBalance);
  }

  function test_claimRewardsToSelf() public {
    test_configureAssets();
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    vm.warp(block.timestamp + 1 days);
    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;
    uint256 totalRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);
    assertGt(totalRewards, 0);

    uint256 aliceBalance = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(rewardsController));
    emit RewardsClaimed(alice, tokenList.usdx, alice, alice, totalRewards);

    vm.prank(alice);
    rewardsController.claimRewardsToSelf(assets, totalRewards, tokenList.usdx);
    assertEq(IERC20(tokenList.usdx).balanceOf(alice), aliceBalance + totalRewards);
  }

  function test_claimAllRewards() public {
    test_configureAssets();
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    vm.warp(block.timestamp + 1 days);
    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;
    uint256 totalRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);
    assertGt(totalRewards, 0);

    uint256 aliceBalance = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(rewardsController));
    emit RewardsClaimed(alice, tokenList.usdx, alice, alice, totalRewards);

    vm.prank(alice);
    rewardsController.claimAllRewards(assets, alice);
    assertEq(IERC20(tokenList.usdx).balanceOf(alice), aliceBalance + totalRewards);
  }

  function test_claimAllRewardsToSelf() public {
    test_configureAssets();
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    vm.warp(block.timestamp + 1 days);
    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;
    uint256 totalRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);
    assertGt(totalRewards, 0);

    uint256 aliceBalance = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(rewardsController));
    emit RewardsClaimed(alice, tokenList.usdx, alice, alice, totalRewards);

    vm.prank(alice);
    rewardsController.claimAllRewardsToSelf(assets);
    assertEq(IERC20(tokenList.usdx).balanceOf(alice), aliceBalance + totalRewards);
  }

  function test_claimAllRewardsOnBehalf() public {
    vm.prank(poolAdmin);
    manager.setClaimer(alice, bob);

    test_configureAssets();
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    vm.warp(block.timestamp + 1 days);
    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;
    uint256 totalRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);
    assertGt(totalRewards, 0);

    uint256 aliceBalance = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(rewardsController));
    emit RewardsClaimed(alice, tokenList.usdx, alice, bob, totalRewards);

    vm.prank(bob);
    rewardsController.claimAllRewardsOnBehalf(assets, alice, alice);
    assertEq(IERC20(tokenList.usdx).balanceOf(alice), aliceBalance + totalRewards);
  }

  function test_claimRewardsOnBehalf() public {
    test_configureAssets();
    test_setClaimer();

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    vm.warp(block.timestamp + 1 days);
    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;
    uint256 totalRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);
    assertGt(totalRewards, 0);

    uint256 aliceBalance = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(rewardsController));
    emit RewardsClaimed(alice, tokenList.usdx, alice, bob, totalRewards);

    vm.prank(bob);
    rewardsController.claimRewardsOnBehalf(assets, totalRewards, alice, alice, tokenList.usdx);
    assertEq(IERC20(tokenList.usdx).balanceOf(alice), aliceBalance + totalRewards);
  }

  function test_accrueRewards() public {
    test_configureAssets();
    address[] memory assets = new address[](1);
    assets[0] = usdxAToken;

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    vm.warp(block.timestamp + 1 days);

    (uint256 newAssetIndex, uint256 expectedRewardsAccrued) = _calculateRewardsAccrued(
      usdxAToken,
      tokenList.usdx,
      alice
    );

    (, uint256[] memory unclaimedRewards) = rewardsController.getAllUserRewards(assets, alice);
    uint256 userUnclaimedRewards = rewardsController.getUserRewards(assets, alice, tokenList.usdx);

    vm.expectEmit(address(rewardsController));
    emit Accrued(
      usdxAToken,
      tokenList.usdx,
      alice,
      newAssetIndex,
      newAssetIndex,
      expectedRewardsAccrued
    );

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);

    uint256 accrued = rewardsController.getUserAccruedRewards(alice, tokenList.usdx);
    assertEq(accrued, expectedRewardsAccrued);
    assertEq(accrued, unclaimedRewards[0]);
    assertEq(accrued, userUnclaimedRewards);
  }

  struct RewardsData {
    uint256 index;
    uint256 emissionPerSecond;
    uint256 lastUpdateTimestamp;
    uint256 distributionEnd;
  }

  function _calculateRewardsAccrued(
    address asset,
    address reward,
    address user
  ) internal view returns (uint256 index, uint256 rewards) {
    uint256 userIndex = rewardsController.getUserAssetIndex(user, asset, reward);
    RewardsData memory rewardData;
    (
      rewardData.index,
      rewardData.emissionPerSecond,
      rewardData.lastUpdateTimestamp,
      rewardData.distributionEnd
    ) = rewardsController.getRewardsData(asset, reward);

    (, uint256 newAssetIndex) = _getAssetIndex(
      rewardData,
      IAToken(asset).scaledTotalSupply(),
      10 ** rewardsController.getAssetDecimals(asset)
    );

    (, uint256 expectedAssetIndex) = rewardsController.getAssetIndex(asset, reward);
    assertEq(newAssetIndex, expectedAssetIndex);

    return (
      newAssetIndex,
      _getRewards(
        IAToken(asset).scaledBalanceOf(user),
        newAssetIndex,
        userIndex,
        10 ** rewardsController.getAssetDecimals(asset)
      )
    );
  }

  function _getAssetIndex(
    RewardsData memory rewardData,
    uint256 totalSupply,
    uint256 assetUnit
  ) internal view returns (uint256, uint256) {
    uint256 oldIndex = rewardData.index;
    uint256 distributionEnd = rewardData.distributionEnd;
    uint256 emissionPerSecond = rewardData.emissionPerSecond;
    uint256 lastUpdateTimestamp = rewardData.lastUpdateTimestamp;

    if (
      emissionPerSecond == 0 ||
      totalSupply == 0 ||
      lastUpdateTimestamp == block.timestamp ||
      lastUpdateTimestamp >= distributionEnd
    ) {
      return (oldIndex, oldIndex);
    }

    uint256 currentTimestamp = block.timestamp > distributionEnd
      ? distributionEnd
      : block.timestamp;
    uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;
    uint256 firstTerm = emissionPerSecond * timeDelta * assetUnit;
    assembly {
      firstTerm := div(firstTerm, totalSupply)
    }
    return (oldIndex, (firstTerm + oldIndex));
  }

  function _getRewards(
    uint256 userBalance,
    uint256 reserveIndex,
    uint256 userIndex,
    uint256 assetUnit
  ) internal pure returns (uint256) {
    uint256 result = userBalance * (reserveIndex - userIndex);
    assembly {
      result := div(result, assetUnit)
    }
    return result;
  }
}
