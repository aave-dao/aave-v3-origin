// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';

/**
 * @title EModeConfiguration library
 * @author BGD Labs
 * @notice Implements the bitmap logic to handle the eMode configuration
 */
library EModeConfiguration {
  /**
   * @notice Sets if the asset is borrowable in the given eMode
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @param borrowable True if the asset should be borrowable, false otherwise
   */
  function setBorrowable(
    DataTypes.EModeCategory memory self,
    uint256 reserveIndex,
    bool borrowable
  ) internal pure {
    require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
    uint128 bit = uint128(1 << reserveIndex);
    if (borrowable) {
      self.borrowableMask |= bit;
    } else {
      self.borrowableMask &= ~bit;
    }
  }

  /**
   * @notice Validates if a reserve can be borrowed in a selected eMode
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the reserve is borrowable
   */
  function isBorrowable(
    DataTypes.EModeCategory memory self,
    uint256 reserveIndex
  ) internal pure returns (bool) {
    require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
    return (self.borrowableMask >> reserveIndex) & 1 != 0;
  }
}
