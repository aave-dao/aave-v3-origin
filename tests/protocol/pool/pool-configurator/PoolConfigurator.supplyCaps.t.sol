// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IERC20} from '../../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {TestnetProcedures} from '../../../utils/TestnetProcedures.sol';

contract PoolConfiguratorSupplyCapTests is TestnetProcedures {
  address internal aUSDX;

  uint256 constant MAX_SUPPLY_CAP = 68719476735;

  event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

  function setUp() public {
    initTestEnvironment();

    (aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
  }

  function _setSupplyCapAction(address admin, address token, uint256 amount) internal {
    (, uint256 previousCap) = contracts.protocolDataProvider.getReserveCaps(token);
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit SupplyCapChanged(token, previousCap, amount);

    vm.prank(admin);
    contracts.poolConfiguratorProxy.setSupplyCap(token, amount);

    (, uint256 newCap) = contracts.protocolDataProvider.getReserveCaps(token);
    assertEq(newCap, amount, 'Cap should match cap amount passed by argument');
  }

  function test_default_supplyCap_zero() public view {
    (, uint256 supplyCapUsdx) = contracts.protocolDataProvider.getReserveCaps(tokenList.usdx);
    assertEq(supplyCapUsdx, 0, 'Default supply cap should be zero');
  }

  function test_reverts_unauthorized_setSupplyCap() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(bob);
    contracts.poolConfiguratorProxy.setSupplyCap(tokenList.usdx, 10);
  }

  function test_setSupplyCap() public {
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 10);
  }

  function test_supply_lt_cap() public {
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 4000);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 1250e6, alice, 0);

    assertEq(IERC20(aUSDX).balanceOf(alice), 1250e6, 'Alice balance should match supply amount');
  }

  function test_supply_eq_cap() public {
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 6000);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 6000e6, alice, 0);

    assertEq(IERC20(aUSDX).balanceOf(alice), 6000e6, 'Alice balance should match supply amount');
  }

  function test_supply_interests_reach_cap() public {
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 5000);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 5000e6, alice, 0);

    assertEq(IERC20(aUSDX).balanceOf(alice), 5000e6, 'Alice balance should match borrow amount');

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 100e6, 2, 0, alice);

    vm.warp(block.timestamp + 30 days);

    uint256 totalCollateral = IERC20(aUSDX).totalSupply();

    (, uint256 supplyCapUsdx) = contracts.protocolDataProvider.getReserveCaps(tokenList.usdx);

    assertGt(totalCollateral, supplyCapUsdx * 10 ** 6, 'Total supplied should be greater than cap');
  }

  function test_setSupplyCap_them_setBorrowCap_zero() public {
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 100);
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 0);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 5000e6, alice, 0);

    assertEq(
      IERC20(aUSDX).balanceOf(alice),
      5000e6,
      'Alice supplied balance should match supply amount'
    );
  }

  function test_multiple_setSupplyCap() public {
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 100);
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 4000);
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 20000);
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 6000);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 5000e6, alice, 0);

    assertEq(
      IERC20(aUSDX).balanceOf(alice),
      5000e6,
      'Alice supplied balance should match supply amount'
    );
  }

  function test_reverts_supply_gt_cap() public {
    _setSupplyCapAction(poolAdmin, tokenList.usdx, 5000);

    vm.expectRevert(bytes(Errors.SUPPLY_CAP_EXCEEDED));
    vm.prank(bob);
    contracts.poolProxy.supply(tokenList.usdx, 6000e6, bob, 0);
  }

  function test_reverts_interests_gt_cap_and_supply() public {
    test_supply_interests_reach_cap();

    vm.expectRevert(bytes(Errors.SUPPLY_CAP_EXCEEDED));
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 1e6, alice, 0);
  }

  function test_reverts_setSupplyCap_gt_max_cap() public {
    vm.expectRevert(bytes(Errors.INVALID_SUPPLY_CAP));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setSupplyCap(tokenList.usdx, MAX_SUPPLY_CAP + 1);
  }
}
