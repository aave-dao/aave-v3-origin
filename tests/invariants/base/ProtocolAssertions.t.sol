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
}
