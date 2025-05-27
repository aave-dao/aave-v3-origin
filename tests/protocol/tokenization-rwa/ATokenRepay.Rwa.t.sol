// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ATokenRepayTests} from 'tests/protocol/tokenization/ATokenRepay.t.sol';

contract ATokenRepayRwaTests is ATokenRepayTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');
  }
}
