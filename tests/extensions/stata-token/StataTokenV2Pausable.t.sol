// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol';
import {IERC20Metadata, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IERC4626StataToken} from '../../../src/contracts/extensions/stata-token/interfaces/IERC4626StataToken.sol';
import {BaseTest} from './TestBase.sol';

contract StataTokenV2PausableTest is BaseTest {
  function test_canPause() external view {
    assertEq(stataTokenV2.canPause(poolAdmin), true);
  }

  function test_canPause_shouldReturnFalse(address actor) external view {
    vm.assume(actor != poolAdmin);
    assertEq(stataTokenV2.canPause(actor), false);
  }

  function test_setPaused_shouldRevertForInvalidCaller(address actor) external {
    vm.assume(actor != poolAdmin && actor != proxyAdmin);
    vm.expectRevert(abi.encodeWithSelector(IERC4626StataToken.OnlyPauseGuardian.selector, actor));
    _setPaused(actor, true);
  }

  function test_setPaused_shouldSucceedForOwner() external {
    assertEq(PausableUpgradeable(address(stataTokenV2)).paused(), false);
    _setPaused(poolAdmin, true);
    assertEq(PausableUpgradeable(address(stataTokenV2)).paused(), true);
  }

  function test_deposit_shouldRevert() external {
    uint128 amountToDeposit = 5 ether;
    _fundUnderlying(amountToDeposit, user);
    vm.prank(user);
    IERC20(underlying).approve(address(stataTokenV2), amountToDeposit);

    _setPausedAsAclAdmin(true);
    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    vm.prank(user);
    stataTokenV2.deposit(amountToDeposit, user);
  }

  function test_mint_shouldRevert() external {
    uint128 amountToDeposit = 5 ether;
    _fundUnderlying(amountToDeposit, user);
    vm.prank(user);
    IERC20(underlying).approve(address(stataTokenV2), amountToDeposit);

    uint256 sharesToMint = stataTokenV2.previewDeposit(amountToDeposit);
    _setPausedAsAclAdmin(true);
    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    vm.prank(user);
    stataTokenV2.mint(sharesToMint, user);
  }

  function test_redeem_shouldRevert() external {
    uint128 amountToDeposit = 5 ether;
    _fund4626(amountToDeposit, user);

    assertEq(stataTokenV2.maxRedeem(user), stataTokenV2.balanceOf(user));

    _setPausedAsAclAdmin(true);
    uint256 maxRedeem = stataTokenV2.maxRedeem(user);
    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    vm.prank(user);
    stataTokenV2.redeem(maxRedeem, user, user);
  }

  function test_withdraw_shouldRevert() external {
    uint128 amountToDeposit = 5 ether;
    _fund4626(amountToDeposit, user);

    uint256 maxWithdraw = stataTokenV2.maxWithdraw(user);
    _setPausedAsAclAdmin(true);
    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    vm.prank(user);
    stataTokenV2.withdraw(maxWithdraw, user, user);
  }

  function test_transfer_shouldRevert() external {
    uint128 amountToDeposit = 10 ether;
    _fund4626(amountToDeposit, user);

    _setPausedAsAclAdmin(true);
    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    vm.prank(user);
    stataTokenV2.transfer(user1, amountToDeposit);
  }

  function test_claimingRewards_shouldRevert() external {
    uint128 amountToDeposit = 10 ether;
    _fund4626(amountToDeposit, user);

    _setPausedAsAclAdmin(true);
    vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
    vm.prank(user);
    stataTokenV2.claimRewardsToSelf(rewardTokens);
  }

  function _setPausedAsAclAdmin(bool paused) internal {
    _setPaused(poolAdmin, paused);
  }

  function _setPaused(address actor, bool paused) internal {
    vm.prank(actor);
    stataTokenV2.setPaused(paused);
  }
}
