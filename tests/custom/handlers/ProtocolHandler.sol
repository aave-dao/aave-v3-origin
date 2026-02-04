// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console2} from 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {JUBCToken} from 'custom/jubc/JUBCToken.sol';

/**
 * @title ProtocolHandler
 * @notice Handler contract for invariant testing that performs bounded random actions
 * @dev Used by Foundry's invariant testing to explore protocol state space
 *
 * ACTIONS:
 * - deposit: Supply collateral to the pool
 * - borrow: Borrow jpyUBI against collateral
 * - repay: Repay jpyUBI debt
 * - withdraw: Withdraw collateral from pool
 * - liquidate: Liquidate undercollateralized positions
 * - warpTime: Advance time to accrue interest
 */
contract ProtocolHandler is Test {
  // ══════════════════════════════════════════════════════════════════════════════
  // STATE
  // ══════════════════════════════════════════════════════════════════════════════

  IPool public pool;
  JUBCToken public jpyUbi;
  IAaveOracle public oracle;
  address[] public collateralAssets;
  address[] public actors;

  // Ghost variables for tracking invariants
  uint256 public ghost_totalDeposits;
  uint256 public ghost_totalBorrows;
  uint256 public ghost_totalRepays;
  uint256 public ghost_totalWithdraws;
  uint256 public ghost_totalLiquidations;

  mapping(bytes32 => uint256) public calls;

  // ══════════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ══════════════════════════════════════════════════════════════════════════════

  constructor(
    IPool _pool,
    JUBCToken _jpyUbi,
    IAaveOracle _oracle,
    address[] memory _collateralAssets,
    address[] memory _actors
  ) {
    pool = _pool;
    jpyUbi = _jpyUbi;
    oracle = _oracle;
    collateralAssets = _collateralAssets;
    actors = _actors;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HANDLER ACTIONS
  // ══════════════════════════════════════════════════════════════════════════════

  /**
   * @notice Deposit collateral into the pool
   * @param actorSeed Seed to select actor
   * @param assetSeed Seed to select collateral asset
   * @param amount Amount to deposit (will be bounded)
   */
  function deposit(uint256 actorSeed, uint256 assetSeed, uint256 amount) external {
    calls[keccak256('deposit')]++;

    address actor = _selectActor(actorSeed);
    address asset = _selectAsset(assetSeed);

    // Bound amount
    uint256 boundedAmount = bound(amount, 1e6, 1e24);

    // Deal tokens to actor
    deal(asset, actor, boundedAmount);

    // Perform deposit
    vm.startPrank(actor);
    IERC20(asset).approve(address(pool), boundedAmount);

    try pool.supply(asset, boundedAmount, actor, 0) {
      ghost_totalDeposits += boundedAmount;
    } catch {
      // Deposit failed (maybe supply cap reached)
    }
    vm.stopPrank();
  }

  /**
   * @notice Borrow jpyUBI against collateral
   * @param actorSeed Seed to select actor
   * @param amount Amount to borrow (will be bounded by available borrows)
   */
  function borrow(uint256 actorSeed, uint256 amount) external {
    calls[keccak256('borrow')]++;

    address actor = _selectActor(actorSeed);

    // Get user's available borrows
    (, , uint256 availableBorrowsBase, , , ) = pool.getUserAccountData(actor);
    if (availableBorrowsBase == 0) return;

    // Convert to jpyUBI amount
    uint256 jpyUbiPrice = oracle.getAssetPrice(address(jpyUbi));
    if (jpyUbiPrice == 0) return;

    uint256 maxBorrow = (availableBorrowsBase * 1e18) / jpyUbiPrice;

    // Bound amount
    uint256 boundedAmount = bound(amount, 1e18, (maxBorrow * 95) / 100);
    if (boundedAmount == 0) return;

    vm.prank(actor);
    try pool.borrow(address(jpyUbi), boundedAmount, 2, 0, actor) {
      ghost_totalBorrows += boundedAmount;
    } catch {
      // Borrow failed
    }
  }

  /**
   * @notice Repay jpyUBI debt
   * @param actorSeed Seed to select actor
   * @param amount Amount to repay
   */
  function repay(uint256 actorSeed, uint256 amount) external {
    calls[keccak256('repay')]++;

    address actor = _selectActor(actorSeed);

    // Get user's debt
    uint256 debt = _getUserDebt(actor);
    if (debt == 0) return;

    // Bound amount
    uint256 boundedAmount = bound(amount, 1, debt);

    // Deal jpyUBI to actor for repayment
    deal(address(jpyUbi), actor, boundedAmount);

    vm.startPrank(actor);
    jpyUbi.approve(address(pool), boundedAmount);

    try pool.repay(address(jpyUbi), boundedAmount, 2, actor) {
      ghost_totalRepays += boundedAmount;
    } catch {
      // Repay failed
    }
    vm.stopPrank();
  }

  /**
   * @notice Withdraw collateral from pool
   * @param actorSeed Seed to select actor
   * @param assetSeed Seed to select asset
   * @param amount Amount to withdraw
   */
  function withdraw(uint256 actorSeed, uint256 assetSeed, uint256 amount) external {
    calls[keccak256('withdraw')]++;

    address actor = _selectActor(actorSeed);
    address asset = _selectAsset(assetSeed);

    // Get user's deposit balance
    DataTypes.ReserveDataLegacy memory reserve = pool.getReserveData(asset);
    uint256 balance = IERC20(reserve.aTokenAddress).balanceOf(actor);
    if (balance == 0) return;

    // Bound amount
    uint256 boundedAmount = bound(amount, 1, balance);

    vm.prank(actor);
    try pool.withdraw(asset, boundedAmount, actor) {
      ghost_totalWithdraws += boundedAmount;
    } catch {
      // Withdraw failed (maybe would cause undercollateralization)
    }
  }

  /**
   * @notice Attempt to liquidate an undercollateralized position
   * @param liquidatorSeed Seed to select liquidator
   * @param targetSeed Seed to select target
   * @param collateralSeed Seed to select collateral asset
   * @param debtToCover Amount of debt to cover
   */
  function liquidate(uint256 liquidatorSeed, uint256 targetSeed, uint256 collateralSeed, uint256 debtToCover) external {
    calls[keccak256('liquidate')]++;

    address liquidator = _selectActor(liquidatorSeed);
    address target = _selectActor(targetSeed);
    address collateral = _selectAsset(collateralSeed);

    if (liquidator == target) return;

    // Check if target is liquidatable
    (, , , , , uint256 healthFactor) = pool.getUserAccountData(target);
    if (healthFactor >= 1e18) return;

    // Get target's debt
    uint256 debt = _getUserDebt(target);
    if (debt == 0) return;

    // Bound debt to cover (max 50% close factor)
    uint256 maxDebtToCover = (debt * 50) / 100;
    uint256 boundedDebt = bound(debtToCover, 1e18, maxDebtToCover);

    // Deal jpyUBI to liquidator
    deal(address(jpyUbi), liquidator, boundedDebt);

    vm.startPrank(liquidator);
    jpyUbi.approve(address(pool), boundedDebt);

    try pool.liquidationCall(collateral, address(jpyUbi), target, boundedDebt, false) {
      ghost_totalLiquidations++;
    } catch {
      // Liquidation failed
    }
    vm.stopPrank();
  }

  /**
   * @notice Warp time forward to accrue interest
   * @param timeJump Seconds to jump forward
   */
  function warpTime(uint256 timeJump) external {
    calls[keccak256('warpTime')]++;

    // Bound time jump between 1 hour and 1 year
    uint256 boundedJump = bound(timeJump, 1 hours, 365 days);
    vm.warp(block.timestamp + boundedJump);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ══════════════════════════════════════════════════════════════════════════════

  function _selectActor(uint256 seed) internal view returns (address) {
    return actors[seed % actors.length];
  }

  function _selectAsset(uint256 seed) internal view returns (address) {
    return collateralAssets[seed % collateralAssets.length];
  }

  function _getUserDebt(address user) internal view returns (uint256) {
    DataTypes.ReserveDataLegacy memory reserve = pool.getReserveData(address(jpyUbi));
    return IERC20(reserve.variableDebtTokenAddress).balanceOf(user);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // GHOST VARIABLE GETTERS
  // ══════════════════════════════════════════════════════════════════════════════

  function callSummary() external view {
    console2.log('Handler call summary:');
    console2.log('  deposit:', calls[keccak256('deposit')]);
    console2.log('  borrow:', calls[keccak256('borrow')]);
    console2.log('  repay:', calls[keccak256('repay')]);
    console2.log('  withdraw:', calls[keccak256('withdraw')]);
    console2.log('  liquidate:', calls[keccak256('liquidate')]);
    console2.log('  warpTime:', calls[keccak256('warpTime')]);
  }
}
