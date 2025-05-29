// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolEModeTests} from '../pool/Pool.EMode.sol';

contract PoolEModeRwaTests is PoolEModeTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
  }

  /// @dev overwriting to make wbtc and weth RWA aTokens: test is not borrowing them
  function test_setUserEMode_shouldAllowSwitchingIfNoBorrows(uint8 eMode) public override {
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
    _upgradeToRwaAToken(tokenList.weth, 'aWeth');
    super.test_setUserEMode_shouldAllowSwitchingIfNoBorrows(eMode);
  }

  /// @dev overwriting to set usdx liquidation protocol fee to 0: test if liquidating usdx
  function test_liquidations_shouldApplyEModeLBForEmodeAssets(uint256 amount) public override {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 0);
    super.test_liquidations_shouldApplyEModeLBForEmodeAssets(amount);
  }
}
