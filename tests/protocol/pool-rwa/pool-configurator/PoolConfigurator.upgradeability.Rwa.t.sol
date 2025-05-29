// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorUpgradeabilityTests} from '../../pool/pool-configurator/PoolConfigurator.upgradeabilty.t.sol';

contract PoolConfiguratorUpgradeabilityRwaTests is PoolConfiguratorUpgradeabilityTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev overwritten to make usdx a standard aToken: test is borrowing usdx
  function test_interestRateStrategy_update() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_interestRateStrategy_update();
  }
}
