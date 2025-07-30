// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IReserveInterestRateStrategy} from '../../../interfaces/IReserveInterestRateStrategy.sol';
import {IPool} from '../../../interfaces/IPool.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {MathUtils} from '../math/MathUtils.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {Errors} from '../helpers/Errors.sol';
import {TokenMath} from '../helpers/TokenMath.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
  using WadRayMath for uint256;
  using TokenMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using GPv2SafeERC20 for IERC20;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /**
   * @notice Returns the ongoing normalized income for the reserve.
   * @dev A value of 1e27 means there is no income. As time passes, the income is accrued
   * @dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return The normalized income, expressed in ray
   */
  function getNormalizedIncome(
    DataTypes.ReserveData storage reserve
  ) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == block.timestamp) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndex;
    } else {
      return
        MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
          reserve.liquidityIndex
        );
    }
  }

  /**
   * @notice Returns the ongoing normalized variable debt for the reserve.
   * @dev A value of 1e27 means there is no debt. As time passes, the debt is accrued
   * @dev A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
   * @param reserve The reserve object
   * @return The normalized variable debt, expressed in ray
   */
  function getNormalizedDebt(
    DataTypes.ReserveData storage reserve
  ) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == block.timestamp) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.variableBorrowIndex;
    } else {
      return
        MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp).rayMul(
          reserve.variableBorrowIndex
        );
    }
  }

  /**
   * @notice Updates the liquidity cumulative index, the variable borrow index and the timestamp of the update.
   * @param reserve The reserve object
   * @param reserveCache The caching layer for the reserve data
   */
  function updateState(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {
    // If time didn't pass since last stored timestamp, skip state update
    //solium-disable-next-line
    if (reserveCache.reserveLastUpdateTimestamp == uint40(block.timestamp)) {
      return;
    }

    _updateIndexes(reserve, reserveCache);
    _accrueToTreasury(reserve, reserveCache);

    //solium-disable-next-line
    reserve.lastUpdateTimestamp = uint40(block.timestamp);
    reserveCache.reserveLastUpdateTimestamp = uint40(block.timestamp);
  }

  /**
   * @notice Initializes a reserve.
   * @param reserve The reserve object
   * @param aTokenAddress The address of the overlying atoken contract
   * @param variableDebtTokenAddress The address of the overlying variable debt token contract
   */
  function init(
    DataTypes.ReserveData storage reserve,
    address aTokenAddress,
    address variableDebtTokenAddress
  ) internal {
    require(reserve.aTokenAddress == address(0), Errors.ReserveAlreadyInitialized());

    reserve.liquidityIndex = uint128(WadRayMath.RAY);
    reserve.variableBorrowIndex = uint128(WadRayMath.RAY);
    reserve.aTokenAddress = aTokenAddress;
    reserve.variableDebtTokenAddress = variableDebtTokenAddress;
  }

  /**
   * @notice Updates the reserve current variable borrow rate and the current liquidity rate.
   * @param reserve The reserve reserve to be updated
   * @param reserveCache The caching layer for the reserve data
   * @param reserveAddress The address of the reserve to be updated
   * @param liquidityAdded The amount of liquidity added to the protocol (supply or repay) in the previous action
   * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
   */
  function updateInterestRatesAndVirtualBalance(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    address reserveAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    address interestRateStrategyAddress
  ) internal {
    uint256 totalVariableDebt = reserveCache.nextScaledVariableDebt.getVTokenBalance(
      reserveCache.nextVariableBorrowIndex
    );

    (uint256 nextLiquidityRate, uint256 nextVariableRate) = IReserveInterestRateStrategy(
      interestRateStrategyAddress
    ).calculateInterestRates(
        DataTypes.CalculateInterestRatesParams({
          unbacked: reserve.deficit,
          liquidityAdded: liquidityAdded,
          liquidityTaken: liquidityTaken,
          totalDebt: totalVariableDebt,
          reserveFactor: reserveCache.reserveFactor,
          reserve: reserveAddress,
          usingVirtualBalance: true,
          virtualUnderlyingBalance: reserve.virtualUnderlyingBalance
        })
      );

    reserve.currentLiquidityRate = nextLiquidityRate.toUint128();
    reserve.currentVariableBorrowRate = nextVariableRate.toUint128();

    if (liquidityAdded > 0) {
      reserve.virtualUnderlyingBalance += liquidityAdded.toUint128();
    }
    if (liquidityTaken > 0) {
      reserve.virtualUnderlyingBalance -= liquidityTaken.toUint128();
    }

    emit IPool.ReserveDataUpdated(
      reserveAddress,
      nextLiquidityRate,
      0,
      nextVariableRate,
      reserveCache.nextLiquidityIndex,
      reserveCache.nextVariableBorrowIndex
    );
  }

  /**
   * @notice Mints part of the repaid interest to the reserve treasury as a function of the reserve factor for the
   * specific asset.
   * @param reserve The reserve to be updated
   * @param reserveCache The caching layer for the reserve data
   */
  function _accrueToTreasury(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {
    if (reserveCache.reserveFactor == 0) {
      return;
    }

    // debt accrued is the sum of the current debt minus the sum of the debt at the last update
    // Rounding down to undermint to the treasury and keep the invariant healthy.
    uint256 totalDebtAccrued = reserveCache.currScaledVariableDebt.rayMulFloor(
      reserveCache.nextVariableBorrowIndex - reserveCache.currVariableBorrowIndex
    );

    uint256 amountToMint = totalDebtAccrued.percentMul(reserveCache.reserveFactor);

    if (amountToMint != 0) {
      reserve.accruedToTreasury += amountToMint
        .getATokenMintScaledAmount(reserveCache.nextLiquidityIndex)
        .toUint128();
    }
  }

  /**
   * @notice Updates the reserve indexes.
   * @param reserve The reserve reserve to be updated
   * @param reserveCache The cache layer holding the cached protocol data
   */
  function _updateIndexes(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {
    // Only cumulating on the supply side if there is any income being produced
    // The case of Reserve Factor 100% is not a problem (currentLiquidityRate == 0),
    // as liquidity index should not be updated
    if (reserveCache.currLiquidityRate != 0) {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
        reserveCache.currLiquidityRate,
        reserveCache.reserveLastUpdateTimestamp
      );
      reserveCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
        reserveCache.currLiquidityIndex
      );
      reserve.liquidityIndex = reserveCache.nextLiquidityIndex.toUint128();
    }

    // Variable borrow index only gets updated if there is any variable debt.
    // reserveCache.currVariableBorrowRate != 0 is not a correct validation,
    // because a positive base variable rate can be stored on
    // reserveCache.currVariableBorrowRate, but the index should not increase
    if (reserveCache.currScaledVariableDebt != 0) {
      uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
        reserveCache.currVariableBorrowRate,
        reserveCache.reserveLastUpdateTimestamp
      );
      reserveCache.nextVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(
        reserveCache.currVariableBorrowIndex
      );
      reserve.variableBorrowIndex = reserveCache.nextVariableBorrowIndex.toUint128();
    }
  }

  /**
   * @notice Creates a cache object to avoid repeated storage reads and external contract calls when updating state and
   * interest rates.
   * @param reserve The reserve object for which the cache will be filled
   * @return The cache object
   */
  function cache(
    DataTypes.ReserveData storage reserve
  ) internal view returns (DataTypes.ReserveCache memory) {
    DataTypes.ReserveCache memory reserveCache;

    reserveCache.reserveConfiguration = reserve.configuration;
    reserveCache.reserveFactor = reserveCache.reserveConfiguration.getReserveFactor();
    reserveCache.currLiquidityIndex = reserveCache.nextLiquidityIndex = reserve.liquidityIndex;
    reserveCache.currVariableBorrowIndex = reserveCache.nextVariableBorrowIndex = reserve
      .variableBorrowIndex;
    reserveCache.currLiquidityRate = reserve.currentLiquidityRate;
    reserveCache.currVariableBorrowRate = reserve.currentVariableBorrowRate;

    reserveCache.aTokenAddress = reserve.aTokenAddress;
    reserveCache.variableDebtTokenAddress = reserve.variableDebtTokenAddress;

    reserveCache.reserveLastUpdateTimestamp = reserve.lastUpdateTimestamp;

    reserveCache.currScaledVariableDebt = reserveCache.nextScaledVariableDebt = IVariableDebtToken(
      reserveCache.variableDebtTokenAddress
    ).scaledTotalSupply();

    return reserveCache;
  }
}
