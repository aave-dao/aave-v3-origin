// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {IScaledBalanceToken} from '../../../src/contracts/interfaces/IScaledBalanceToken.sol';
import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {SupplyLogic} from '../../../src/contracts/protocol/libraries/logic/SupplyLogic.sol';
import {MathUtils} from '../../../src/contracts/protocol/libraries/math/MathUtils.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {MockAToken} from '../../../src/contracts/mocks/tokens/MockAToken.sol';

contract ATokenTransferTests is TestnetProcedures {
  using WadRayMath for uint256;
  IAToken public aToken;
  IVariableDebtToken public variableDebtToken;
  MockAToken public mockAToken;

  function setUp() public {
    initTestEnvironment(false);

    mockAToken = new MockAToken(
      IPool(report.poolProxy),
      report.rewardsControllerProxy,
      report.treasury
    );
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    address variableDebtWBTC = contracts.poolProxy.getReserveVariableDebtToken(tokenList.wbtc);
    aToken = IAToken(aUSDX);
    variableDebtToken = IVariableDebtToken(variableDebtWBTC);

    // Perform setup of user positions
    uint256 mintAmount = 100_000e6;
    vm.startPrank(poolAdmin);

    usdx.mint(alice, mintAmount);
    usdx.mint(carol, mintAmount);
    wbtc.mint(carol, 10e8);

    vm.stopPrank();

    vm.prank(alice);
    usdx.approve(report.poolProxy, UINT256_MAX);
    vm.prank(carol);
    usdx.approve(report.poolProxy, UINT256_MAX);

    vm.prank(carol);
    wbtc.approve(report.poolProxy, UINT256_MAX);

    // Carol seeds WBTC liquidity
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.wbtc, 10e8, carol, 0);

    // Carol seeds USDX liq
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, mintAmount, carol, 0);

    // Alice supplies USDX
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, mintAmount, alice, 0);
  }

  function test_atoken_alice_transfer_to_herself() public {
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, alice, 120e6);

    vm.prank(alice);
    aToken.transfer(alice, 120e6);
  }

  function test_atoken_alice_transfer_to_herself_zero() public {
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, alice, 0);

    vm.prank(alice);
    aToken.transfer(alice, 0);
  }

  function test_atoken_alice_transfer_to_bob() public {
    uint256 transferAmount = 120e6;
    uint256 aliceBalanceBefore = aToken.balanceOf(alice);
    uint256 bobBalanceBefore = aToken.balanceOf(bob);
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, bob, transferAmount);
    vm.expectEmit(report.poolProxy);
    emit IPool.ReserveUsedAsCollateralEnabled(tokenList.usdx, bob);

    vm.prank(alice);
    aToken.transfer(bob, transferAmount);

    (uint256 bobCollateralBalance, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, bob);
    (uint256 aliceCollateralBalance, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, alice);
    assertEq(
      bobCollateralBalance,
      transferAmount,
      'Bob balance should be equal alice transfer to bob'
    );
    assertEq(aliceCollateralBalance, aliceBalanceBefore - transferAmount);
    assertEq(aToken.balanceOf(bob), bobBalanceBefore + transferAmount);
    assertEq(aToken.balanceOf(alice), aliceBalanceBefore - transferAmount);
  }

  function test_atoken_alice_transfer_all_to_bob() public {
    uint256 transferAmount = aToken.balanceOf(alice);
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, bob, transferAmount);

    vm.expectEmit(address(aToken));
    emit IAToken.BalanceTransfer(alice, bob, transferAmount, 1e27);
    vm.expectEmit(report.poolProxy);
    emit IPool.ReserveUsedAsCollateralDisabled(tokenList.usdx, alice);
    vm.expectEmit(report.poolProxy);
    emit IPool.ReserveUsedAsCollateralEnabled(tokenList.usdx, bob);

    vm.prank(alice);
    aToken.transfer(bob, transferAmount);

    assertEq(
      aToken.balanceOf(bob),
      transferAmount,
      'Bob balance should be equal alice transfer to bob'
    );

    assertEq(aToken.balanceOf(alice), 0);
  }

  function test_atoken_alice_transfer_to_bob_zero() public {
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, bob, 0);

    vm.prank(alice);
    aToken.transfer(bob, 0);

    (uint256 bobCollateralBalance, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, bob);
    assertEq(bobCollateralBalance, 0, 'Bob collateral balance should still be zero');
  }

  function test_atoken_multiple_transfers() public {
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, bob, 10_000e6);

    vm.prank(alice);
    aToken.transfer(bob, 10_000e6);

    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(bob, alice, 444e6);

    vm.prank(bob);
    aToken.transfer(alice, 444e6);

    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(bob, carol, 555e6);

    vm.prank(bob);
    aToken.transfer(carol, 555e6);
  }

  function test_atoken_transfer_to_bob_them_bob_borrows() public {
    uint256 transferAmount = 50_000e6;
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, bob, transferAmount);

    vm.prank(alice);
    aToken.transfer(bob, transferAmount);

    (uint256 bobCollateralBalance, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, bob);
    assertEq(
      bobCollateralBalance,
      transferAmount,
      'Bob balance should be equal alice transfer to bob'
    );

    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.5e8, 2, 0, bob);
  }

  function test_reverts_atoken_transfer_all_collateral_from_bob_borrower_to_alice() public {
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, bob, 50_000e6);

    vm.prank(alice);
    aToken.transfer(bob, 50_000e6);

    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.wbtc, 1e8, 2, 0, bob);

    uint256 transferAmount = aToken.balanceOf(bob);

    vm.expectRevert(
      abi.encodeWithSelector(Errors.HealthFactorLowerThanLiquidationThreshold.selector)
    );
    vm.prank(bob);
    aToken.transfer(alice, transferAmount);
  }

  function test_atoken_transfer_some_collateral_from_bob_borrower_to_alice() public {
    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, bob, 50_000e6);

    vm.prank(alice);
    aToken.transfer(bob, 50_000e6);

    (uint256 bobCollateralBalance, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, bob);
    assertEq(bobCollateralBalance, 50_000e6, 'Bob balance should be the transfer amount');

    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.wbtc, 1e8, 2, 0, bob);
    (, , uint256 borrowBalance, , , , , , ) = contracts.protocolDataProvider.getUserReserveData(
      tokenList.wbtc,
      bob
    );
    assertEq(borrowBalance, 1e8, 'borrowBalance should match borrowed amount');

    uint256 transferAmount = aToken.balanceOf(bob) / 4;

    (uint256 carolCollateralBalanceBefore, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, carol);

    vm.prank(bob);
    aToken.transfer(carol, transferAmount);

    (uint256 carolCollateralBalance, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, carol);

    assertEq(
      carolCollateralBalance,
      carolCollateralBalanceBefore + transferAmount,
      'transfer amount should match carol balance'
    );
  }

  function test_atoken_alice_transfer_to_carol_accrues_interests() public {
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    uint256 transferAmount = 120e6;
    uint256 aliceBalanceBefore = aToken.balanceOf(alice);
    uint256 carolBalanceBefore = aToken.balanceOf(carol);
    uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
      reserveData.currentLiquidityRate,
      reserveData.lastUpdateTimestamp
    );
    uint256 expectedIndex = cumulatedLiquidityInterest.rayMul(reserveData.liquidityIndex);

    uint256 recipientBalanceIncrease = aToken.scaledBalanceOf(carol).rayMul(expectedIndex) -
      aToken.scaledBalanceOf(carol).rayMul(aToken.getPreviousIndex(carol));
    (uint256 carolCollateralBalanceBefore, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, carol);

    vm.expectEmit(address(aToken));
    emit IERC20.Transfer(alice, carol, transferAmount);

    vm.prank(alice);
    aToken.transfer(carol, transferAmount);

    (uint256 carolCollateralBalance, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, carol);
    (uint256 aliceCollateralBalance, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, alice);
    assertEq(
      carolCollateralBalance,
      carolCollateralBalanceBefore + transferAmount,
      'carol balance should be equal alice transfer to bob'
    );
    assertEq(aliceCollateralBalance, aliceBalanceBefore - transferAmount);
    assertEq(
      aToken.balanceOf(carol),
      carolBalanceBefore + transferAmount + recipientBalanceIncrease
    );
    assertEq(aToken.balanceOf(alice), aliceBalanceBefore - transferAmount);
  }

  function test_atoken_transfer_sets_enabled_as_collateral(
    uint256 timePassed,
    uint256 amount
  ) public {
    uint256 aliceBalance = IERC20(aToken).balanceOf(alice);
    amount = bound(amount, 1, aliceBalance);
    timePassed = uint56(bound(timePassed, 1, (365 days) * 50));
    address mockReceiver = vm.addr(42);

    // borrow all available usdx
    vm.prank(carol);
    contracts.poolProxy.borrow(tokenList.usdx, 200_000e6, 2, 0, carol);

    // wait to inflate the index
    vm.warp(vm.getBlockTimestamp() + timePassed);
    // transfer the usdx
    vm.prank(alice);
    aToken.transfer(mockReceiver, amount);

    // check flag correctness
    (uint256 collateralBalance, , , , , , , , bool collateralEnabled) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, mockReceiver);
    if (collateralBalance == 0) {
      assertEq(collateralEnabled, false);
    } else {
      assertEq(collateralEnabled, true);
    }
  }

  function test_scaled_balance_token_base_alice_transfer_to_bob_accrues_interests() public {
    uint256 transferAmount = 120e6;
    uint256 aliceScaledBalanceBefore = 140e6;
    uint256 bobScaledBalanceBefore = 30e6;

    uint256 previousIndex = 1e27;
    uint256 expectedIndex = 1.0001e27;
    uint256 expectedScaledTransferAmount = transferAmount.rayDivCeil(expectedIndex);

    mockAToken.setStorage(
      alice,
      bob,
      previousIndex,
      aliceScaledBalanceBefore,
      bobScaledBalanceBefore
    );

    uint256 senderBalanceIncrease = aliceScaledBalanceBefore.rayMulFloor(expectedIndex) -
      aliceScaledBalanceBefore.rayMulFloor(previousIndex);
    uint256 recipientBalanceIncrease = bobScaledBalanceBefore.rayMulFloor(expectedIndex) -
      bobScaledBalanceBefore.rayMulFloor(previousIndex);

    vm.expectEmit(address(mockAToken));
    emit IERC20.Transfer(address(0), alice, senderBalanceIncrease);
    vm.expectEmit(address(mockAToken));
    emit IScaledBalanceToken.Mint(
      alice,
      alice,
      senderBalanceIncrease,
      senderBalanceIncrease,
      expectedIndex
    );
    vm.expectEmit(address(mockAToken));
    emit IERC20.Transfer(address(0), bob, recipientBalanceIncrease);
    vm.expectEmit(address(mockAToken));
    emit IScaledBalanceToken.Mint(
      alice,
      bob,
      recipientBalanceIncrease,
      recipientBalanceIncrease,
      expectedIndex
    );
    vm.expectEmit(address(mockAToken));
    emit IERC20.Transfer(alice, bob, transferAmount);

    vm.prank(alice);
    mockAToken.transferWithIndex(alice, bob, transferAmount, expectedIndex);
    assertEq(
      mockAToken.scaledBalanceOf(bob),
      bobScaledBalanceBefore + expectedScaledTransferAmount,
      'bob scaled balance should accrue scaled transfer amount'
    );

    assertEq(
      mockAToken.scaledBalanceOf(alice),
      aliceScaledBalanceBefore - expectedScaledTransferAmount,
      'alice scaled balance should be minus scaled transfer amount'
    );
  }
}
