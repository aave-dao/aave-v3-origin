// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Contracts
import {ProtocolAssertions} from './ProtocolAssertions.t.sol';

// Test Contracts
import {SpecAggregator} from '../SpecAggregator.t.sol';

/// @title BaseHooks
/// @notice Contains common logic for all hooks
/// @dev inherits all suite assertions since per-action assertions are implemented in the handlers
/// @dev inherits SpecAggregator
contract BaseHooks is ProtocolAssertions, SpecAggregator {}
