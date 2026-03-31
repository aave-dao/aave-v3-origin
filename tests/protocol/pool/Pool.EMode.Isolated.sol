// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {IPool, DataTypes} from '../../../src/contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from '../../../src/contracts/interfaces/IPoolConfigurator.sol';
import {PoolInstance} from '../../../src/contracts/instances/PoolInstance.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {EModeConfiguration} from '../../../src/contracts/protocol/libraries/configuration/EModeConfiguration.sol';
import {UserConfiguration} from '../../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {PercentageMath} from '../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract PoolEModeIsolatedTests is TestnetProcedures {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using PercentageMath for uint256;

  IPool internal pool;

  // EMode 1: non-isolated (GROUP_A) with usdx as collateral
  // EMode 3: isolated with usdx+wbtc as collateral, usdx as borrowable
  uint8 constant EMODE_ISOLATED = 3;

  function setUp() public virtual {
    initTestEnvironment(true);
    pool = PoolInstance(report.poolProxy);

    vm.startPrank(poolAdmin);

    // Setup eMode 1 (non-isolated) with usdx as collateral and borrowable
    EModeCategoryInput memory ct1 = _genCategoryOne();
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct1.id,
      ct1.ltv,
      ct1.lt,
      ct1.lb,
      ct1.label,
      ct1.isolated
    );
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.usdx, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, ct1.id, true);

    // Setup eMode 3 (isolated) with usdx+wbtc as collateral, usdx as borrowable
    contracts.poolConfiguratorProxy.setEModeCategory(
      EMODE_ISOLATED,
      95_00,
      96_00,
      101_00,
      'ISOLATED_GROUP',
      true
    );
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, EMODE_ISOLATED, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, EMODE_ISOLATED, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.usdx, EMODE_ISOLATED, true);

    vm.stopPrank();
  }

  function test_isolatedEmode_cannotEnterWithNonEmodeCollateral() public {
    // Alice supplies and enables weth (non-emode) as collateral
    _supplyAndEnableAsCollateral(tokenList.weth, 1 ether, alice);

    // Trying to enter isolated eMode 3 should revert because weth is not in collateralBitmap
    vm.expectRevert(
      abi.encodeWithSelector(
        Errors.InvalidCollateralInEmode.selector,
        tokenList.weth,
        EMODE_ISOLATED
      )
    );
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);
  }

  function test_isolatedEmode_canEnterWithOnlyEmodeCollateral() public {
    // Alice supplies and enables usdx (in emode collateralBitmap) as collateral
    _supplyAndEnableAsCollateral(tokenList.usdx, 1000e6, alice);

    // Entering isolated eMode 3 should succeed
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);
    assertEq(pool.getUserEMode(alice), EMODE_ISOLATED);
  }

  function test_isolatedEmode_canEnterWithNoCollateral() public {
    // Alice has no positions, entering isolated eMode should succeed (isEmpty early return)
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);
    assertEq(pool.getUserEMode(alice), EMODE_ISOLATED);
  }

  function test_isolatedEmode_cannotEnableNonEmodeCollateral() public {
    // Alice enters isolated eMode 3 first
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Alice supplies weth
    vm.startPrank(alice);
    pool.supply(tokenList.weth, 1 ether, alice, 0);

    // Trying to enable weth as collateral should revert (LTV=0 for non-emode asset in isolated emode)
    vm.expectRevert(abi.encodeWithSelector(Errors.UserHasAssetWithZeroLtv.selector));
    pool.setUserUseReserveAsCollateral(tokenList.weth, true);
    vm.stopPrank();
  }

  function test_isolatedEmode_supplyDoesNotAutoEnableNonEmodeCollateral() public {
    // Alice enters isolated eMode 3 first
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Alice first-time supplies weth - should NOT be auto-enabled as collateral
    vm.prank(alice);
    pool.supply(tokenList.weth, 1 ether, alice, 0);

    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(alice);
    DataTypes.ReserveDataLegacy memory wethData = pool.getReserveData(tokenList.weth);
    assertFalse(userConfig.isUsingAsCollateral(wethData.id));
  }

  function test_isolatedEmode_canEnableEmodeCollateral() public {
    // Alice enters isolated eMode 3 first
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Alice supplies and enables usdx as collateral - should succeed
    _supplyAndEnableAsCollateral(tokenList.usdx, 1000e6, alice);

    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(alice);
    DataTypes.ReserveDataLegacy memory usdxData = pool.getReserveData(tokenList.usdx);
    assertTrue(userConfig.isUsingAsCollateral(usdxData.id));
  }

  function test_isolatedEmode_adminToggle_existingUsersGetLtv0() public {
    // Alice enters non-isolated eMode 1 and has usdx (emode) + weth (non-emode) collateral
    _supplyAndEnableAsCollateral(tokenList.usdx, 1000e6, alice);
    _supplyAndEnableAsCollateral(tokenList.weth, 1 ether, alice);

    vm.prank(alice);
    pool.setUserEMode(1);

    // Get baseline account data
    (uint256 totalCollateralBefore, , , , uint256 ltvBefore, ) = pool.getUserAccountData(alice);
    assertGt(ltvBefore, 0, 'LTV should be > 0 before admin toggle');
    assertGt(totalCollateralBefore, 0, 'Collateral should be > 0');

    // Admin changes eMode 1 to isolated
    EModeCategoryInput memory ct1 = _genCategoryOne();
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct1.id,
      ct1.ltv,
      ct1.lt,
      ct1.lb,
      ct1.label,
      true
    );

    // Verify: weth now contributes 0 LTV, so overall LTV should drop
    (, , , , uint256 ltvAfter, uint256 hfAfter) = pool.getUserAccountData(alice);
    assertLt(ltvAfter, ltvBefore, 'LTV should decrease after admin enables isolated');
    // Position should not be liquidated (HF should still be >= 1 since there's no debt)
    assertGe(hfAfter, 1e18, 'HF should still be healthy');
  }

  function test_isolatedEmode_canExitToEmode0() public {
    // Alice enters isolated eMode 3 with only emode collateral
    _supplyAndEnableAsCollateral(tokenList.usdx, 1000e6, alice);

    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);
    assertEq(pool.getUserEMode(alice), EMODE_ISOLATED);

    // Can exit to eMode 0
    vm.prank(alice);
    pool.setUserEMode(0);
    assertEq(pool.getUserEMode(alice), 0);
  }

  function test_isolatedEmode_nonIsolatedUnaffected() public {
    // EMode 1 is non-isolated, should allow non-emode collateral
    _supplyAndEnableAsCollateral(tokenList.weth, 1 ether, alice);

    // weth is not in eMode 1's collateralBitmap, but since eMode 1 is not isolated, entry should succeed
    // (weth will just use its base LTV, not emode LTV)
    vm.prank(alice);
    pool.setUserEMode(1);
    assertEq(pool.getUserEMode(alice), 1);
  }

  function test_isolatedEmode_getterReturnsCorrectValue() public view {
    assertTrue(pool.getIsEModeCategoryIsolated(EMODE_ISOLATED));
    assertFalse(pool.getIsEModeCategoryIsolated(1));
  }

  function test_isolatedEmode_ltvzeroBitmapStillWorks() public {
    // Create an isolated eMode with ltvzero for an emode asset
    vm.startPrank(poolAdmin);

    // Set usdx as ltvzero in eMode 3
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, EMODE_ISOLATED, true);

    vm.stopPrank();

    // Alice supplies and enables usdx as collateral
    _supplyAndEnableAsCollateral(tokenList.usdx, 1000e6, alice);

    // Alice cannot enter eMode 3 because usdx is ltvzero (LTV=0 blocks entry)
    vm.expectRevert(
      abi.encodeWithSelector(
        Errors.InvalidCollateralInEmode.selector,
        tokenList.usdx,
        EMODE_ISOLATED
      )
    );
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Also, weth is not in collateralBitmap (isolated blocks it too)
    _supplyAndEnableAsCollateral(tokenList.weth, 1 ether, bob);
    vm.expectRevert(
      abi.encodeWithSelector(
        Errors.InvalidCollateralInEmode.selector,
        tokenList.weth,
        EMODE_ISOLATED
      )
    );
    vm.prank(bob);
    pool.setUserEMode(EMODE_ISOLATED);
  }

  function test_isolatedEmode_canBorrowWithOnlyEmodeCollateral() public {
    // Alice enters isolated eMode and supplies emode collateral
    _supplyAndEnableAsCollateral(tokenList.usdx, 10_000e6, alice);

    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Bob supplies usdx for liquidity
    _supply(tokenList.usdx, 10_000e6, bob);

    // Alice borrows usdx successfully (usdx is borrowable in eMode 3)
    vm.prank(alice);
    pool.borrow(tokenList.usdx, 100e6, 2, 0, alice);
  }

  function test_isolatedEmode_supplyAutoEnablesBitmapCollateral() public {
    // Alice enters isolated eMode 3 first (no positions)
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Alice first-time supplies usdx (which IS in the eMode collateralBitmap)
    // It should be auto-enabled as collateral since validateUseAsCollateral returns true for bitmap assets
    vm.startPrank(alice);
    deal(tokenList.usdx, alice, 1000e6);
    IERC20(tokenList.usdx).approve(address(pool), 1000e6);
    pool.supply(tokenList.usdx, 1000e6, alice, 0);
    vm.stopPrank();

    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(alice);
    DataTypes.ReserveDataLegacy memory usdxData = pool.getReserveData(tokenList.usdx);
    assertTrue(
      userConfig.isUsingAsCollateral(usdxData.id),
      'Bitmap asset should be auto-enabled as collateral on first supply in isolated eMode'
    );
  }

  function test_isolatedEmode_switchBetweenIsolatedEmodes() public {
    // Create eMode 4 (isolated) with ONLY wbtc as collateral (different bitmap from eMode 3)
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      4,
      93_00,
      94_00,
      101_00,
      'ISOLATED_GROUP_B',
      true
    );
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, 4, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.usdx, 4, true);
    vm.stopPrank();

    // Alice supplies both usdx and wbtc, enables both as collateral
    _supplyAndEnableAsCollateral(tokenList.usdx, 1000e6, alice);
    _supplyAndEnableAsCollateral(tokenList.wbtc, 1e8, alice);

    // Alice enters isolated eMode 3 (usdx+wbtc in bitmap) — should succeed
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);
    assertEq(pool.getUserEMode(alice), EMODE_ISOLATED);

    // Switching to isolated eMode 4 (only wbtc in bitmap) should REVERT
    // because usdx is enabled as collateral but NOT in eMode 4's bitmap
    vm.expectRevert(
      abi.encodeWithSelector(Errors.InvalidCollateralInEmode.selector, tokenList.usdx, 4)
    );
    vm.prank(alice);
    pool.setUserEMode(4);

    // Alice disables usdx as collateral, then switching should succeed
    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, false);

    vm.prank(alice);
    pool.setUserEMode(4);
    assertEq(pool.getUserEMode(alice), 4);

    // Verify: in eMode 4, usdx (not in bitmap) has LTV=0 and wbtc (in bitmap) has eMode LTV
    (, , , , uint256 ltv, ) = pool.getUserAccountData(alice);
    // LTV should reflect only wbtc's eMode 4 LTV (93_00) since usdx collateral is disabled
    assertEq(ltv, 93_00, 'LTV should equal eMode 4 LTV with only wbtc collateral');
  }

  function test_isolatedEmode_disabledNonEmodeCollateralAllowsEntry() public {
    // Alice supplies weth but does NOT enable it as collateral
    vm.prank(alice);
    pool.supply(tokenList.weth, 1 ether, alice, 0);

    // Check that weth is not used as collateral
    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(alice);
    DataTypes.ReserveDataLegacy memory wethData = pool.getReserveData(tokenList.weth);
    // In some cases first-time supply auto-enables collateral, so explicitly disable if needed
    if (userConfig.isUsingAsCollateral(wethData.id)) {
      vm.prank(alice);
      pool.setUserUseReserveAsCollateral(tokenList.weth, false);
    }

    // Alice can enter isolated eMode because weth is not enabled as collateral (only enabled collateral matters)
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);
    assertEq(pool.getUserEMode(alice), EMODE_ISOLATED);
  }
}
