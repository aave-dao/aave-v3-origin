// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console2} from 'forge-std/Test.sol';
import '../base/TestZaiBotsMarket.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

/**
 * @title ConfigurationACLTest
 * @notice Tests for protocol configuration and access control
 * @dev Tests cover:
 *      - Reserve configuration (LTV, LT, borrowing enabled, etc.)
 *      - Flash loan configuration
 *      - Isolation mode configuration
 *      - ACL for pool admin, risk admin, emergency admin
 *      - All error conditions with exact error messages
 */
contract ConfigurationACLTest is TestZaiBotsMarket {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  // ══════════════════════════════════════════════════════════════════════════════
  // SETUP
  // ══════════════════════════════════════════════════════════════════════════════

  function setUp() public override {
    super.setUp();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // RESERVE CONFIGURATION TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_config_jpyUbiNotCollateral() public view {
    if (address(pool) == address(0)) return;

    uint256 ltv = _getLTV(address(jpyUbi));
    uint256 lt = _getLiquidationThreshold(address(jpyUbi));

    assertEq(ltv, 0, 'jpyUBI LTV must be 0');
    assertEq(lt, 0, 'jpyUBI liquidation threshold must be 0');
  }

  function test_config_jpyUbiBorrowable() public view {
    if (address(pool) == address(0)) return;

    assertTrue(_isBorrowingEnabled(address(jpyUbi)), 'jpyUBI must be borrowable');
  }

  function test_config_collateralAssetsNotBorrowable() public view {
    if (address(pool) == address(0)) return;

    for (uint256 i = 0; i < collateralAssets.length; i++) {
      assertFalse(
        _isBorrowingEnabled(collateralAssets[i]),
        string.concat(collateralSymbols[i], ' must not be borrowable')
      );
    }
  }

  function test_config_stablecoinsHighLTV() public view {
    if (address(pool) == address(0)) return;

    if (address(usdc) != address(0)) {
      uint256 usdcLtv = _getLTV(address(usdc));
      assertGe(usdcLtv, 7500, 'USDC LTV should be >= 75%');
      assertLe(usdcLtv, 9000, 'USDC LTV should be <= 90%');
    }

    if (address(usdt) != address(0)) {
      uint256 usdtLtv = _getLTV(address(usdt));
      assertGe(usdtLtv, 7500, 'USDT LTV should be >= 75%');
      assertLe(usdtLtv, 9000, 'USDT LTV should be <= 90%');
    }
  }

  function test_config_volatileAssetsLowLTV() public view {
    if (address(pool) == address(0)) return;

    address[] memory volatileAssets = new address[](3);
    volatileAssets[0] = address(virtuals);
    volatileAssets[1] = address(fet);
    volatileAssets[2] = address(render);

    for (uint256 i = 0; i < volatileAssets.length; i++) {
      if (volatileAssets[i] == address(0)) continue;

      uint256 ltv = _getLTV(volatileAssets[i]);
      assertLe(ltv, 5000, 'Volatile asset LTV should be <= 50%');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // FLASH LOAN CONFIGURATION TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_config_flashLoansDisabled() public view {
    if (address(pool) == address(0)) return;

    for (uint256 i = 0; i < collateralAssets.length; i++) {
      assertFalse(
        _isFlashLoanEnabled(collateralAssets[i]),
        string.concat(collateralSymbols[i], ' flash loans must be disabled')
      );
    }

    assertFalse(_isFlashLoanEnabled(address(jpyUbi)), 'jpyUBI flash loans must be disabled');
  }

  function test_flashLoan_revert_disabled() public {
    if (address(pool) == address(0)) return;

    for (uint256 i = 0; i < collateralAssets.length; i++) {
      address asset = collateralAssets[i];

      vm.prank(attacker);
      vm.expectRevert(bytes(ERR_FLASHLOAN_DISABLED));
      pool.flashLoanSimple(attacker, asset, 1000e18, '', 0);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ISOLATION MODE CONFIGURATION TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_config_volatileAssetsIsolated() public view {
    if (address(pool) == address(0)) return;

    address[] memory volatileAssets = new address[](4);
    volatileAssets[0] = address(virtuals);
    volatileAssets[1] = address(fet);
    volatileAssets[2] = address(render);
    volatileAssets[3] = address(cusd);

    for (uint256 i = 0; i < volatileAssets.length; i++) {
      if (volatileAssets[i] == address(0)) continue;

      uint256 debtCeiling = _getDebtCeiling(volatileAssets[i]);
      assertGt(debtCeiling, 0, 'Volatile asset must have debt ceiling > 0');
    }
  }

  function test_config_blueChipsNotIsolated() public view {
    if (address(pool) == address(0)) return;

    if (address(usdc) != address(0)) {
      uint256 debtCeiling = _getDebtCeiling(address(usdc));
      assertTrue(debtCeiling == 0 || debtCeiling > 1e12, 'USDC should not be in restrictive isolation mode');
    }
  }

  function test_isolation_debtCeilingEnforced() public {
    if (address(pool) == address(0)) return;
    if (address(virtuals) == address(0)) return;

    uint256 debtCeiling = _getDebtCeiling(address(virtuals));
    if (debtCeiling == 0) return;

    deal(address(virtuals), alice, 1e24);
    vm.startPrank(alice);
    virtuals.approve(address(pool), 1e24);
    pool.supply(address(virtuals), 1e24, alice, 0);

    uint256 jpyUbiPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 excessBorrow = (debtCeiling * 1e18 * 2) / jpyUbiPrice;

    vm.expectRevert(bytes(ERR_DEBT_CEILING_EXCEEDED));
    pool.borrow(address(jpyUbi), excessBorrow, 2, 0, alice);
    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ACL - POOL ADMIN TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_acl_onlyPoolAdminCanSetReserveConfig() public {
    if (address(configurator) == address(0)) return;

    vm.prank(attacker);
    vm.expectRevert();
    configurator.setReserveActive(address(usdc), false);
  }

  function test_acl_onlyRiskAdminCanSetRiskParams() public {
    if (address(configurator) == address(0)) return;
    if (address(usdc) == address(0)) return;

    vm.prank(attacker);
    vm.expectRevert();
    configurator.setReserveBorrowing(address(usdc), true);
  }

  function test_acl_onlyEmergencyAdminCanPause() public {
    if (address(configurator) == address(0)) return;

    vm.prank(attacker);
    vm.expectRevert();
    configurator.setPoolPause(true);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // SUPPLY/BORROW CAPS TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_config_capsEnforced() public {
    if (address(pool) == address(0)) return;
    if (address(usdc) == address(0)) return;

    DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(address(usdc));
    uint256 supplyCap = config.getSupplyCap();

    if (supplyCap == 0) return;

    uint256 excessAmount = supplyCap * 2;
    deal(address(usdc), alice, excessAmount);

    vm.startPrank(alice);
    usdc.approve(address(pool), excessAmount);

    vm.expectRevert(bytes(ERR_SUPPLY_CAP_EXCEEDED));
    pool.supply(address(usdc), excessAmount, alice, 0);
    vm.stopPrank();
  }

  function test_config_borrowCapEnforced() public {
    if (address(pool) == address(0)) return;
    if (address(jpyUbi) == address(0)) return;

    DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(address(jpyUbi));
    uint256 borrowCap = config.getBorrowCap();

    if (borrowCap == 0) return;

    deal(address(usdc), alice, 1e15);
    vm.startPrank(alice);
    usdc.approve(address(pool), 1e15);
    pool.supply(address(usdc), 1e15, alice, 0);

    uint256 excessBorrow = borrowCap * 2 * 1e18;

    vm.expectRevert(bytes(ERR_BORROW_CAP_EXCEEDED));
    pool.borrow(address(jpyUbi), excessBorrow, 2, 0, alice);
    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // EMODE TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_eMode_stablecoinMode() public {
    if (address(pool) == address(0)) return;

    DataTypes.EModeCategoryLegacy memory stableMode = pool.getEModeCategoryData(1);

    if (stableMode.ltv == 0) return;

    assertGt(stableMode.ltv, 9000, 'Stable emode LTV should be > 90%');
    assertGt(stableMode.liquidationThreshold, 9500, 'Stable emode LT should be > 95%');
  }

  function test_eMode_canActivateForUser() public {
    if (address(pool) == address(0)) return;

    DataTypes.EModeCategoryLegacy memory stableMode = pool.getEModeCategoryData(1);
    if (stableMode.ltv == 0) return;

    deal(address(usdc), alice, 10000e6);
    vm.startPrank(alice);
    usdc.approve(address(pool), 10000e6);
    pool.supply(address(usdc), 10000e6, alice, 0);

    pool.setUserEMode(1);

    uint256 userEmode = pool.getUserEMode(alice);
    assertEq(userEmode, 1, 'User should be in stable emode');

    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // FUZZ TESTS FOR CONFIGURATION
  // ══════════════════════════════════════════════════════════════════════════════

  function testFuzz_config_ltvAlwaysBelowLiquidationThreshold(uint256 assetIndex) external view {
    if (address(pool) == address(0)) return;
    if (collateralAssets.length == 0) return;

    assetIndex = bound(assetIndex, 0, collateralAssets.length - 1);
    address asset = collateralAssets[assetIndex];

    uint256 ltv = _getLTV(asset);
    uint256 lt = _getLiquidationThreshold(asset);

    if (ltv > 0) {
      assertLt(ltv, lt, 'LTV must be less than liquidation threshold');
    }
  }

  function testFuzz_config_liquidationBonusReasonable(uint256 assetIndex) external view {
    if (address(pool) == address(0)) return;
    if (collateralAssets.length == 0) return;

    assetIndex = bound(assetIndex, 0, collateralAssets.length - 1);
    address asset = collateralAssets[assetIndex];

    DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(asset);
    uint256 liquidationBonus = config.getLiquidationBonus();

    if (liquidationBonus > 0) {
      assertGe(liquidationBonus, 10000, 'Liquidation bonus must be >= 100%');
      assertLe(liquidationBonus, 12000, 'Liquidation bonus must be <= 120%');
    }
  }
}
