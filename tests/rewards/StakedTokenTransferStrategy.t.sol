// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {StakedTokenTransferStrategy, IERC20, IStakedToken} from '../../src/contracts/rewards/transfer-strategies/StakedTokenTransferStrategy.sol';
import {StakeMock} from '../mocks/StakeMock.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract StakedTokenTransferStrategyTest is TestnetProcedures {
  event EmergencyWithdrawal(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  StakeMock internal stakeMock;
  StakedTokenTransferStrategy internal stakedTokenTransferStrategy;

  event TestCheck(address a, uint256 b);
  event TestApproval(address spender, uint256 amount);

  function setUp() public {
    initTestEnvironment(false);
    stakeMock = new StakeMock();
    stakedTokenTransferStrategy = new StakedTokenTransferStrategy(
      report.rewardsControllerProxy,
      alice,
      IStakedToken(address(stakeMock))
    );
  }

  function test_performTransfer() public {
    vm.expectEmit(address(stakeMock));
    emit TestCheck(alice, 10);

    vm.prank(report.rewardsControllerProxy);
    assertTrue(stakedTokenTransferStrategy.performTransfer(alice, address(stakeMock), 10));
  }

  function test_renewApproval() public {
    vm.expectEmit(address(stakeMock));
    emit TestApproval(address(stakeMock), 0);
    vm.expectEmit(address(stakeMock));
    emit TestApproval(address(stakeMock), UINT256_MAX);

    vm.prank(alice);
    stakedTokenTransferStrategy.renewApproval();
  }

  function test_dropApproval() public {
    vm.expectEmit(address(stakeMock));
    emit TestApproval(address(stakeMock), 0);

    vm.prank(alice);
    stakedTokenTransferStrategy.dropApproval();
  }

  function test_getters() public view {
    assertEq(stakedTokenTransferStrategy.getStakeContract(), address(stakeMock));
    assertEq(stakedTokenTransferStrategy.getUnderlyingToken(), address(stakeMock));
    assertEq(
      stakedTokenTransferStrategy.getIncentivesController(),
      address(report.rewardsControllerProxy)
    );
    assertEq(stakedTokenTransferStrategy.getRewardsAdmin(), address(alice));
  }

  function test_emergencyTransfer() public {
    deal(tokenList.usdx, address(stakedTokenTransferStrategy), 100e6);
    uint256 bobBalance = IERC20(tokenList.usdx).balanceOf(bob);

    vm.expectEmit();
    emit EmergencyWithdrawal(alice, tokenList.usdx, bob, 100e6);

    vm.prank(alice);
    stakedTokenTransferStrategy.emergencyWithdrawal(tokenList.usdx, bob, 100e6);

    assertEq(IERC20(tokenList.usdx).balanceOf(bob), bobBalance + 100e6);
  }
}
