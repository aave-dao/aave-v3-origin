// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {WadRayMath} from './WadRayMath.sol';

/**
 * @title MathUtils library
 * @author Aave
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library MathUtils {
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   */
  function calculateLinearInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp
  ) internal view returns (uint256) {
    //solium-disable-next-line
    uint256 result = rate * (block.timestamp - uint256(lastUpdateTimestamp));
    unchecked {
      result = result / SECONDS_PER_YEAR;
    }

    return WadRayMath.RAY + result;
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
   * gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
   * error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   */
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

    if (exp == 0) {
      return WadRayMath.RAY;
    }

    // calculations compound interest using the ideal formula - e^(rate per year * number of years)
    // 100_000% per year = 1_000 * 100, passed 10_000 years:
    // e^(1_000 * 10_000) = 6.5922325346184394895608861310659088446667722661221381641234330770... × 10^4342944

    // The current formula in the contract returns:
    // 1.66666716666676666667 × 10^20
    // This happens because the contract uses a polynomial approximation of the ideal formula
    // and on big numbers the ideal formula with exponential function has much more speed.
    // Used approximation in contracts is not precise enough on such big numbers.
    //
    // But we can be sure that the current formula in contracts can't overflow on such big numbers
    // and we can use unchecked arithmetics to save gas.
    //
    // Also, if we take into an account the fact that all timestamps are stored in uint32/40 types
    // we can only have 100 years left until we will have overflows in timestamps.
    // Because of that realistically we can't overflow in this formula.

    unchecked {
      // this can't overflow because rate is always fits in 128 bits and exp always fits in 40 bits
      uint256 x = (rate * exp) / SECONDS_PER_YEAR;

      return WadRayMath.RAY + x + x.rayMul(x / 2 + x.rayMul(x / 6));
    }
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   * @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
   */
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp
  ) internal view returns (uint256) {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }

  function mulDivCeil(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 d) {
    assembly {
      // Revert if c == 0 to avoid division by zero
      if iszero(c) {
        revert(0, 0)
      }

      // Overflow check: Ensure a * b does not exceed uint256 max
      if iszero(or(iszero(b), iszero(gt(a, div(not(0), b))))) {
        revert(0, 0)
      }

      let product := mul(a, b)
      d := add(div(product, c), iszero(iszero(mod(product, c))))
    }
  }
}
