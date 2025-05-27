// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ATokenEventsTests} from 'tests/protocol/tokenization/ATokenEvents.t.sol';

contract ATokenEventsRwaTests is ATokenEventsTests {
  function setUp() public override {
    super.setUp();
  }

  /// @dev overwriting to make usdx an RWA aToken: test is not borrowing it
  function test_atoken_burnEvents_singleWithdraw_noInterests() public override {
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
    super.test_atoken_burnEvents_singleWithdraw_noInterests();
  }

  /// @dev overwriting to make usdx an RWA aToken: test is not supplying it
  function test_atoken_mintEvents_firstSupply() public override {
    _upgradeToRwaAToken(tokenList.usdx, 'aUsdx');
    super.test_atoken_mintEvents_firstSupply();
  }
}
