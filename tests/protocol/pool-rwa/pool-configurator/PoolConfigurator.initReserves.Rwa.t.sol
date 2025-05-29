// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorInitReservesTest} from '../../pool/pool-configurator/PoolConfigurator.initReserves.t.sol';

contract PoolConfiguratorInitReservesRwaTest is PoolConfiguratorInitReservesTest {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }
}
