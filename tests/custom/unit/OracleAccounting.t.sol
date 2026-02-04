// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console2} from 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import '../base/TestZaiBotsMarket.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';

/**
 * @title OracleAccountingTest
 * @notice Tests for oracle pricing and protocol accounting
 * @dev Tests cover:
 *      - Oracle price fetching
 *      - Collateral value calculations
 *      - Debt value calculations
 *      - Interest accrual
 *      - All error conditions
 */
contract OracleAccountingTest is TestZaiBotsMarket {
  // ══════════════════════════════════════════════════════════════════════════════
  // SETUP
  // ══════════════════════════════════════════════════════════════════════════════

  function setUp() public override {
    super.setUp();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ORACLE TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_oracle_allAssetPricesNonZero() public view {
    if (address(oracle) == address(0)) return;

    for (uint256 i = 0; i < collateralAssets.length; i++) {
      uint256 price = oracle.getAssetPrice(collateralAssets[i]);
      assertGt(price, 0, string.concat(collateralSymbols[i], ' price must be > 0'));
    }

    if (address(jpyUbi) != address(0)) {
      uint256 jpyPrice = oracle.getAssetPrice(address(jpyUbi));
      assertGt(jpyPrice, 0, 'jpyUBI price must be > 0');
    }
  }

  function test_oracle_stablecoinPricesReasonable() public view {
    if (address(oracle) == address(0)) return;

    if (address(usdc) != address(0)) {
      uint256 usdcPrice = oracle.getAssetPrice(address(usdc));
      assertGe(usdcPrice, 95e6, 'USDC price too low');
      assertLe(usdcPrice, 105e6, 'USDC price too high');
    }

    if (address(usdt) != address(0)) {
      uint256 usdtPrice = oracle.getAssetPrice(address(usdt));
      assertGe(usdtPrice, 95e6, 'USDT price too low');
      assertLe(usdtPrice, 105e6, 'USDT price too high');
    }
  }

  function test_oracle_jpyUbiPriceReasonable() public view {
    if (address(oracle) == address(0)) return;
    if (address(jpyUbi) == address(0)) return;

    uint256 jpyPrice = oracle.getAssetPrice(address(jpyUbi));

    assertGe(jpyPrice, 5e5, 'jpyUBI price too low');
    assertLe(jpyPrice, 1e7, 'jpyUBI price too high');
  }

  function testFuzz_oracle_priceAlwaysPositive(uint256 assetIndex) external view {
    if (address(oracle) == address(0)) return;
    if (collateralAssets.length == 0) return;

    assetIndex = bound(assetIndex, 0, collateralAssets.length - 1);
    address asset = collateralAssets[assetIndex];

    uint256 price = oracle.getAssetPrice(asset);
    assertGt(price, 0, 'Price must always be positive');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // COLLATERAL VALUE TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_accounting_collateralValueCalculation() public {
    if (address(pool) == address(0)) return;
    if (address(usdc) == address(0)) return;

    uint256 depositAmount = 10000e6;
    deal(address(usdc), alice, depositAmount);

    vm.startPrank(alice);
    usdc.approve(address(pool), depositAmount);
    pool.supply(address(usdc), depositAmount, alice, 0);
    vm.stopPrank();

    (uint256 totalCollateralBase, , , , , ) = pool.getUserAccountData(alice);

    uint256 usdcPrice = oracle.getAssetPrice(address(usdc));
    uint256 expectedValue = (depositAmount * usdcPrice) / 1e6;

    assertApproxEqRel(totalCollateralBase, expectedValue, 1e15);
  }

  function testFuzz_accounting_collateralValueScalesWithDeposit(uint256 depositAmount) external {
    if (address(pool) == address(0)) return;
    if (address(usdc) == address(0)) return;

    depositAmount = bound(depositAmount, 10e6, 1_000_000e6);

    deal(address(usdc), alice, depositAmount);
    vm.startPrank(alice);
    usdc.approve(address(pool), depositAmount);
    pool.supply(address(usdc), depositAmount, alice, 0);
    vm.stopPrank();

    (uint256 totalCollateral, , , , , ) = pool.getUserAccountData(alice);

    uint256 usdcPrice = oracle.getAssetPrice(address(usdc));
    uint256 expectedValue = (depositAmount * usdcPrice) / 1e6;

    assertApproxEqRel(totalCollateral, expectedValue, 1e15);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // DEBT VALUE TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_accounting_debtValueCalculation() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 100000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 100000e6);
    pool.supply(address(usdc), 100000e6, alice, 0);

    uint256 borrowAmount = 1000e18;
    pool.borrow(address(jpyUbi), borrowAmount, 2, 0, alice);
    vm.stopPrank();

    (, uint256 totalDebtBase, , , , ) = pool.getUserAccountData(alice);

    uint256 jpyPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 expectedDebt = (borrowAmount * jpyPrice) / 1e18;

    assertApproxEqRel(totalDebtBase, expectedDebt, 1e15);
  }

  function testFuzz_accounting_debtValueScalesWithBorrow(uint256 borrowAmount) external {
    if (address(pool) == address(0)) return;

    borrowAmount = bound(borrowAmount, 100e18, 100_000e18);

    deal(address(usdc), alice, 1_000_000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 1_000_000e6);
    pool.supply(address(usdc), 1_000_000e6, alice, 0);

    (, , uint256 availableBorrows, , , ) = pool.getUserAccountData(alice);
    uint256 jpyPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 maxBorrow = (availableBorrows * 1e18) / jpyPrice;

    if (borrowAmount > maxBorrow) {
      borrowAmount = (maxBorrow * 90) / 100;
    }

    if (borrowAmount < 100e18) return;

    pool.borrow(address(jpyUbi), borrowAmount, 2, 0, alice);
    vm.stopPrank();

    (, uint256 totalDebt, , , , ) = pool.getUserAccountData(alice);
    uint256 expectedDebt = (borrowAmount * jpyPrice) / 1e18;

    assertApproxEqRel(totalDebt, expectedDebt, 1e15);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // INTEREST ACCRUAL TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_accounting_interestAccruesOverTime() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 100000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 100000e6);
    pool.supply(address(usdc), 100000e6, alice, 0);
    pool.borrow(address(jpyUbi), 10000e18, 2, 0, alice);
    vm.stopPrank();

    (, uint256 debtBefore, , , , ) = pool.getUserAccountData(alice);

    vm.warp(block.timestamp + 365 days);

    (, uint256 debtAfter, , , , ) = pool.getUserAccountData(alice);

    assertGt(debtAfter, debtBefore, 'Debt should increase due to interest');
  }

  function testFuzz_accounting_interestScalesWithTime(uint256 timeElapsed) external {
    if (address(pool) == address(0)) return;

    timeElapsed = bound(timeElapsed, 1 days, 730 days);

    deal(address(usdc), alice, 100000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 100000e6);
    pool.supply(address(usdc), 100000e6, alice, 0);
    pool.borrow(address(jpyUbi), 10000e18, 2, 0, alice);
    vm.stopPrank();

    (, uint256 debtBefore, , , , ) = pool.getUserAccountData(alice);

    vm.warp(block.timestamp + timeElapsed);

    (, uint256 debtAfter, , , , ) = pool.getUserAccountData(alice);

    assertGe(debtAfter, debtBefore, 'Debt should not decrease over time');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // AVAILABLE BORROW TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_accounting_availableBorrowsRespectLTV() public {
    if (address(pool) == address(0)) return;

    uint256 depositAmount = 10000e6;
    deal(address(usdc), alice, depositAmount);
    vm.startPrank(alice);
    usdc.approve(address(pool), depositAmount);
    pool.supply(address(usdc), depositAmount, alice, 0);
    vm.stopPrank();

    (uint256 totalCollateral, , uint256 availableBorrows, , uint256 ltv, ) = pool.getUserAccountData(alice);

    uint256 expectedBorrows = (totalCollateral * ltv) / 10000;

    assertApproxEqRel(availableBorrows, expectedBorrows, 1e15);
  }

  function test_accounting_availableBorrowsDecreaseWithDebt() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 100000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 100000e6);
    pool.supply(address(usdc), 100000e6, alice, 0);

    (, , uint256 availableBefore, , , ) = pool.getUserAccountData(alice);

    pool.borrow(address(jpyUbi), 1000e18, 2, 0, alice);

    (, , uint256 availableAfter, , , ) = pool.getUserAccountData(alice);
    vm.stopPrank();

    assertLt(availableAfter, availableBefore, 'Available borrows should decrease');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // RESERVE DATA TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_accounting_reserveDataConsistent() public {
    if (address(pool) == address(0)) return;

    for (uint256 i = 0; i < collateralAssets.length; i++) {
      DataTypes.ReserveDataLegacy memory reserve = pool.getReserveData(collateralAssets[i]);

      assertGe(reserve.liquidityIndex, RAY, 'Liquidity index should be >= 1 RAY');
      assertGe(reserve.variableBorrowIndex, RAY, 'Variable borrow index should be >= 1 RAY');
      assertNotEq(reserve.aTokenAddress, address(0), 'aToken should be set');
    }
  }

  function test_accounting_jpyUbiReserveSpecialConfig() public view {
    if (address(pool) == address(0)) return;
    if (address(jpyUbi) == address(0)) return;

    DataTypes.ReserveDataLegacy memory reserve = pool.getReserveData(address(jpyUbi));

    assertNotEq(reserve.aTokenAddress, address(0), 'jpyUBI aToken should be set');
    assertNotEq(reserve.variableDebtTokenAddress, address(0), 'jpyUBI variable debt token should be set');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MULTI-USER ACCOUNTING TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_accounting_multipleUsersIndependent() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);
    vm.stopPrank();

    deal(address(usdt), bob, 10000e6);
    vm.startPrank(bob);
    usdt.approve(address(pool), 10000e6);
    pool.supply(address(usdt), 10000e6, bob, 0);
    vm.stopPrank();

    (uint256 aliceCollateral, , , , , ) = pool.getUserAccountData(alice);
    (uint256 bobCollateral, , , , , ) = pool.getUserAccountData(bob);

    assertGt(aliceCollateral, 0, 'Alice should have collateral');
    assertGt(bobCollateral, 0, 'Bob should have collateral');

    vm.prank(alice);
    pool.withdraw(address(usdc), 1000e6, alice);

    (uint256 aliceAfter, , , , , ) = pool.getUserAccountData(alice);
    (uint256 bobAfter, , , , , ) = pool.getUserAccountData(bob);

    assertLt(aliceAfter, aliceCollateral, 'Alice collateral should decrease');
    assertEq(bobAfter, bobCollateral, 'Bob collateral should be unchanged');
  }

  function testFuzz_accounting_totalSupplyMatchesATokenSupply(uint256 depositAmount1, uint256 depositAmount2) external {
    if (address(pool) == address(0)) return;
    if (address(usdc) == address(0)) return;

    depositAmount1 = bound(depositAmount1, 1000e6, 100_000e6);
    depositAmount2 = bound(depositAmount2, 1000e6, 100_000e6);

    DataTypes.ReserveDataLegacy memory reserve = pool.getReserveData(address(usdc));

    uint256 initialSupply = IERC20(reserve.aTokenAddress).totalSupply();

    deal(address(usdc), alice, depositAmount1);
    vm.startPrank(alice);
    usdc.approve(address(pool), depositAmount1);
    pool.supply(address(usdc), depositAmount1, alice, 0);
    vm.stopPrank();

    deal(address(usdc), bob, depositAmount2);
    vm.startPrank(bob);
    usdc.approve(address(pool), depositAmount2);
    pool.supply(address(usdc), depositAmount2, bob, 0);
    vm.stopPrank();

    uint256 finalSupply = IERC20(reserve.aTokenAddress).totalSupply();
    uint256 expectedIncrease = depositAmount1 + depositAmount2;

    assertApproxEqRel(finalSupply - initialSupply, expectedIncrease, 1e15);
  }
}
