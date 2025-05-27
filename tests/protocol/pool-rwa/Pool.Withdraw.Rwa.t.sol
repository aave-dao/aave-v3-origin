// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolWithdrawTests} from 'tests/protocol/pool/Pool.Withdraw.t.sol';

contract PoolWithdrawRwaTests is PoolWithdrawTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
    _upgradeToRwaAToken(tokenList.weth, 'aWeth');
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev overwriting to make usdx a standard aToken: test is borrowing usdx
  function test_Reverts_withdraw_transferred_funds() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_Reverts_withdraw_transferred_funds();
  }

  /// @dev overwriting to make usdx a standard aToken: test is borrowing usdx
  function test_reverts_withdraw_hf_lt_lqt() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_reverts_withdraw_hf_lt_lqt();
  }
}
