// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ATokenRescueTokensTests} from 'tests/protocol/tokenization/ATokenRescueTokens.sol';

contract ATokenRescueTokensRwaTests is ATokenRescueTokensTests {
  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.usdx, 'aUSDX');
    _upgradeToRwaAToken(tokenList.wbtc, 'aWBTC');
  }
}
