// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorACLModifiersTest} from '../../pool/pool-configurator/PoolConfigurator.ACLModifiers.t.sol';

contract PoolConfiguratorACLModifiersRwaTest is PoolConfiguratorACLModifiersTest {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }
}
