// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorPendingLtvTests} from '../../pool/pool-configurator/PoolConfigurator.pendingLTV.t.sol';

contract PoolConfiguratorPendingLtvRwaTests is PoolConfiguratorPendingLtvTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }
}
