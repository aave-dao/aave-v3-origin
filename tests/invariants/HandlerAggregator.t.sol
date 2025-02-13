// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// User Actions Handler contracts,
import {ATokenHandler} from './handlers/user/ATokenHandler.t.sol';
import {VariableDebtTokenHandler} from './handlers/user/VariableDebtTokenHandler.t.sol';
import {BorrowingHandler} from './handlers/user/BorrowingHandler.t.sol';
import {LendingHandler} from './handlers/user/LendingHandler.t.sol';
import {LiquidationHandler} from './handlers/user/LiquidationHandler.t.sol';
import {PoolHandler} from './handlers/user/PoolHandler.t.sol';

// Permissioned Actions Handler contracts,
import {PoolPermissionedHandler} from './handlers/permissioned/PoolPermissionedHandler.t.sol';

// Simulator Handler contracts,
import {DonationAttackHandler} from './handlers/simulators/DonationAttackHandler.t.sol';
import {FlashLoanHandler} from './handlers/simulators/FlashLoanHandler.t.sol';
import {PriceAggregatorHandler} from './handlers/simulators/PriceAggregatorHandler.t.sol';

/// @notice Helper contract to aggregate all handler contracts, inherited in BaseInvariants
abstract contract HandlerAggregator is
  ATokenHandler, // User Actions
  VariableDebtTokenHandler,
  BorrowingHandler,
  LendingHandler,
  LiquidationHandler,
  PoolHandler,
  PoolPermissionedHandler, // Permissioned Actions
  DonationAttackHandler, // Simulators
  FlashLoanHandler,
  PriceAggregatorHandler
{
  /// @notice Helper function in case any handler requires additional setup
  function _setUpHandlers() internal {}
}
