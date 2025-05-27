// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolLiquidationCloseFactorTests} from 'tests/protocol/pool/Pool.Liquidations.CloseFactor.t.sol';

contract PoolLiquidationCloseFactorRwaTests is PoolLiquidationCloseFactorTests {
  function setUp() public override {
    super.setUp();

    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
  }

  /// @dev overwriting to make weth an RWA aToken: test is not borrowing it
  function test_hf_helper(uint256 desiredHf) public override {
    _upgradeToRwaAToken(tokenList.weth, 'aWeth');
    super.test_hf_helper(desiredHf);
  }

  /// @dev overwriting to make weth an RWA aToken: test is not borrowing it
  function test_liquidationdataprovider_edge_range_reverse() public override {
    _upgradeToRwaAToken(tokenList.weth, 'aWeth');
    super.test_liquidationdataprovider_edge_range_reverse();
  }

  /// @dev overwriting to make weth an RWA aToken: test is not borrowing it
  function test_shouldRevertIfCloseFactorIs100ButCollateralIsBelowThreshold() public override {
    _upgradeToRwaAToken(tokenList.weth, 'aWeth');
    super.test_shouldRevertIfCloseFactorIs100ButCollateralIsBelowThreshold();
  }
}
