// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestnetProcedures, IERC20, IAToken} from '../utils/TestnetProcedures.sol';

// Base test to setup the initial config: deploying the protocol contracts and setting them up locally on foundry
// command to test: make test-contract filter=BaseTest
contract BaseTest is TestnetProcedures {
  function setUp() public {
    // this method deploys all the protocol contract and does the inital setup.
    // -> the deployed contracts could be accessed via the ContractsReport struct internal variable `contracts`. Ex `contracts.poolProxy`
    // -> the assets listed could be accessed via the TokenList struct internal variable `tokenList`
    // -> the internal variable `poolAdmin` has the poolAdmin role of the protocol and holds all the admin access.
    initTestEnvironment();

    // initL2TestEnvironment(); -> deploys the protocol contracts as on an L2 (ex. we deploy L2Pool instead of Pool)
    // initTestEnvironment(true); -> mints the listed assets to users: alice, bob, carol (can be accessed by the same variable name)
  }

  // add your code below
  function test_default() public {
    uint256 supplyAmount = 0.2e8;
    uint256 underlyingBalanceBefore = IERC20(tokenList.wbtc).balanceOf(alice);
    (address aWBTC, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.wbtc);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, supplyAmount, alice, 0);

    assertEq(IERC20(tokenList.wbtc).balanceOf(alice), underlyingBalanceBefore - supplyAmount);
    assertEq(IAToken(aWBTC).scaledBalanceOf(alice), supplyAmount);
  }
}
