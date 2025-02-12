// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Base
import {BaseTest} from './BaseTest.t.sol';
import {StdAsserts} from '../utils/StdAsserts.sol';

/// @title ProtocolAssertions
/// @notice Helper contract for protocol specific assertions
contract ProtocolAssertions is StdAsserts, BaseTest {
  /// @notice Checks if an actor is active in the context of the call
  function assertIsActiveActor(address user, string memory reason) internal {
    assertTrue(_isActiveActor(user), reason);
  }

  /// @notice Checks if all the assets in an array of assets are borrowable in a specific eMode
  function assertAssetsBorrowableInEmode(
    address[] memory assets,
    uint8 eModeCategory,
    string memory reason
  ) internal {
    for (uint256 i; i < assets.length; i++) {
      assertTrue(_isEModeBorrowableAsset(assets[i], eModeCategory), reason);
    }
  }

  /// @notice Checks if the reserve is active and not paused
  function assertReserveIsActiveAndNotPaused(Flags memory flags) internal pure returns (bool) {
    return flags.isActive && !flags.isPaused;
  }

  /// @notice Checks if the reserve is active, not frozen, not paused and borrowing is enabled
  function assertReserveIsAbleToBorrow(Flags memory flags) internal pure returns (bool) {
    return flags.isActive && flags.borrowingEnabled && !flags.isFrozen && !flags.isPaused;
  }

  /// @notice Checks if the reserve is active, not frozen and not paused
  function assertReserveIsAbleToDeposit(Flags memory flags) internal pure returns (bool) {
    return flags.isActive && !flags.isFrozen && !flags.isPaused;
  }

  /// @notice Checks if the gracePeriod is set acrosss all reserves
  function assertReserveGracePeriodIsSetAllReserves(
    uint40 gracePeriod,
    string memory reason
  ) internal {
    for (uint256 i; i < baseAssets.length; i++) {
      assertReserveGracePeriodIsSet(gracePeriod, baseAssets[i], reason);
    }
  }

  /// @notice Checks if the gracePeriod is set for a specific reserve
  function assertReserveGracePeriodIsSet(
    uint40 gracePeriod,
    address asset,
    string memory reason
  ) internal {
    uint256 liquidationGracePeriodUntil = pool.getLiquidationGracePeriod(asset);
    assertEq(liquidationGracePeriodUntil, block.timestamp + gracePeriod, reason);
  }
}
