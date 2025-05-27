// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolFlashLoansTests} from 'tests/protocol/pool/Pool.FlashLoans.t.sol';

contract PoolFlashLoansRwaTests is PoolFlashLoansTests {
  function setUp() public override {
    super.setUp();

    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
    _upgradeToRwaAToken(tokenList.weth, 'aWeth');
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev overwriting to make usdx a standard aToken: test is flashloaning usdx
  function test_flashloan() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_flashloan();
  }

  /// @dev overwriting to make usdx a standard aToken: test is flashloaning usdx
  function test_flashloan_borrow() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_flashloan_borrow();
  }

  /// @dev overwriting to make usdx a standard aToken: test is flashloaning usdx & wbtc
  function test_flashloan_multiple() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    _upgradeToStandardAToken(tokenList.wbtc, 'aWbtc');
    super.test_flashloan_multiple();
  }

  /// @dev overwriting to make usdx a standard aToken: test is flashloaning usdx
  function test_flashloan_simple() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_flashloan_simple();
  }

  /// @dev overwriting to make wbtc a standard aToken: test is flashloaning usdx
  function test_flashloan_simple_2() public override {
    _upgradeToStandardAToken(tokenList.wbtc, 'aWbtc');
    super.test_flashloan_simple_2();
  }

  /// @dev overwriting to make usdx a standard aToken: test is flashloaning usdx
  function test_revert_flashloan_borrow_stable() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_revert_flashloan_borrow_stable();
  }

  /// @dev overwriting to make usdx a standard aToken: test is flashloaning usdx
  function test_reverts_flashLoan_invalid_return() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_reverts_flashLoan_invalid_return();
  }

  /// @dev overwriting to make usdx a standard aToken: test is flashloaning usdx
  function test_reverts_flashLoan_simple_invalid_return() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_reverts_flashLoan_simple_invalid_return();
  }

  /// @dev overwriting to make usdx a standard aToken: test is flashloaning usdx
  function test_reverts_supply_flashloan_simple_transfer_withdraw() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_reverts_supply_flashloan_simple_transfer_withdraw();
  }

  /// @dev overwriting to make usdx a standard aToken: test is flashloaning usdx
  function test_reverts_supply_flashloan_transfer_withdraw() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_reverts_supply_flashloan_transfer_withdraw();
  }
}
