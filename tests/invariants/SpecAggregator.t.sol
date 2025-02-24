// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Test Contracts
import {InvariantsSpec} from './specs/InvariantsSpec.t.sol';
import {PostconditionsSpec} from './specs/PostconditionsSpec.t.sol';
import {HFPostconditionsSpec} from './specs/HFPostconditionsSpec.t.sol';

/// @title SpecAggregator
/// @notice Helper contract to aggregate all spec contracts, inherited in BaseHooks
/// @dev inherits InvariantsSpec, PostconditionsSpec
abstract contract SpecAggregator is InvariantsSpec, PostconditionsSpec, HFPostconditionsSpec {
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      PROPERTY TYPES                                       //
  ///////////////////////////////////////////////////////////////////////////////////////////////
  /// In this invariant testing framework, there are two types of properties:
  /// - INVARIANTS (INV):
  ///   - Properties that should always hold true in the system.
  ///   - Implemented in the /invariants folder.
  /// - POSTCONDITIONS:
  ///   - Properties that should hold true after an action is executed.
  ///   - Implemented in the /hooks and /handlers folders.
  ///   - There are two types of POSTCONDITIONS:
  ///     - GLOBAL POSTCONDITIONS (GPOST):
  ///       - Properties that should always hold true after any action is executed.
  ///       - Checked in the `_checkPostConditions` function within the HookAggregator contract.
  ///     - HANDLER-SPECIFIC POSTCONDITIONS (HSPOST):
  ///       - Properties that should hold true after a specific action is executed in a specific context.
  ///       - Implemented within each handler function, under the HANDLER-SPECIFIC POSTCONDITIONS section.
}
