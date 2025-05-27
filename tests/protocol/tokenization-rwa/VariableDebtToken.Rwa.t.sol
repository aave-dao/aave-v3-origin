// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VariableDebtTokenEventsTests} from 'tests/protocol/tokenization/VariableDebtToken.t.sol';

contract VariableDebtTokenEventsRwaTests is VariableDebtTokenEventsTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev skipping this tests, borrowing is not supported for RWA aTokens
  function test_balanceOf() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this tests, borrowing is not supported for RWA aTokens
  function test_scaledBalanceOf() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this tests, borrowing is not supported for RWA aTokens
  function test_totalScaledSupply() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev skipping this tests, borrowing is not supported for RWA aTokens
  function test_totalSupply() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }
}
