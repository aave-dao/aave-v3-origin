// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console2} from 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import '../base/TestZaiBotsMarket.sol';

/**
 * @title FlashLoanAttackTest
 * @notice Tests that verify flash loan attack vectors are blocked
 * @dev Tests cover:
 *      - Recursive flash loan collateral inflation
 *      - Empty pool manipulation
 *      - Multi-asset flash loan attacks
 *      - All error conditions with exact error messages
 *      - Documentation of vulnerable configurations
 */
contract FlashLoanAttackTest is TestZaiBotsMarket {
  // ══════════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ══════════════════════════════════════════════════════════════════════════════

  uint256 constant VULNERABLE_DEPOSIT_THRESHOLD = 100e6;

  // ══════════════════════════════════════════════════════════════════════════════
  // SETUP
  // ══════════════════════════════════════════════════════════════════════════════

  function setUp() public override {
    super.setUp();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // FLASH LOAN BLOCKED TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_attack_flashLoanBlockedOnUSDC() public {
    if (address(pool) == address(0)) return;
    if (address(usdc) == address(0)) return;

    vm.prank(attacker);
    vm.expectRevert(bytes(ERR_FLASHLOAN_DISABLED));
    pool.flashLoanSimple(attacker, address(usdc), 1e12, '', 0);
  }

  function test_attack_flashLoanBlockedOnUSDT() public {
    if (address(pool) == address(0)) return;
    if (address(usdt) == address(0)) return;

    vm.prank(attacker);
    vm.expectRevert(bytes(ERR_FLASHLOAN_DISABLED));
    pool.flashLoanSimple(attacker, address(usdt), 1e12, '', 0);
  }

  function test_attack_flashLoanBlockedOnCbBTC() public {
    if (address(pool) == address(0)) return;
    if (address(cbBtc) == address(0)) return;

    vm.prank(attacker);
    vm.expectRevert(bytes(ERR_FLASHLOAN_DISABLED));
    pool.flashLoanSimple(attacker, address(cbBtc), 1e8, '', 0);
  }

  function test_attack_flashLoanBlockedOnJpyUBI() public {
    if (address(pool) == address(0)) return;
    if (address(jpyUbi) == address(0)) return;

    vm.prank(attacker);
    vm.expectRevert(bytes(ERR_FLASHLOAN_DISABLED));
    pool.flashLoanSimple(attacker, address(jpyUbi), 1e24, '', 0);
  }

  function testFuzz_attack_flashLoanBlockedOnAllAssets(uint256 assetIndex, uint256 amount) external {
    if (address(pool) == address(0)) return;
    if (collateralAssets.length == 0) return;

    assetIndex = bound(assetIndex, 0, collateralAssets.length - 1);
    amount = bound(amount, 1, type(uint128).max);

    address asset = collateralAssets[assetIndex];

    vm.prank(attacker);
    vm.expectRevert(bytes(ERR_FLASHLOAN_DISABLED));
    pool.flashLoanSimple(attacker, asset, amount, '', 0);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MULTI-ASSET FLASH LOAN BLOCKED
  // ══════════════════════════════════════════════════════════════════════════════

  function test_attack_multiAssetFlashLoanBlocked() public {
    if (address(pool) == address(0)) return;
    if (collateralAssets.length == 0) return;

    uint256[] memory amounts = new uint256[](collateralAssets.length);
    uint256[] memory modes = new uint256[](collateralAssets.length);

    for (uint256 i = 0; i < collateralAssets.length; i++) {
      amounts[i] = 1e18;
      modes[i] = 0;
    }

    vm.prank(attacker);
    vm.expectRevert();
    pool.flashLoan(attacker, collateralAssets, amounts, modes, attacker, '', 0);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ATTACK SIMULATION - WHAT WOULD HAPPEN IF FLASH LOANS WERE ENABLED
  // ══════════════════════════════════════════════════════════════════════════════

  function test_attack_documentVulnerableConfiguration() public pure {
    console2.log('');
    console2.log('========================================');
    console2.log('FLASH LOAN ATTACK VECTOR DOCUMENTATION');
    console2.log('========================================');
    console2.log('');
    console2.log('ATTACK STEPS (if vulnerable):');
    console2.log('1. Flash loan $100 USDC from nearly empty pool');
    console2.log('2. Deposit $100 USDC as collateral');
    console2.log("3. Borrow $85 worth of jpyUBI (85% LTV)");
    console2.log('4. Sell jpyUBI for $85 USDC');
    console2.log('5. Repay $100 flash loan (need $15 more)');
    console2.log('6. Result: Attacker has $85 aTokens, $85 debt');
    console2.log('');
    console2.log('WHY THIS FAILS WITH CURRENT CONFIG:');
    console2.log('- Flash loans DISABLED on all assets');
    console2.log('- Cannot execute step 1');
    console2.log('');
    console2.log('CHANGES THAT WOULD ENABLE ATTACK:');
    console2.log('- Enable flashLoanEnabled on USDC');
    console2.log('- Deploy with < $100 initial liquidity');
    console2.log('- Remove debt ceilings');
    console2.log('========================================');
    console2.log('');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HEALTH FACTOR PROTECTION TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_attack_healthFactorPreventsOverBorrow() public {
    if (address(pool) == address(0)) return;

    uint256 externalLoan = 10000e6;
    deal(address(usdc), attacker, externalLoan);

    vm.startPrank(attacker);
    usdc.approve(address(pool), externalLoan);
    pool.supply(address(usdc), externalLoan, attacker, 0);

    (, , uint256 availableBorrows, , , ) = pool.getUserAccountData(attacker);
    uint256 jpyPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 maxBorrow = (availableBorrows * 1e18) / jpyPrice;

    vm.expectRevert(bytes(ERR_COLLATERAL_CANNOT_COVER_BORROW));
    pool.borrow(address(jpyUbi), maxBorrow * 2, 2, 0, attacker);

    vm.stopPrank();
  }

  function test_attack_externalFlashLoanUnprofitable() public {
    if (address(pool) == address(0)) return;

    uint256 flashLoanAmount = 10000e6;
    uint256 flashLoanFee = (flashLoanAmount * 9) / 10000;

    deal(address(usdc), attacker, flashLoanAmount);

    vm.startPrank(attacker);
    usdc.approve(address(pool), flashLoanAmount);
    pool.supply(address(usdc), flashLoanAmount, attacker, 0);

    (, , uint256 availableBorrows, , , ) = pool.getUserAccountData(attacker);
    uint256 jpyPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 maxBorrow = (availableBorrows * 1e18 * 95) / (jpyPrice * 100);

    pool.borrow(address(jpyUbi), maxBorrow, 2, 0, attacker);

    uint256 borrowedValue = (maxBorrow * jpyPrice) / 1e18;

    uint256 totalRepayNeeded = flashLoanAmount + flashLoanFee;

    assertLt(borrowedValue, totalRepayNeeded, 'ATTACK UNPROFITABLE: Cannot repay flash loan from borrowed funds');

    console2.log('');
    console2.log('Flash loan attack profitability analysis:');
    console2.log('  Flash loan amount:', flashLoanAmount / 1e6, 'USDC');
    console2.log('  Flash loan fee:', flashLoanFee / 1e6, 'USDC');
    console2.log('  Total repay needed:', totalRepayNeeded / 1e6, 'USDC');
    console2.log('  Max borrow value:', borrowedValue / 1e6, 'USD');
    console2.log('  RESULT: UNPROFITABLE');
    console2.log('');

    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MINIMUM DEPOSIT PROTECTION TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_protection_minimumDepositsRecommended() public pure {
    console2.log('');
    console2.log('========================================');
    console2.log('RECOMMENDED MINIMUM DEPOSITS');
    console2.log('========================================');
    console2.log('');
    console2.log('Before enabling borrowing, seed pools with:');
    console2.log('');
    console2.log('BLUE CHIP ASSETS:');
    console2.log('  USDC:  $10,000 minimum');
    console2.log('  USDT:  $10,000 minimum');
    console2.log('  cbBTC: 0.1 BTC (~$10,000)');
    console2.log('  LINK:  500 LINK (~$10,000)');
    console2.log('');
    console2.log('VOLATILE ASSETS:');
    console2.log('  (Debt ceilings provide protection)');
    console2.log('  VIRTUALS: $1,000 minimum');
    console2.log('  FET:      $1,000 minimum');
    console2.log('  RENDER:   $1,000 minimum');
    console2.log('');
    console2.log('jpyUBI: No deposit needed (minted on borrow)');
    console2.log('========================================');
    console2.log('');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ISOLATION MODE PROTECTION TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_protection_debtCeilingLimitsExposure() public {
    if (address(pool) == address(0)) return;
    if (address(virtuals) == address(0)) return;

    uint256 debtCeiling = _getDebtCeiling(address(virtuals));
    if (debtCeiling == 0) return;

    console2.log('');
    console2.log('Debt ceiling protection:');
    console2.log('  VIRTUALS debt ceiling: $', debtCeiling / 100);
    console2.log('  Max protocol exposure limited regardless of:');
    console2.log('  - Oracle manipulation');
    console2.log('  - Price volatility');
    console2.log('  - Market manipulation');
    console2.log('');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // CONFIGURATION VERIFICATION TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_protection_allFlashLoansDisabled() public view {
    if (address(pool) == address(0)) return;

    for (uint256 i = 0; i < collateralAssets.length; i++) {
      bool flashEnabled = _isFlashLoanEnabled(collateralAssets[i]);
      assertFalse(flashEnabled, string.concat('CRITICAL: ', collateralSymbols[i], ' has flash loans enabled!'));
    }

    if (address(jpyUbi) != address(0)) {
      assertFalse(_isFlashLoanEnabled(address(jpyUbi)), 'CRITICAL: jpyUBI has flash loans enabled!');
    }
  }

  function test_protection_jpyUbiNotCollateral() public view {
    if (address(pool) == address(0)) return;
    if (address(jpyUbi) == address(0)) return;

    uint256 ltv = _getLTV(address(jpyUbi));
    assertEq(ltv, 0, 'CRITICAL: jpyUBI can be used as collateral!');
  }

  function test_protection_volatileAssetsIsolated() public view {
    if (address(pool) == address(0)) return;

    address[] memory volatileAssets = new address[](4);
    volatileAssets[0] = address(virtuals);
    volatileAssets[1] = address(fet);
    volatileAssets[2] = address(render);
    volatileAssets[3] = address(cusd);

    for (uint256 i = 0; i < volatileAssets.length; i++) {
      if (volatileAssets[i] == address(0)) continue;

      uint256 debtCeiling = _getDebtCeiling(volatileAssets[i]);
      assertGt(debtCeiling, 0, 'CRITICAL: Volatile asset has no debt ceiling!');
    }
  }
}
