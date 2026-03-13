// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {IAToken} from '../../../src/contracts/interfaces/IAToken.sol';
import {ReserveLogic, IERC20} from '../../../src/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from '../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {MathUtils} from '../../../src/contracts/protocol/libraries/math/MathUtils.sol';
import {TokenMath} from '../../../src/contracts/protocol/libraries/helpers/TokenMath.sol';
import {IScaledBalanceToken} from '../../../src/contracts/interfaces/IScaledBalanceToken.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

/**
 * @title Test: Double Treasury Accrual in Same-Asset Liquidation
 * @notice Demonstrates that when collateralAsset == debtAsset, updateState is called
 *         twice with two independently cached ReserveCache structs, causing
 *         _accrueToTreasury to double-count the interest for the treasury.
 */
contract PoolLiquidationDoubleTreasuryAccrualTest is TestnetProcedures {
  using stdStorage for StdStorage;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using PercentageMath for uint256;
  using WadRayMath for uint256;
  using TokenMath for uint256;

  function setUp() public {
    initTestEnvironment();

    // Carol provides deep liquidity so Alice can borrow
    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);
    contracts.poolProxy.supply(tokenList.weth, 100e18, carol, 0);
    vm.stopPrank();
  }

  /**
   * @notice Proves that same-asset liquidation double-counts treasury accrual.
   *
   * The test:
   *  1. Sets up a same-asset (USDX/USDX) position
   *  2. Warps time so interest accrues
   *  3. Snapshots the pre-liquidation reserve state
   *  4. Manually computes the CORRECT single _accrueToTreasury amount
   *  5. Executes the liquidation
   *  6. Asserts accruedToTreasury == singleAccrual (expected)
   *     → Fails because the contract stores 2 * singleAccrual
   */
  function test_sameAssetLiquidation_doublesTreasuryAccrual() public {
    // --- Setup: create an underwater same-asset position ---
    uint256 supplyAmount = 2000e6;
    uint256 borrowAmount = 1620e6;

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    // Warp 100 days to accrue meaningful interest
    vm.warp(block.timestamp + 100 days);

    // --- Snapshot reserve state BEFORE liquidation ---
    // At this point the reserve has NOT been updated this block yet.
    DataTypes.ReserveDataLegacy memory reserveDataBefore = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );

    uint256 currScaledVariableDebt = IScaledBalanceToken(reserveDataBefore.variableDebtTokenAddress)
      .scaledTotalSupply();

    uint256 currVariableBorrowIndex = reserveDataBefore.variableBorrowIndex;
    uint256 currLiquidityIndex = reserveDataBefore.liquidityIndex;
    uint256 reserveFactor = reserveDataBefore.configuration.getReserveFactor();
    uint256 accruedToTreasuryBefore = reserveDataBefore.accruedToTreasury;

    // --- Compute what a SINGLE _accrueToTreasury should produce ---
    // Replicate _updateIndexes to get nextVariableBorrowIndex and nextLiquidityIndex
    uint256 nextVariableBorrowIndex = currVariableBorrowIndex;
    if (currScaledVariableDebt != 0) {
      uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
        reserveDataBefore.currentVariableBorrowRate,
        reserveDataBefore.lastUpdateTimestamp
      );
      nextVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(currVariableBorrowIndex);
    }

    uint256 nextLiquidityIndex = currLiquidityIndex;
    if (reserveDataBefore.currentLiquidityRate != 0) {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
        reserveDataBefore.currentLiquidityRate,
        reserveDataBefore.lastUpdateTimestamp
      );
      nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(currLiquidityIndex);
    }

    // Replicate _accrueToTreasury (single call)
    uint256 expectedSingleAccrual = 0;
    if (reserveFactor != 0) {
      uint256 totalDebtAccrued = currScaledVariableDebt.rayMulFloor(
        nextVariableBorrowIndex - currVariableBorrowIndex
      );
      uint256 amountToMint = totalDebtAccrued.percentMul(reserveFactor);
      if (amountToMint != 0) {
        expectedSingleAccrual = amountToMint.getATokenMintScaledAmount(nextLiquidityIndex);
      }
    }

    // Sanity: the accrual should be non-zero for this test to be meaningful
    assertGt(expectedSingleAccrual, 0, 'Test precondition: expected non-zero treasury accrual');

    uint256 expectedTotalAccrued = accruedToTreasuryBefore + expectedSingleAccrual;

    // --- Make position liquidatable by warping even more ---
    // Actually we already warped 100 days above. The position should be underwater
    // due to interest accrual making debt > collateral. Let's verify and force it if needed.
    vm.warp(block.timestamp + 20000 days);

    // Re-snapshot after the larger warp since the _accrueToTreasury computation
    // happens at the time of the liquidation call, not at our earlier snapshot.
    // We need to recompute expected values at the actual liquidation time.
    reserveDataBefore = contracts.poolProxy.getReserveData(tokenList.usdx);
    currScaledVariableDebt = IScaledBalanceToken(reserveDataBefore.variableDebtTokenAddress)
      .scaledTotalSupply();
    currVariableBorrowIndex = reserveDataBefore.variableBorrowIndex;
    currLiquidityIndex = reserveDataBefore.liquidityIndex;
    reserveFactor = reserveDataBefore.configuration.getReserveFactor();
    accruedToTreasuryBefore = reserveDataBefore.accruedToTreasury;

    // Recompute indices at current block.timestamp
    nextVariableBorrowIndex = currVariableBorrowIndex;
    if (currScaledVariableDebt != 0) {
      nextVariableBorrowIndex = MathUtils
        .calculateCompoundedInterest(
          reserveDataBefore.currentVariableBorrowRate,
          reserveDataBefore.lastUpdateTimestamp
        )
        .rayMul(currVariableBorrowIndex);
    }
    nextLiquidityIndex = currLiquidityIndex;
    if (reserveDataBefore.currentLiquidityRate != 0) {
      nextLiquidityIndex = MathUtils
        .calculateLinearInterest(
          reserveDataBefore.currentLiquidityRate,
          reserveDataBefore.lastUpdateTimestamp
        )
        .rayMul(currLiquidityIndex);
    }

    // Single accrual computation
    expectedSingleAccrual = 0;
    if (reserveFactor != 0) {
      uint256 totalDebtAccrued = currScaledVariableDebt.rayMulFloor(
        nextVariableBorrowIndex - currVariableBorrowIndex
      );
      uint256 amountToMint = totalDebtAccrued.percentMul(reserveFactor);
      if (amountToMint != 0) {
        expectedSingleAccrual = amountToMint.getATokenMintScaledAmount(nextLiquidityIndex);
      }
    }

    assertGt(expectedSingleAccrual, 0, 'Test precondition: expected non-zero treasury accrual');
    expectedTotalAccrued = accruedToTreasuryBefore + expectedSingleAccrual;

    // --- Execute same-asset liquidation ---
    // Give bob enough to cover debt
    deal(tokenList.usdx, bob, type(uint128).max);
    vm.prank(bob);
    IERC20(tokenList.usdx).approve(address(contracts.poolProxy), type(uint256).max);

    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      tokenList.usdx, // collateralAsset
      tokenList.usdx, // debtAsset == collateralAsset
      alice,
      type(uint256).max,
      false // receiveAToken = false
    );

    // --- Verify accruedToTreasury ---
    uint256 accruedToTreasuryAfter = contracts
      .poolProxy
      .getReserveData(tokenList.usdx)
      .accruedToTreasury;

    // The correct value should be accruedToTreasuryBefore + expectedSingleAccrual.
    // Due to the double-updateState bug, the contract stores accruedToTreasuryBefore + 2 * expectedSingleAccrual.
    assertEq(
      accruedToTreasuryAfter,
      expectedTotalAccrued,
      'accruedToTreasury should reflect a single accrual, not double'
    );
  }

  /**
   * @notice Control test: different-asset liquidation does NOT double-count.
   * This proves the issue is specific to the same-asset case.
   */
  function test_differentAssetLiquidation_singleTreasuryAccrual() public {
    // Alice supplies WBTC as collateral, borrows USDX
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 20_000e6, 2, 0, alice);

    // Warp to accrue interest
    vm.warp(block.timestamp + 100 days);

    // Crash WBTC price to make position liquidatable
    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(tokenList.wbtc))
      .sig('_latestAnswer()')
      .checked_write(
        _calcPrice(IAaveOracle(report.aaveOracle).getAssetPrice(tokenList.wbtc), 40_00)
      );

    // Snapshot the DEBT reserve (USDX) state
    DataTypes.ReserveDataLegacy memory debtReserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    uint256 currScaledVariableDebt = IScaledBalanceToken(debtReserveData.variableDebtTokenAddress)
      .scaledTotalSupply();
    uint256 currVariableBorrowIndex = debtReserveData.variableBorrowIndex;
    uint256 currLiquidityIndex = debtReserveData.liquidityIndex;
    uint256 reserveFactor = debtReserveData.configuration.getReserveFactor();
    uint256 accruedToTreasuryBefore = debtReserveData.accruedToTreasury;

    // Compute expected single accrual for the DEBT reserve
    uint256 nextVariableBorrowIndex = currVariableBorrowIndex;
    if (currScaledVariableDebt != 0) {
      nextVariableBorrowIndex = MathUtils
        .calculateCompoundedInterest(
          debtReserveData.currentVariableBorrowRate,
          debtReserveData.lastUpdateTimestamp
        )
        .rayMul(currVariableBorrowIndex);
    }
    uint256 nextLiquidityIndex = currLiquidityIndex;
    if (debtReserveData.currentLiquidityRate != 0) {
      nextLiquidityIndex = MathUtils
        .calculateLinearInterest(
          debtReserveData.currentLiquidityRate,
          debtReserveData.lastUpdateTimestamp
        )
        .rayMul(currLiquidityIndex);
    }

    uint256 expectedSingleAccrual = 0;
    if (reserveFactor != 0) {
      uint256 totalDebtAccrued = currScaledVariableDebt.rayMulFloor(
        nextVariableBorrowIndex - currVariableBorrowIndex
      );
      uint256 amountToMint = totalDebtAccrued.percentMul(reserveFactor);
      if (amountToMint != 0) {
        expectedSingleAccrual = amountToMint.getATokenMintScaledAmount(nextLiquidityIndex);
      }
    }

    assertGt(expectedSingleAccrual, 0, 'Test precondition: expected non-zero treasury accrual');
    uint256 expectedTotalAccrued = accruedToTreasuryBefore + expectedSingleAccrual;

    // Execute different-asset liquidation
    deal(tokenList.usdx, bob, type(uint128).max);
    vm.prank(bob);
    IERC20(tokenList.usdx).approve(address(contracts.poolProxy), type(uint256).max);

    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      tokenList.wbtc, // collateralAsset (different from debt)
      tokenList.usdx, // debtAsset
      alice,
      type(uint256).max,
      false
    );

    // For different-asset liquidation, accruedToTreasury on the DEBT reserve should be correct
    uint256 accruedToTreasuryAfter = contracts
      .poolProxy
      .getReserveData(tokenList.usdx)
      .accruedToTreasury;

    assertEq(
      accruedToTreasuryAfter,
      expectedTotalAccrued,
      'Different-asset liquidation: accruedToTreasury should reflect single accrual'
    );
  }

  /**
   * @notice Proves that memory struct assignment is a reference, not a value copy.
   *         This means collateralReserveCache and debtReserveCache alias the same
   *         memory in the same-asset path (LiquidationLogic L181), so when
   *         _burnDebtTokens mutates debtReserveCache.nextScaledVariableDebt,
   *         collateralReserveCache sees the update automatically.
   *         The explicit sync at L372 is therefore a harmless no-op.
   */
  function test_memoryStructAssignment_isReferenceNotCopy() public pure {
    DataTypes.ReserveCache memory original;
    original.nextScaledVariableDebt = 100;
    original.nextLiquidityIndex = 1e27;

    DataTypes.ReserveCache memory alias_ = original;

    // Mutate original (simulates what _burnDebtTokens does to debtReserveCache)
    original.nextScaledVariableDebt = 50;

    // Alias sees the mutation — they share the same memory
    assertEq(alias_.nextScaledVariableDebt, 50, 'memory struct assignment must be a reference');
    assertEq(alias_.nextLiquidityIndex, 1e27);
  }
}
