// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolBorrowTests} from 'tests/protocol/pool/Pool.Borrow.t.sol';

contract PoolBorrowRwaTests is PoolBorrowTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
    _upgradeToRwaAToken(tokenList.weth, 'aWeth');
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev overwriting to make usdx a standard aToken: test is borrowing usdx
  function test_borrow_variable_in_isolation() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_borrow_variable_in_isolation();
  }

  /// @dev overwriting to make usdx a standard aToken: test is borrowing usdx
  function test_reverts_borrow_hf_lt_1() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_reverts_borrow_hf_lt_1();
  }

  /// @dev overwriting to make wbtc a standard aToken: test is borrowing wbtc
  function test_reverts_borrow_sioled_borrowing_violation() public override {
    _upgradeToStandardAToken(tokenList.wbtc, 'aWbtc');
    super.test_reverts_borrow_sioled_borrowing_violation();
  }

  /// @dev overwriting to make wbtc a standard aToken: test is borrowing wbtc
  function test_reverts_deprecated_stable_borrow() public override {
    _upgradeToStandardAToken(tokenList.wbtc, 'aWbtc');
    super.test_reverts_deprecated_stable_borrow();
  }

  /// @dev overwriting to make usdx a standard aToken: test is borrowing usdx
  function test_variable_borrow() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_variable_borrow();
  }
}
