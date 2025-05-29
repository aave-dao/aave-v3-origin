// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorReserveRiskConfigs} from '../../pool/pool-configurator/PoolConfigurator.reserveRiskConfig.t.sol';

contract PoolConfiguratorReserveRiskConfigsRwa is PoolConfiguratorReserveRiskConfigs {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev overwritten to make wbtc a standard aToken: test is borrowing wbtc
  function test_reverts_dropReserve_variableDebtNotZero() public override {
    _upgradeToStandardAToken(tokenList.wbtc, 'aWbtc');
    super.test_reverts_dropReserve_variableDebtNotZero();
  }

  /// @dev overwritten to make usdx a standard aToken: test is borrowing usdx
  function test_reverts_setSiloedBorrowing_borrowers() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_reverts_setSiloedBorrowing_borrowers();
  }

  /// @dev overwritten to make usdx a standard aToken: test is borrowing usdx
  function test_setReserveFactor() public override {
    _upgradeToStandardAToken(tokenList.usdx, 'aUsdx');
    super.test_setReserveFactor();
  }
}
