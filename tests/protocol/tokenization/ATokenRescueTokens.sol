// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken} from '../../../src/contracts/interfaces/IAToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract ATokenRescueTokensTests is TestnetProcedures {
  IAToken public aTokenUSDX;
  IAToken public aTokenWBTC;

  event Transfer(address indexed from, address indexed to, uint256 amount);

  function setUp() public {
    initTestEnvironment();

    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
    (address aWBTC, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.wbtc);
    aTokenUSDX = IAToken(aUSDX);
    aTokenWBTC = IAToken(aWBTC);
  }

  function test_rescueTokens() public {
    vm.prank(poolAdmin);
    usdx.mint(address(aTokenWBTC), 100e6);

    assertEq(usdx.balanceOf(address(aTokenWBTC)), 100e6);

    vm.prank(poolAdmin);
    aTokenWBTC.rescueTokens(address(usdx), poolAdmin, 100e6);

    assertEq(usdx.balanceOf(address(aTokenWBTC)), 0);
    assertEq(usdx.balanceOf(poolAdmin), 100e6);
  }

  function test_reverts_rescueTokens_UNDERLYING_CANNOT_BE_RESCUED() public {
    vm.prank(poolAdmin);
    usdx.mint(address(aTokenUSDX), 100e6);

    assertEq(usdx.balanceOf(address(aTokenUSDX)), 100e6);

    vm.expectRevert(bytes(Errors.UNDERLYING_CANNOT_BE_RESCUED));

    vm.prank(poolAdmin);
    aTokenUSDX.rescueTokens(address(usdx), poolAdmin, 100e6);

    assertEq(usdx.balanceOf(address(aTokenUSDX)), 100e6);
  }

  function test_reverts_rescueTokens_CALLER_NOT_POOL_ADMIN() public {
    vm.prank(poolAdmin);
    usdx.mint(address(aTokenUSDX), 100e6);

    assertEq(usdx.balanceOf(address(aTokenUSDX)), 100e6);

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(makeAddr('OTHER'));
    aTokenUSDX.rescueTokens(address(usdx), poolAdmin, 100e6);

    assertEq(usdx.balanceOf(address(aTokenUSDX)), 100e6);
  }
}
