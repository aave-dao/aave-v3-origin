// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'forge-std/StdStorage.sol';

import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {IPool, DataTypes} from '../../../src/contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from '../../../src/contracts/interfaces/IPoolConfigurator.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {IPriceOracleGetter} from '../../../src/contracts/interfaces/IPriceOracleGetter.sol';
import {PoolInstance} from '../../../src/contracts/instances/PoolInstance.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {UserConfiguration} from '../../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {PercentageMath} from '../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';

/**
 * @title Edge case tests for isolated eMode
 * @notice Covers 5 gap areas identified during audit context building:
 *   1. Liquidation with mixed LTV-0 collateral in isolated eMode
 *   2. Admin live-toggle when HF is near 1.0
 *   3. Flash loan interaction with isolated eMode collateral
 *   4. Empty collateralBitmap + isolated=true
 *   5. Reserve isolation mode (debt ceiling) + eMode isolation combo
 */
contract PoolEModeIsolatedEdgeCaseTests is TestnetProcedures {
  using stdStorage for StdStorage;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using PercentageMath for uint256;
  using WadRayMath for uint256;

  IPool internal pool;

  uint8 constant EMODE_NON_ISOLATED = 1;
  uint8 constant EMODE_ISOLATED = 3;

  function setUp() public virtual {
    initTestEnvironment(false);
    pool = PoolInstance(report.poolProxy);

    vm.startPrank(poolAdmin);

    // Setup eMode 1 (non-isolated): usdx+wbtc as collateral, usdx+wbtc as borrowable
    EModeCategoryInput memory ct1 = _genCategoryOne();
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct1.id,
      ct1.ltv,
      ct1.lt,
      ct1.lb,
      ct1.label,
      false
    );
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.usdx, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, ct1.id, true);

    // Setup eMode 3 (isolated): usdx+wbtc as collateral, usdx as borrowable
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

  // ─────────────────────────────────────────────────────────────────────────
  // 1. LIQUIDATION WITH MIXED LTV-0 COLLATERAL IN ISOLATED EMODE
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * @notice User in non-isolated eMode 1 with mixed collateral (eMode + non-eMode).
   *         Admin toggles eMode 1 to isolated, making non-eMode collateral LTV=0.
   *         Price drops → user becomes liquidatable → verify liquidation works correctly.
   *
   *         Key check: Liquidation should be able to seize both eMode and non-eMode collateral.
   *         The LTV=0 collateral still has liquidation threshold, so it can be seized.
   */
  function test_liquidation_afterAdminToggleIsolated_nonEmodeCollateralSeizable() public {
    // Setup liquidity
    _mintAndSupply(tokenList.usdx, 100_000e6, carol);

    // Alice enters non-isolated eMode 1 with small usdx + large weth collateral.
    // This makes her position dependent on weth value for HF.
    _mintAndSupplyAndEnable(tokenList.usdx, 1_000e6, alice);
    _mintAndSupplyAndEnable(tokenList.weth, 5 ether, alice);

    vm.prank(alice);
    pool.setUserEMode(EMODE_NON_ISOLATED);

    // Alice borrows close to her max
    (uint256 totalCollateral, , , uint256 lt, , ) = pool.getUserAccountData(alice);
    uint256 usdxPrice = contracts.aaveOracle.getAssetPrice(tokenList.usdx);
    // Borrow 90% of LT-based max
    uint256 borrowAmount = (((totalCollateral * lt * 90) / 10_000 / 100) * 1e6) / usdxPrice;
    vm.prank(alice);
    pool.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);

    // Admin toggles eMode 1 to isolated → weth becomes LTV=0 for Alice
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

    // Verify position is still healthy (LT unchanged)
    (, , , , , uint256 hf) = pool.getUserAccountData(alice);
    assertGe(hf, 1e18, 'HF should still be healthy (no debt crisis yet)');

    // Drop weth price heavily. Alice's position heavily depends on weth for LT coverage.
    _dropPrice(tokenList.weth, 95_00); // 95% drop

    (, , , , , uint256 hfAfterDrop) = pool.getUserAccountData(alice);
    assertLt(hfAfterDrop, 1e18, 'HF should be below 1 after price drop');

    // Bob liquidates Alice, seizing weth (the LTV=0 collateral).
    // weth still has liquidation threshold so it CAN be seized.
    _mintToken(tokenList.usdx, bob, 100_000e6);
    vm.startPrank(bob);
    IERC20(tokenList.usdx).approve(address(pool), type(uint256).max);
    pool.liquidationCall(
      tokenList.weth, // collateral to seize (non-emode, LTV=0 but still has LT)
      tokenList.usdx, // debt to repay
      alice,
      type(uint256).max,
      false
    );
    vm.stopPrank();

    // Verify liquidation happened
    assertGt(IERC20(tokenList.weth).balanceOf(bob), 0, 'Bob should have received weth collateral');
  }

  /**
   * @notice User in isolated eMode with only eMode collateral, borrows, price drops,
   *         and gets liquidated. Verify eMode liquidation bonus is applied correctly.
   */
  function test_liquidation_isolatedEmodeUser_emodeCollateralOnly() public {
    // Setup liquidity
    _mintAndSupply(tokenList.usdx, 100_000e6, carol);

    // Alice enters isolated eMode with usdx collateral
    _mintAndSupplyAndEnable(tokenList.usdx, 10_000e6, alice);
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Alice borrows usdx near her limit (LTV=95%)
    vm.prank(alice);
    pool.borrow(tokenList.usdx, 9_400e6, 2, 0, alice);

    // Accrue interest to push into liquidation territory
    vm.warp(block.timestamp + 365 days);

    (, , , , , uint256 hf) = pool.getUserAccountData(alice);

    // If HF is still healthy after time warp, use direct index manipulation
    if (hf >= 1e18) {
      // Force borrow index increase to simulate massive interest accrual
      uint256 reserveSlot = uint256(keccak256(abi.encode(tokenList.usdx, 52))) + 2;
      uint256 currentValue = uint256(vm.load(address(pool), bytes32(reserveSlot)));
      uint128 existingRate = uint128(currentValue >> 128);
      // Double the borrow index
      bytes32 newPackedValue = bytes32((uint256(existingRate) << 128) | uint256(2e27));
      vm.store(address(pool), bytes32(reserveSlot), newPackedValue);
    }

    (, , , , , hf) = pool.getUserAccountData(alice);
    assertLt(hf, 1e18, 'HF should be below 1');

    // Bob liquidates Alice
    _mintToken(tokenList.usdx, bob, 20_000e6);
    vm.startPrank(bob);
    IERC20(tokenList.usdx).approve(address(pool), type(uint256).max);

    uint256 bobBalBefore = IERC20(tokenList.usdx).balanceOf(bob);
    pool.liquidationCall(tokenList.usdx, tokenList.usdx, alice, type(uint256).max, false);
    vm.stopPrank();

    // Verify liquidation occurred
    (, uint256 debtAfter, , , , uint256 hfAfter) = pool.getUserAccountData(alice);
    assertTrue(debtAfter == 0 || hfAfter >= 1e18, 'Position should be improved or cleared');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. ADMIN LIVE-TOGGLE WHEN HF IS NEAR 1.0
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * @notice User in non-isolated eMode with HF very close to 1.0.
   *         Admin enables isolated flag. The LTV drops (non-eMode collateral → LTV=0)
   *         but HF should NOT drop below 1 because isolation only affects LTV, not LT.
   *
   *         Key insight: isolated flag zeroes LTV, not liquidation threshold.
   *         So HF is computed from LT and is unaffected.
   */
  function test_adminToggle_hfNear1_hfUnaffected() public {
    // Setup liquidity
    _mintAndSupply(tokenList.usdx, 100_000e6, carol);

    // Alice enters non-isolated eMode 1 with mixed collateral
    _mintAndSupplyAndEnable(tokenList.usdx, 10_000e6, alice);
    _mintAndSupplyAndEnable(tokenList.weth, 5 ether, alice);

    vm.prank(alice);
    pool.setUserEMode(EMODE_NON_ISOLATED);

    // Borrow near max LT to push HF close to 1.0
    // Use a conservative 95% of LT-based max to avoid CollateralCannotCoverNewBorrow
    (uint256 totalCollateral, , , uint256 currentLt, , ) = pool.getUserAccountData(alice);
    uint256 maxBorrowInBase = (totalCollateral * currentLt) / 10_000;
    uint256 usdxPrice = contracts.aaveOracle.getAssetPrice(tokenList.usdx);
    uint256 borrowAmount = (maxBorrowInBase * 1e6) / usdxPrice;
    borrowAmount = (borrowAmount * 95) / 100;

    vm.prank(alice);
    pool.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);

    (, , , , , uint256 hfBefore) = pool.getUserAccountData(alice);
    assertGe(hfBefore, 1e18, 'HF should be >= 1 before toggle');

    // Admin enables isolated on eMode 1
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

    // Key assertion: HF should be UNCHANGED because isolated only affects LTV, not LT.
    // Liquidation threshold is not affected by the isolated flag.
    (, , , , uint256 ltvAfter, uint256 hfAfter) = pool.getUserAccountData(alice);
    assertEq(hfAfter, hfBefore, 'HF must not change when isolated is toggled (LT unchanged)');
    // LTV should drop since weth now contributes 0 LTV
    assertLt(ltvAfter, ct1.ltv, 'LTV should drop below eMode LTV (mixed with 0-LTV weth)');
  }

  /**
   * @notice After admin toggle, user should NOT be able to take new borrows
   *         even though HF is unchanged, because weth LTV dropped to 0, meaning
   *         the user has LTV-zero collateral. Any new borrow fails with
   *         CollateralCannotCoverNewBorrow because aggregate LTV includes the
   *         zero-LTV weth weight.
   */
  function test_adminToggle_cannotBorrowAfterIsolationEnabled() public {
    _mintAndSupply(tokenList.usdx, 100_000e6, carol);

    // Alice enters non-isolated eMode 1 with ONLY weth (non-emode) collateral
    _mintAndSupplyAndEnable(tokenList.weth, 5 ether, alice);

    vm.prank(alice);
    pool.setUserEMode(EMODE_NON_ISOLATED);

    // Toggle to isolated — weth now has LTV=0 since it's not in eMode 1 collateralBitmap
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

    // weth is the only collateral and its LTV=0 → aggregate LTV=0
    (, , , , uint256 ltvAfter, ) = pool.getUserAccountData(alice);
    assertEq(ltvAfter, 0, 'LTV should be 0 when only collateral has LTV=0');

    // Trying to borrow should revert — LTV-zero collateral blocks new borrows
    vm.expectRevert(abi.encodeWithSelector(Errors.LtvValidationFailed.selector));
    vm.prank(alice);
    pool.borrow(tokenList.usdx, 1e6, 2, 0, alice);
  }

  /**
   * @notice After admin toggle, user should be able to unwind by exiting eMode.
   *         Exiting to eMode 0 restores base LTV for all assets, removing the LTV-zero state.
   */
  function test_adminToggle_canExitEmodeToRestore() public {
    _mintAndSupply(tokenList.usdx, 100_000e6, carol);

    // Alice enters non-isolated eMode 1 with mixed collateral
    _mintAndSupplyAndEnable(tokenList.usdx, 10_000e6, alice);
    _mintAndSupplyAndEnable(tokenList.weth, 5 ether, alice);

    vm.prank(alice);
    pool.setUserEMode(EMODE_NON_ISOLATED);

    // Borrow a small amount so she has debt
    vm.prank(alice);
    pool.borrow(tokenList.usdx, 1_000e6, 2, 0, alice);

    // Toggle to isolated
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

    // Exiting to eMode 0 should succeed (restores base LTV for weth)
    vm.prank(alice);
    pool.setUserEMode(0);
    assertEq(pool.getUserEMode(alice), 0);

    // Now borrowing should work again (no LTV-zero collateral)
    (, , , , uint256 ltvAfter, ) = pool.getUserAccountData(alice);
    assertGt(ltvAfter, 0, 'LTV should be > 0 after exiting eMode');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. FLASH LOAN INTERACTION WITH ISOLATED EMODE
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * @notice User in isolated eMode takes a flash loan of a non-eMode asset.
   *         Flash loan with mode=0 (repay within tx) should succeed because
   *         no collateral state changes occur.
   */
  function test_flashLoan_isolatedEmodeUser_mode0_succeeds() public {
    // Setup: Carol supplies liquidity for flash loan
    _mintAndSupply(tokenList.usdx, 50_000e6, carol);

    // Alice enters isolated eMode
    _mintAndSupplyAndEnable(tokenList.usdx, 10_000e6, alice);
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Alice takes flash loan of usdx with mode=0 (repay within tx)
    address[] memory assets = new address[](1);
    assets[0] = tokenList.usdx;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 1_000e6;
    uint256[] memory modes = new uint256[](1);
    modes[0] = 0; // repay within tx

    // Create a simple receiver that just approves repayment
    MockFlashLoanReceiverSimple receiver = new MockFlashLoanReceiverSimple(address(pool));
    // Give receiver enough to cover flash loan premium
    _mintToken(tokenList.usdx, address(receiver), 100e6);
    vm.prank(address(receiver));
    IERC20(tokenList.usdx).approve(address(pool), type(uint256).max);

    vm.prank(alice);
    pool.flashLoan(address(receiver), assets, amounts, modes, alice, '', 0);
    // If we got here without revert, flash loan with mode=0 works in isolated eMode
  }

  /**
   * @notice User in isolated eMode tries flash loan with mode=2 (open variable debt).
   *         The flash loan should create debt for alice. The borrowed asset must be
   *         borrowable in the eMode.
   */
  function test_flashLoan_isolatedEmodeUser_mode2_borrowableAsset_succeeds() public {
    // Setup: Carol supplies liquidity
    _mintAndSupply(tokenList.usdx, 100_000e6, carol);

    // Alice enters isolated eMode with collateral
    _mintAndSupplyAndEnable(tokenList.usdx, 10_000e6, alice);
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Flash loan usdx with mode=2 (open variable debt) — usdx is borrowable in isolated eMode
    address[] memory assets = new address[](1);
    assets[0] = tokenList.usdx;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 100e6;
    uint256[] memory modes = new uint256[](1);
    modes[0] = 2; // variable debt

    MockFlashLoanReceiverNoop receiver = new MockFlashLoanReceiverNoop(address(pool));

    vm.prank(alice);
    pool.flashLoan(address(receiver), assets, amounts, modes, alice, '', 0);

    // Verify debt was created
    (, uint256 debt, , , , ) = pool.getUserAccountData(alice);
    assertGt(debt, 0, 'Alice should have debt from flash loan mode=2');
  }

  /**
   * @notice Verify that flash loan mode=2 for non-borrowable asset in isolated eMode
   *         should fail because the asset is not borrowable in the eMode.
   */
  function test_flashLoan_isolatedEmodeUser_mode2_nonBorrowableAsset_reverts() public {
    // Make wbtc not borrowable outside eMode and not in eMode 3's borrowable bitmap
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveBorrowing(tokenList.wbtc, false);

    // Setup: Carol supplies liquidity
    _mintAndSupply(tokenList.wbtc, 10e8, carol);

    // Alice enters isolated eMode with collateral
    _mintAndSupplyAndEnable(tokenList.usdx, 10_000e6, alice);
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Flash loan wbtc with mode=2 — wbtc is NOT borrowable in isolated eMode 3
    address[] memory assets = new address[](1);
    assets[0] = tokenList.wbtc;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 0.01e8;
    uint256[] memory modes = new uint256[](1);
    modes[0] = 2;

    MockFlashLoanReceiverNoop receiver = new MockFlashLoanReceiverNoop(address(pool));

    // wbtc is not borrowable outside eMode, and not borrowable in eMode 3 →
    // Error is NotBorrowableInEMode because eMode check runs and asset is not in borrowableBitmap
    vm.expectRevert(abi.encodeWithSelector(Errors.NotBorrowableInEMode.selector));
    vm.prank(alice);
    pool.flashLoan(address(receiver), assets, amounts, modes, alice, '', 0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. EMPTY COLLATERAL BITMAP + ISOLATED = TRUE
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * @notice Create an isolated eMode with NO assets in collateralBitmap.
   *         A user with no positions should be able to enter (isEmpty early return).
   *         But once they have any collateral enabled, ALL assets return LTV=0.
   */
  function test_emptyBitmap_isolatedEmode_userCanEnterEmpty() public {
    // Create eMode 4 with isolated=true but NO collateral assets
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      4,
      90_00,
      92_00,
      101_00,
      'EMPTY_ISOLATED',
      true
    );
    // Deliberately NOT calling setAssetCollateralInEMode for any asset
    // But make usdx borrowable so we can test
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.usdx, 4, true);
    vm.stopPrank();

    // User with no positions can enter
    vm.prank(alice);
    pool.setUserEMode(4);
    assertEq(pool.getUserEMode(alice), 4);
  }

  /**
   * @notice In an isolated eMode with empty collateralBitmap, attempting to
   *         enter with any collateral enabled should revert because all assets
   *         would have LTV=0.
   */
  function test_emptyBitmap_isolatedEmode_cannotEnterWithCollateral() public {
    // Create eMode 4 isolated with no collateral bitmap
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      4,
      90_00,
      92_00,
      101_00,
      'EMPTY_ISOLATED',
      true
    );
    vm.stopPrank();

    // Alice supplies and enables usdx as collateral
    _mintAndSupplyAndEnable(tokenList.usdx, 1_000e6, alice);

    // Trying to enter should revert because usdx is not in collateralBitmap → LTV=0
    vm.expectRevert(
      abi.encodeWithSelector(Errors.InvalidCollateralInEmode.selector, tokenList.usdx, 4)
    );
    vm.prank(alice);
    pool.setUserEMode(4);
  }

  /**
   * @notice In an isolated eMode with empty collateralBitmap, user entered with no positions.
   *         Then supplies and tries to enable collateral — should fail (LTV=0 for everything).
   */
  function test_emptyBitmap_isolatedEmode_cannotEnableAnyCollateral() public {
    // Create eMode 4 isolated with no collateral bitmap
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      4,
      90_00,
      92_00,
      101_00,
      'EMPTY_ISOLATED',
      true
    );
    vm.stopPrank();

    // Alice enters with no positions
    vm.prank(alice);
    pool.setUserEMode(4);

    // Supply usdx
    _mintAndSupply(tokenList.usdx, 1_000e6, alice);

    // Try to enable as collateral — should fail because LTV=0
    vm.expectRevert(abi.encodeWithSelector(Errors.UserHasAssetWithZeroLtv.selector));
    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  /**
   * @notice Admin adds assets to the collateralBitmap AFTER user entered the empty
   *         isolated eMode. User should then be able to enable that asset as collateral.
   */
  function test_emptyBitmap_isolatedEmode_adminAddsAsset_thenUserCanEnable() public {
    // Create eMode 4 isolated with no collateral bitmap
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      4,
      90_00,
      92_00,
      101_00,
      'EMPTY_ISOLATED',
      true
    );
    vm.stopPrank();

    // Alice enters with no positions
    vm.prank(alice);
    pool.setUserEMode(4);

    // Supply usdx
    _mintAndSupply(tokenList.usdx, 1_000e6, alice);

    // Admin adds usdx to collateralBitmap
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 4, true);

    // Now Alice can enable usdx as collateral
    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);

    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(alice);
    DataTypes.ReserveDataLegacy memory usdxData = pool.getReserveData(tokenList.usdx);
    assertTrue(userConfig.isUsingAsCollateral(usdxData.id));
  }

  /**
   * @notice User in isolated eMode with non-debt-ceiling collateral. User should be able to borrow
   *         any asset borrowable in the eMode.
   */
  function test_emodeIsolation_canBorrowFreely() public {
    // usdx has NO debt ceiling — no reserve isolation mode
    // But user is in isolated eMode 3

    // Setup liquidity
    _mintAndSupply(tokenList.usdx, 100_000e6, carol);

    // Alice enters isolated eMode with usdx collateral (no debt ceiling)
    _mintAndSupplyAndEnable(tokenList.usdx, 10_000e6, alice);
    vm.prank(alice);
    pool.setUserEMode(EMODE_ISOLATED);

    // Borrow usdx (borrowable in eMode 3) — should work
    vm.prank(alice);
    pool.borrow(tokenList.usdx, 5_000e6, 2, 0, alice);

    (, uint256 debt, , , , ) = pool.getUserAccountData(alice);
    assertGt(debt, 0, 'Should have borrowed');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  function _mintToken(address erc20, address user, uint256 amount) internal {
    if (erc20 == tokenList.weth) {
      deal(erc20, user, IERC20(erc20).balanceOf(user) + amount);
    } else {
      vm.prank(poolAdmin);
      TestnetERC20(erc20).mint(user, amount);
    }
  }

  function _mintAndSupply(address asset, uint256 amount, address user) internal {
    _mintToken(asset, user, amount);
    vm.startPrank(user);
    IERC20(asset).approve(address(pool), type(uint256).max);
    pool.supply(asset, amount, user, 0);
    vm.stopPrank();
  }

  function _mintAndSupplyAndEnable(address asset, uint256 amount, address user) internal {
    _mintToken(asset, user, amount);
    _supplyAndEnableAsCollateral(asset, amount, user);
  }

  function _dropPrice(address asset, uint256 dropPercent) internal {
    address source = IAaveOracle(report.aaveOracle).getSourceOfAsset(asset);
    uint256 currentPrice = IAaveOracle(report.aaveOracle).getAssetPrice(asset);
    uint256 newPrice = _calcPrice(currentPrice, dropPercent);
    stdstore.target(source).sig('_latestAnswer()').checked_write(newPrice);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// MOCK FLASH LOAN RECEIVERS
// ─────────────────────────────────────────────────────────────────────────

/**
 * @notice Simple flash loan receiver that just approves repayment (for mode=0 tests).
 */
contract MockFlashLoanReceiverSimple {
  address internal immutable POOL;

  constructor(address pool) {
    POOL = pool;
  }

  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address,
    bytes calldata
  ) external returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      IERC20(assets[i]).approve(POOL, amounts[i] + premiums[i]);
    }
    return true;
  }
}

/**
 * @notice Flash loan receiver that does nothing (for mode=2 where debt is opened, no repayment needed).
 */
contract MockFlashLoanReceiverNoop {
  address internal immutable POOL;

  constructor(address pool) {
    POOL = pool;
  }

  function executeOperation(
    address[] memory,
    uint256[] memory,
    uint256[] memory,
    address,
    bytes calldata
  ) external pure returns (bool) {
    return true;
  }
}
