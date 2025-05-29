// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolDeficitTests} from '../pool/Pool.Deficit.sol';

contract PoolDeficitRwaTests is PoolDeficitTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
  }

  /// @dev overwriting to make usdx an RWA aToken: this is the only
  /// test from this suite that is not borrowing usdx
  function test_reverts_eliminateReserveDeficit_reserve_not_in_deficit(
    address coverageAdmin
  ) public override {
    _upgradeToRwaAToken(tokenList.usdx, 'usdx');
    super.test_reverts_eliminateReserveDeficit_reserve_not_in_deficit(coverageAdmin);
  }
}
