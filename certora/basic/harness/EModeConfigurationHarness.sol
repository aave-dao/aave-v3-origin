// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;

import {EModeConfiguration} from '../munged/contracts/protocol/libraries/configuration/EModeConfiguration.sol';
import {DataTypes} from '../munged/contracts/protocol/libraries/types/DataTypes.sol';

contract EModeConfigurationHarness {
  DataTypes.EModeCategory public eModeCategory;

  function setCollateral(uint256 reserveIndex, bool enabled) public {
    DataTypes.EModeCategory memory emode_new = eModeCategory;
    eModeCategory.collateralBitmap = EModeConfiguration.setReserveBitmapBit(
      emode_new.collateralBitmap,
      reserveIndex,
      enabled
    );
  }

  function isCollateralAsset(uint256 reserveIndex) public returns (bool) {
    return
      EModeConfiguration.isReserveEnabledOnBitmap(eModeCategory.collateralBitmap, reserveIndex);
  }

  function setBorrowable(uint256 reserveIndex, bool enabled) public {
    DataTypes.EModeCategory memory emode_new = eModeCategory;
    eModeCategory.borrowableBitmap = EModeConfiguration.setReserveBitmapBit(
      emode_new.borrowableBitmap,
      reserveIndex,
      enabled
    );
  }

  function isBorrowableAsset(uint256 reserveIndex) public returns (bool) {
    return
      EModeConfiguration.isReserveEnabledOnBitmap(eModeCategory.borrowableBitmap, reserveIndex);
  }
}
