// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorBorrowCapTests} from 'tests/protocol/pool/pool-configurator/PoolConfigurator.borrowCaps.t.sol';

contract PoolConfiguratorBorrowCapRwaTests is PoolConfiguratorBorrowCapTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev overwritten to make usdx a standard aToken: test is borrowing usdx
  function test_borrow_eq_cap() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_borrow_eq_cap();
  }

  /// @dev overwritten to make usdx a standard aToken: test is borrowing usdx
  function test_borrow_interests_reach_cap() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_borrow_interests_reach_cap();
  }

  /// @dev overwritten to make usdx a standard aToken: test is borrowing usdx
  function test_borrow_lt_cap() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_borrow_lt_cap();
  }

  /// @dev overwritten to make usdx a standard aToken: test is borrowing usdx
  function test_setBorrowCap_them_setBorrowCap_zero() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_setBorrowCap_them_setBorrowCap_zero();
  }
}
