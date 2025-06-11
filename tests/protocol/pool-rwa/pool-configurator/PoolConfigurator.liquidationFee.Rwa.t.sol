// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorLiquidationFeeTests} from '../../pool/pool-configurator/PoolConfigurator.liquidationFee.t.sol';

contract PoolConfiguratorLiquidationFeeRwaTests is PoolConfiguratorLiquidationFeeTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }
}
