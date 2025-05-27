// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorSupplyCapTests} from 'tests/protocol/pool/pool-configurator/PoolConfigurator.supplyCaps.t.sol';

contract PoolConfiguratorSupplyCapRwaTests is PoolConfiguratorSupplyCapTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev overwritten to make usdx a standard aToken: test is borrowing usdx
  function test_supply_interests_reach_cap() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_supply_interests_reach_cap();
  }
}
