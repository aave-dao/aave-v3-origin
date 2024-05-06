// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {SupplyLogic} from '../../../src/contracts/protocol/libraries/logic/SupplyLogic.sol';
import {MathUtils} from '../../../src/contracts/protocol/libraries/math/MathUtils.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract ATokenTransferTests is TestnetProcedures {
  using WadRayMath for uint256;
  IAToken public aToken;
  IVariableDebtToken public variableDebtToken;

  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  function setUp() public {
    initTestEnvironment(false);

    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
    (, , address variableDebtWBTC) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.wbtc
    );
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
    emit Transfer(alice, alice, 120e6);

    vm.prank(alice);
    aToken.transfer(alice, 120e6);
  }

  function test_atoken_alice_transfer_to_herself_zero() public {
    vm.expectEmit(address(aToken));
    emit Transfer(alice, alice, 0);

    vm.prank(alice);
    aToken.transfer(alice, 0);
  }

  function test_atoken_alice_transfer_to_bob() public {
    uint256 transferAmount = 120e6;
    uint256 aliceBalanceBefore = aToken.balanceOf(alice);
    uint256 bobBalanceBefore = aToken.balanceOf(bob);
    vm.expectEmit(address(aToken));
    emit Transfer(alice, bob, transferAmount);
    vm.expectEmit(report.poolProxy);
    emit SupplyLogic.ReserveUsedAsCollateralEnabled(tokenList.usdx, bob);

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
    emit Transfer(alice, bob, transferAmount);

    vm.expectEmit(report.poolProxy);
    emit SupplyLogic.ReserveUsedAsCollateralDisabled(tokenList.usdx, alice);
    vm.expectEmit(report.poolProxy);
    emit SupplyLogic.ReserveUsedAsCollateralEnabled(tokenList.usdx, bob);
    vm.expectEmit(address(aToken));
    emit BalanceTransfer(alice, bob, transferAmount, 1e27);

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
    emit Transfer(alice, bob, 0);

    vm.prank(alice);
    aToken.transfer(bob, 0);

    (uint256 bobCollateralBalance, , , , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(tokenList.usdx, bob);
    assertEq(bobCollateralBalance, 0, 'Bob collateral balance should still be zero');
  }

  function test_atoken_multiple_transfers() public {
    vm.expectEmit(address(aToken));
    emit Transfer(alice, bob, 10_000e6);

    vm.prank(alice);
    aToken.transfer(bob, 10_000e6);

    vm.expectEmit(address(aToken));
    emit Transfer(bob, alice, 444e6);

    vm.prank(bob);
    aToken.transfer(alice, 444e6);

    vm.expectEmit(address(aToken));
    emit Transfer(bob, carol, 555e6);

    vm.prank(bob);
    aToken.transfer(carol, 555e6);
  }

  function test_atoken_transfer_to_bob_them_bob_borrows() public {
    uint256 transferAmount = 50_000e6;
    vm.expectEmit(address(aToken));
    emit Transfer(alice, bob, transferAmount);

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
    emit Transfer(alice, bob, 50_000e6);

    vm.prank(alice);
    aToken.transfer(bob, 50_000e6);

    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.wbtc, 1e8, 2, 0, bob);

    uint256 transferAmount = aToken.balanceOf(bob);

    vm.expectRevert(bytes(Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD));
    vm.prank(bob);
    aToken.transfer(alice, transferAmount);
  }

  function test_atoken_transfer_some_collateral_from_bob_borrower_to_alice() public {
    vm.expectEmit(address(aToken));
    emit Transfer(alice, bob, 50_000e6);

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
    emit Transfer(alice, carol, transferAmount);

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
    uint64 timePassed,
    uint256 amount
  ) public {
    uint256 aliceBalance = IERC20(aToken).balanceOf(alice);
    vm.assume(amount <= aliceBalance);
    vm.assume(timePassed > 0);
    address mockReceiver = vm.addr(42);

    // borrow all available usdx
    vm.prank(carol);
    contracts.poolProxy.borrow(tokenList.usdx, 200_000e6, 2, 0, carol);

    // wait to inflate the index
    vm.warp(block.timestamp + timePassed);
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
}
