// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolSupplyTests} from '../pool/Pool.Supply.t.sol';

contract PoolSupplyRwaTests is PoolSupplyTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
    _upgradeToRwaAToken(tokenList.weth, 'aWeth');
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev overwriting to make usdx an RWA aToken: test is supplying on behalf
  function test_first_supply_on_behalf() public override {
    _upgradeToStandardAToken(tokenList.wbtc, 'aWbtc');
  }
}
