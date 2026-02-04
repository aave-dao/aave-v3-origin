// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console2} from 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import '../base/TestZaiBotsMarket.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';

/**
 * @title BorrowingIntegrationTest
 * @notice Integration tests for jpyUBI borrowing against collateral
 * @dev Tests cover:
 *      - Full borrow/repay cycles
 *      - Health factor enforcement
 *      - Overcollateralization requirements
 *      - Error conditions with exact error messages
 *      - Fuzz testing on all parameters
 */
contract BorrowingIntegrationTest is TestZaiBotsMarket {
  // ══════════════════════════════════════════════════════════════════════════════
  // SETUP
  // ══════════════════════════════════════════════════════════════════════════════

  function setUp() public override {
    super.setUp();

    if (address(pool) == address(0)) {
      return;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // BORROW - ERROR CONDITIONS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_borrow_revert_noCollateral() public {
    if (address(pool) == address(0)) return;

    vm.prank(alice);
    vm.expectRevert(bytes(ERR_COLLATERAL_BALANCE_ZERO));
    pool.borrow(address(jpyUbi), 100e18, 2, 0, alice);
  }

  function test_borrow_revert_borrowingNotEnabled() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);

    vm.expectRevert(bytes(ERR_BORROWING_NOT_ENABLED));
    pool.borrow(address(usdc), 1000e6, 2, 0, alice);
    vm.stopPrank();
  }

  function test_borrow_revert_exceedsCollateralValue() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 100e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 100e6);
    pool.supply(address(usdc), 100e6, alice, 0);

    vm.expectRevert(bytes(ERR_COLLATERAL_CANNOT_COVER_BORROW));
    pool.borrow(address(jpyUbi), 1000000e18, 2, 0, alice);
    vm.stopPrank();
  }

  function testFuzz_borrow_revert_exceedsLTV(uint256 depositAmount, uint256 borrowMultiplier) external {
    if (address(pool) == address(0)) return;

    depositAmount = bound(depositAmount, 10e6, 1_000_000e6);
    borrowMultiplier = bound(borrowMultiplier, 2, 10);

    deal(address(usdc), alice, depositAmount);
    vm.startPrank(alice);
    usdc.approve(address(pool), depositAmount);
    pool.supply(address(usdc), depositAmount, alice, 0);

    (, , uint256 availableBorrowsBase, , , ) = pool.getUserAccountData(alice);
    uint256 jpyUbiPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 maxBorrow = (availableBorrowsBase * 1e18) / jpyUbiPrice;

    uint256 excessiveBorrow = maxBorrow * borrowMultiplier;

    vm.expectRevert(bytes(ERR_COLLATERAL_CANNOT_COVER_BORROW));
    pool.borrow(address(jpyUbi), excessiveBorrow, 2, 0, alice);
    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // BORROW - SUCCESS CASES
  // ══════════════════════════════════════════════════════════════════════════════

  function test_borrow_success_basicFlow() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);

    (, , uint256 availableBorrowsBase, , , ) = pool.getUserAccountData(alice);
    assertGt(availableBorrowsBase, 0, 'Should have borrow capacity');

    uint256 jpyUbiPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 safeBorrow = (availableBorrowsBase * 1e18 * 50) / (jpyUbiPrice * 100);

    pool.borrow(address(jpyUbi), safeBorrow, 2, 0, alice);
    vm.stopPrank();

    assertGt(jpyUbi.balanceOf(alice), 0, 'Should have jpyUBI balance');
    (, uint256 totalDebtBase, , , , uint256 healthFactor) = pool.getUserAccountData(alice);
    assertGt(totalDebtBase, 0, 'Should have debt');
    assertGt(healthFactor, 1e18, 'Health factor should be > 1');
  }

  function test_borrow_success_afterErrorThenCollateralDeposit() public {
    if (address(pool) == address(0)) return;

    vm.prank(alice);
    vm.expectRevert(bytes(ERR_COLLATERAL_BALANCE_ZERO));
    pool.borrow(address(jpyUbi), 100e18, 2, 0, alice);

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);

    pool.borrow(address(jpyUbi), 100e18, 2, 0, alice);
    vm.stopPrank();

    assertEq(jpyUbi.balanceOf(alice), 100e18);
  }

  function testFuzz_borrow_success_withinLTV(uint256 depositAmount, uint256 borrowPercent) external {
    if (address(pool) == address(0)) return;

    depositAmount = bound(depositAmount, 100e6, 100_000e6);
    borrowPercent = bound(borrowPercent, 10, 80);

    deal(address(usdc), alice, depositAmount);
    vm.startPrank(alice);
    usdc.approve(address(pool), depositAmount);
    pool.supply(address(usdc), depositAmount, alice, 0);

    (, , uint256 availableBorrowsBase, , , ) = pool.getUserAccountData(alice);
    uint256 jpyUbiPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 borrowAmount = (availableBorrowsBase * 1e18 * borrowPercent) / (jpyUbiPrice * 100);

    if (borrowAmount > 0) {
      pool.borrow(address(jpyUbi), borrowAmount, 2, 0, alice);

      (, , , , , uint256 healthFactor) = pool.getUserAccountData(alice);
      assertGe(healthFactor, 1e18, 'Health factor should be >= 1');
    }
    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // REPAY - ERROR CONDITIONS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_repay_revert_noDebt() public {
    if (address(pool) == address(0)) return;

    deal(address(jpyUbi), alice, 1000e18);
    vm.startPrank(alice);
    jpyUbi.approve(address(pool), 1000e18);

    uint256 repaid = pool.repay(address(jpyUbi), 1000e18, 2, alice);
    assertEq(repaid, 0, 'Should repay 0 when no debt');
    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // REPAY - SUCCESS CASES
  // ══════════════════════════════════════════════════════════════════════════════

  function test_repay_success_fullRepayment() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);
    pool.borrow(address(jpyUbi), 1000e18, 2, 0, alice);

    (, uint256 debtBefore, , , , ) = pool.getUserAccountData(alice);
    assertGt(debtBefore, 0, 'Should have debt');

    jpyUbi.approve(address(pool), type(uint256).max);
    pool.repay(address(jpyUbi), type(uint256).max, 2, alice);
    vm.stopPrank();

    (, uint256 debtAfter, , , , ) = pool.getUserAccountData(alice);
    assertEq(debtAfter, 0, 'Should have no debt');
  }

  function test_repay_success_partialRepayment() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);
    pool.borrow(address(jpyUbi), 1000e18, 2, 0, alice);

    (, uint256 debtBefore, , , , ) = pool.getUserAccountData(alice);

    jpyUbi.approve(address(pool), 500e18);
    pool.repay(address(jpyUbi), 500e18, 2, alice);
    vm.stopPrank();

    (, uint256 debtAfter, , , , ) = pool.getUserAccountData(alice);
    assertLt(debtAfter, debtBefore, 'Debt should have decreased');
    assertGt(debtAfter, 0, 'Should still have some debt');
  }

  function testFuzz_repay_success(uint256 borrowAmount, uint256 repayPercent) external {
    if (address(pool) == address(0)) return;

    borrowAmount = bound(borrowAmount, 100e18, 10000e18);
    repayPercent = bound(repayPercent, 10, 100);

    deal(address(usdc), alice, 100000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 100000e6);
    pool.supply(address(usdc), 100000e6, alice, 0);

    pool.borrow(address(jpyUbi), borrowAmount, 2, 0, alice);

    uint256 repayAmount = (borrowAmount * repayPercent) / 100;

    deal(address(jpyUbi), alice, borrowAmount * 2);

    jpyUbi.approve(address(pool), repayAmount);
    pool.repay(address(jpyUbi), repayAmount, 2, alice);
    vm.stopPrank();

    (, uint256 debt, , , , ) = pool.getUserAccountData(alice);
    if (repayPercent == 100) {
      assertLe(debt, 1e8, 'Debt should be near zero after full repay');
    } else {
      assertGt(debt, 0, 'Should still have debt after partial repay');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HEALTH FACTOR TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_healthFactor_decreasesWithBorrowing() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);

    (, , , , , uint256 hfBefore) = pool.getUserAccountData(alice);

    pool.borrow(address(jpyUbi), 1000e18, 2, 0, alice);

    (, , , , , uint256 hfAfter1) = pool.getUserAccountData(alice);
    assertLt(hfAfter1, hfBefore, 'HF should decrease after borrow');

    pool.borrow(address(jpyUbi), 1000e18, 2, 0, alice);

    (, , , , , uint256 hfAfter2) = pool.getUserAccountData(alice);
    assertLt(hfAfter2, hfAfter1, 'HF should decrease more with more debt');

    vm.stopPrank();
  }

  function test_healthFactor_increasesWithRepayment() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);
    pool.borrow(address(jpyUbi), 5000e18, 2, 0, alice);

    (, , , , , uint256 hfBefore) = pool.getUserAccountData(alice);

    jpyUbi.approve(address(pool), 2000e18);
    pool.repay(address(jpyUbi), 2000e18, 2, alice);

    (, , , , , uint256 hfAfter) = pool.getUserAccountData(alice);
    assertGt(hfAfter, hfBefore, 'HF should increase after repay');

    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // OVERCOLLATERALIZATION INVARIANT
  // ══════════════════════════════════════════════════════════════════════════════

  function test_overcollateralization_debtNeverExceedsCollateralLTV() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);

    (, , uint256 availableBorrowsBase, , uint256 ltv, ) = pool.getUserAccountData(alice);

    uint256 jpyUbiPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 borrowAmount = (availableBorrowsBase * 1e18 * 99) / (jpyUbiPrice * 100);

    pool.borrow(address(jpyUbi), borrowAmount, 2, 0, alice);

    (uint256 collateral, uint256 debt, , , , uint256 hf) = pool.getUserAccountData(alice);

    uint256 maxDebtByLTV = (collateral * ltv) / 10000;
    assertLe(debt, maxDebtByLTV, 'Debt should not exceed LTV-allowed amount');
    assertGe(hf, 1e18, 'Health factor must be >= 1');

    vm.stopPrank();
  }

  function testFuzz_overcollateralization_alwaysMaintained(uint256 depositAmount, uint256 borrowPercent) external {
    if (address(pool) == address(0)) return;

    depositAmount = bound(depositAmount, 1000e6, 1_000_000e6);
    borrowPercent = bound(borrowPercent, 1, 99);

    deal(address(usdc), alice, depositAmount);
    vm.startPrank(alice);
    usdc.approve(address(pool), depositAmount);
    pool.supply(address(usdc), depositAmount, alice, 0);

    (, , uint256 availableBorrows, , uint256 ltv, ) = pool.getUserAccountData(alice);
    uint256 jpyUbiPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 borrowAmount = (availableBorrows * 1e18 * borrowPercent) / (jpyUbiPrice * 100);

    if (borrowAmount > 0) {
      pool.borrow(address(jpyUbi), borrowAmount, 2, 0, alice);

      (uint256 collateral, uint256 debt, , , , uint256 hf) = pool.getUserAccountData(alice);

      uint256 maxDebt = (collateral * ltv) / 10000;
      assertLe(debt, maxDebt, 'INVARIANT VIOLATED: Overcollateralization');
      assertGe(hf, 1e18, 'INVARIANT VIOLATED: Health factor < 1');
    }

    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MULTI-COLLATERAL TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_multiCollateral_combinedBorrowCapacity() public {
    if (address(pool) == address(0)) return;

    deal(address(usdc), alice, 5000e6);
    deal(address(usdt), alice, 5000e6);

    vm.startPrank(alice);

    usdc.approve(address(pool), 5000e6);
    pool.supply(address(usdc), 5000e6, alice, 0);

    usdt.approve(address(pool), 5000e6);
    pool.supply(address(usdt), 5000e6, alice, 0);

    (, , uint256 availableBorrows, , , ) = pool.getUserAccountData(alice);

    uint256 jpyUbiPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 borrowAmount = (availableBorrows * 1e18 * 50) / (jpyUbiPrice * 100);

    pool.borrow(address(jpyUbi), borrowAmount, 2, 0, alice);

    (, uint256 debt, , , , uint256 hf) = pool.getUserAccountData(alice);
    assertGt(debt, 0, 'Should have debt');
    assertGe(hf, 1e18, 'Health factor should be >= 1');

    vm.stopPrank();
  }
}
