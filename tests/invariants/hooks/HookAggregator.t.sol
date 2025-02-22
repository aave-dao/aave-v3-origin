// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Hook Contracts
import {DefaultBeforeAfterHooks} from './DefaultBeforeAfterHooks.t.sol';

/// @title HookAggregator
/// @notice Helper contract to aggregate all before / after hook contracts, inherited on each handler
abstract contract HookAggregator is DefaultBeforeAfterHooks {
  /// @notice Initializer for the hooks
  function _setUpHooks() internal {
    _setUpDefaultHooks();
  }

  /// @notice Modular hook selector, per module
  function _before() internal {
    // RESET
    _resetHookValues(defaultVarsBefore);
    _resetHookValues(defaultVarsAfter);

    _defaultHooksBefore();
  }

  /// @notice Modular hook selector, per module
  function _after() internal {
    _defaultHooksAfter();

    // POST-CONDITIONS
    _checkPostConditions();

    // RESET
    _resetTargetAsset();
  }

  /// @notice Postconditions for the handlers
  function _checkPostConditions() internal {
    // Implement post conditions here

    // BASE
    assert_BASE_GPOST_A();
    //assert_BASE_GPOST_BCD();

    // LENDING
    assert_LENDING_GPOST_C();

    // BORROWING
    assert_BORROWING_GPOST_H();

    // HEALTH FACTOR

    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      //assert_HF_GPOST_A(actorAddresses[i]);
      assert_HF_GPOST_B(actorAddresses[i]);
      assert_HF_GPOST_C(actorAddresses[i]);
      assert_HF_GPOST_D(actorAddresses[i]);
      assert_HF_GPOST_E(actorAddresses[i]);
    }

    // DEFICIT
    assert_DM_GPOST_A();
  }

  /// @notice cleanup certain values on hook structs
  function _resetHookValues(DefaultVars storage _defaultVars) internal {
    delete _defaultVars.totalSupply;
    delete _defaultVars.scaledTotalSupply;
    delete _defaultVars.supplyCap;
    delete _defaultVars.borrowCap;
    delete _defaultVars.accruedToTreasury;
    delete _defaultVars.reserveDeficit;
  }
}
