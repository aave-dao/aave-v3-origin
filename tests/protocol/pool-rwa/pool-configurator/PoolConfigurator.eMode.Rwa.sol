// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorEModeConfigTests} from 'tests/protocol/pool/pool-configurator/PoolConfigurator.eMode.sol';

contract PoolConfiguratorEModeConfigRwaTests is PoolConfiguratorEModeConfigTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }
}
