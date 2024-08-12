// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {AToken} from '../../../src/core/contracts/protocol/tokenization/AToken.sol';
import {IERC20} from '../../../src/periphery/contracts/static-a-token/StaticATokenLM.sol';
import {BaseTest} from './TestBase.sol';

contract StataRewardsTest is BaseTest {
  function setUp() public override {
    super.setUp();

    _configureLM();

    vm.startPrank(user);
  }

  function test_claimableRewards() external {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);
    _depositAToken(amountToDeposit, user);

    vm.warp(block.timestamp + 200);
    uint256 claimable = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    assertEq(claimable, 200 * 0.00385 ether);
  }

  // test rewards
  function test_collectAndUpdateRewards() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    _skipBlocks(60);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(address(staticATokenLM)), 0);
    uint256 claimable = staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN);
    staticATokenLM.collectAndUpdateRewards(REWARD_TOKEN);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(address(staticATokenLM)), claimable);
  }

  function test_claimRewardsToSelf() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    _skipBlocks(60);

    uint256 claimable = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
  }

  function test_claimRewards() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    _skipBlocks(60);

    uint256 claimable = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    staticATokenLM.claimRewards(user, rewardTokens);
    assertEq(claimable, IERC20(REWARD_TOKEN).balanceOf(user));
    assertEq(IERC20(REWARD_TOKEN).balanceOf(address(staticATokenLM)), 0);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
  }

  // should fail as user1 is not a valid claimer
  function testFail_claimRewardsOnBehalfOf() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    _skipBlocks(60);

    vm.stopPrank();
    vm.startPrank(user1);

    staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    staticATokenLM.claimRewardsOnBehalf(user, user1, rewardTokens);
  }

  function test_depositATokenClaimWithdrawClaim() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    // deposit aweth
    _depositAToken(amountToDeposit, user);

    // forward time
    _skipBlocks(60);

    // claim
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), 0);
    uint256 claimable0 = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), claimable0);
    assertGt(claimable0, 0);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable0);

    // forward time
    _skipBlocks(60);

    // redeem
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user, user);
    uint256 claimable1 = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), claimable1);
    assertGt(claimable1, 0);

    // claim on behalf of other user
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable1 + claimable0);
    assertEq(staticATokenLM.balanceOf(user), 0);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), 0);
    assertGe(AToken(UNDERLYING).balanceOf(user), 5 ether);
  }

  function test_depositWETHClaimWithdrawClaim() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    // forward time
    _skipBlocks(60);

    // claim
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), 0);
    uint256 claimable0 = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), claimable0);
    assertGt(claimable0, 0);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable0);

    // forward time
    _skipBlocks(60);

    // redeem
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user, user);
    uint256 claimable1 = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), claimable1);
    assertGt(claimable1, 0);

    // claim on behalf of other user
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable1 + claimable0);
    assertEq(staticATokenLM.balanceOf(user), 0);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), 0);
    assertGe(AToken(UNDERLYING).balanceOf(user), 5 ether);
  }

  function test_transfer() public {
    uint128 amountToDeposit = 10 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    // transfer to 2nd user
    staticATokenLM.transfer(user1, amountToDeposit / 2);
    assertEq(staticATokenLM.getClaimableRewards(user1, REWARD_TOKEN), 0);

    // forward time
    _skipBlocks(60);

    // redeem for both
    uint256 claimableUser = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user, user);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimableUser);
    vm.stopPrank();
    vm.startPrank(user1);
    uint256 claimableUser1 = staticATokenLM.getClaimableRewards(user1, REWARD_TOKEN);
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user1), user1, user1);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user1), claimableUser1);
    assertGt(claimableUser1, 0);

    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), 0);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
    assertEq(staticATokenLM.getClaimableRewards(user1, REWARD_TOKEN), 0);
  }

  // getUnclaimedRewards
  function test_getUnclaimedRewards() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    uint256 shares = _depositAToken(amountToDeposit, user);
    assertEq(staticATokenLM.getUnclaimedRewards(user, REWARD_TOKEN), 0);
    _skipBlocks(1000);
    staticATokenLM.redeem(shares, user, user);
    assertGt(staticATokenLM.getUnclaimedRewards(user, REWARD_TOKEN), 0);
  }
}
