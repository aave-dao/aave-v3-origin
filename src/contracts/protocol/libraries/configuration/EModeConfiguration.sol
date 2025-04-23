// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';

/**
 * @title EModeConfiguration library
 * @author BGD Labs
 * @notice Implements the bitmap logic to handle the eMode configuration
 */
library EModeConfiguration {
  /**
   * @notice Sets a bit in a given bitmap that represents the reserve index range
   * @dev The supplied bitmap is supposed to be a uint128 in which each bit represents a reserve
   * @param bitmap The bitmap
   * @param reserveIndex The index of the reserve in the bitmap
   * @param enabled True if the reserveIndex should be enabled on the bitmap, false otherwise
   * @return The altered bitmap
   */
  function setReserveBitmapBit(
    uint128 bitmap,
    uint256 reserveIndex,
    bool enabled
  ) internal pure returns (uint128) {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.InvalidReserveIndex());
      uint128 bit = uint128(1 << reserveIndex);
      if (enabled) {
        return bitmap | bit;
      } else {
        return bitmap & ~bit;
      }
    }
  }

  /**
   * @notice Validates if a reserveIndex is flagged as enabled on a given bitmap
   * @param bitmap The bitmap
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the reserveindex is flagged true
   */
  function isReserveEnabledOnBitmap(
    uint128 bitmap,
    uint256 reserveIndex
  ) internal pure returns (bool) {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.InvalidReserveIndex());
      return (bitmap >> reserveIndex) & 1 != 0;
    }
  }
}
