// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title CarryLib
 * @notice Shared constants and math utilities for Carry strategy contracts
 */
library CarryLib {
  uint256 internal constant DECIMALS = 9;
  uint256 internal constant PRECISE_UNIT = 1e9;
  uint256 internal constant FULL_PRECISION = 1e18;
  uint256 internal constant CHAINLINK_DECIMALS = 8;
  uint256 internal constant CHAINLINK_UNIT = 1e8;
  uint256 internal constant USDC_DECIMALS = 6;
  uint256 internal constant JPY_DECIMALS = 18;
  uint256 internal constant SWAP_TIMEOUT = 30 minutes;
  uint256 internal constant MAX_BPS = 10000;
  uint256 internal constant TWAP_CONVERGENCE_TOLERANCE = 5e16;
  uint256 internal constant REBALANCE_DEVIATION_THRESHOLD = 1e16;
  uint256 internal constant ENGAGEMENT_THRESHOLD = 1e7;

  function calculateLeverageRatio(uint256 collateral, uint256 debtInBase) internal pure returns (uint256) {
    if (collateral == 0 || debtInBase == 0) return FULL_PRECISION;
    uint256 equity = collateral > debtInBase ? collateral - debtInBase : 0;
    if (equity == 0) return type(uint256).max;
    return (collateral * FULL_PRECISION) / equity;
  }

  function jpyToUsdc(uint256 jpyAmount, uint256 jpyUsdPrice) internal pure returns (uint256) {
    return (jpyAmount * jpyUsdPrice) / 1e20;
  }

  function usdcToJpy(uint256 usdcAmount, uint256 jpyUsdPrice) internal pure returns (uint256) {
    return (usdcAmount * 1e20) / jpyUsdPrice;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }
}
