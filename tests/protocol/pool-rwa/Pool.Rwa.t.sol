// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolTests} from 'tests/protocol/pool/Pool.t.sol';

contract PoolRwaTests is PoolTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
  }
}
