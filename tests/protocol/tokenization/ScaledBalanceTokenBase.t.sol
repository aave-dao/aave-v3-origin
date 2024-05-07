// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {MockScaledToken} from '../../../src/contracts/mocks/tokens/MockScaledToken.sol';
import '../../utils/TestnetProcedures.sol';

contract ScaledBalanceTokenBaseEdgeTests is TestnetProcedures {
  using WadRayMath for uint256;

  MockScaledToken internal mockScaledToken;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  function setUp() public {
    initTestEnvironment(false);

    mockScaledToken = new MockScaledToken(IPool(report.poolProxy));
  }

  function test_scaled_balance_token_base_alice_transfer_to_bob_accrues_interests() public {
    uint256 transferAmount = 120e6;
    uint256 aliceScaledBalanceBefore = 140e6;
    uint256 bobScaledBalanceBefore = 30e6;

    uint256 previousIndex = 1e27;
    uint256 expectedIndex = 1.0001e27;
    uint256 expectedScaledTransferAmount = transferAmount.rayDiv(expectedIndex);

    mockScaledToken.setStorage(
      alice,
      bob,
      previousIndex,
      aliceScaledBalanceBefore,
      bobScaledBalanceBefore
    );

    uint256 senderBalanceIncrease = aliceScaledBalanceBefore.rayMul(expectedIndex) -
      aliceScaledBalanceBefore.rayMul(previousIndex);
    uint256 recipientBalanceIncrease = bobScaledBalanceBefore.rayMul(expectedIndex) -
      bobScaledBalanceBefore.rayMul(previousIndex);

    vm.expectEmit(address(mockScaledToken));
    emit Transfer(address(0), alice, senderBalanceIncrease);
    vm.expectEmit(address(mockScaledToken));
    emit Mint(alice, alice, senderBalanceIncrease, senderBalanceIncrease, expectedIndex);
    vm.expectEmit(address(mockScaledToken));
    emit Transfer(address(0), bob, recipientBalanceIncrease);
    vm.expectEmit(address(mockScaledToken));
    emit Mint(alice, bob, recipientBalanceIncrease, recipientBalanceIncrease, expectedIndex);
    vm.expectEmit(address(mockScaledToken));
    emit Transfer(alice, bob, transferAmount);

    vm.prank(alice);
    mockScaledToken.transferWithIndex(alice, bob, transferAmount, expectedIndex);

    assertEq(
      mockScaledToken.balanceOf(bob),
      bobScaledBalanceBefore + expectedScaledTransferAmount,
      'bob scaled balance should accrue scaled transfer amount'
    );

    assertEq(
      mockScaledToken.balanceOf(alice),
      aliceScaledBalanceBefore - expectedScaledTransferAmount,
      'alice scaled balance should be minus scaled transfer amount'
    );
    assertEq(
      getBalanceOf(mockScaledToken.balanceOf(alice), expectedIndex),
      aliceScaledBalanceBefore - transferAmount + senderBalanceIncrease,
      'alice atoken balance'
    );
    assertEq(
      getBalanceOf(mockScaledToken.balanceOf(bob), expectedIndex),
      bobScaledBalanceBefore + transferAmount + recipientBalanceIncrease,
      'bob atoken balance'
    );
  }

  function getBalanceOf(uint256 scaledBalance, uint256 index) internal pure returns (uint256) {
    return scaledBalance.rayMul(index);
  }
}
