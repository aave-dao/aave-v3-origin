// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IPoolConfigurator} from '../../../../src/contracts/interfaces/IPoolConfigurator.sol';
import {IERC20} from '../../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {DataTypes} from '../../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {TestnetProcedures} from '../../../utils/TestnetProcedures.sol';

contract PoolConfiguratorBorrowCapTests is TestnetProcedures {
  address internal aUSDX;

  uint256 public constant MAX_BORROW_CAP = 68719476735;

  function setUp() public {
    initTestEnvironment();

    aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);

    uint256 mintAmount = 100_000e6;

    // Supplies USDX
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, mintAmount, alice, 0);

    vm.prank(bob);
    contracts.poolProxy.supply(tokenList.usdx, mintAmount, bob, 0);

    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, mintAmount, carol, 0);
  }

  function _setBorrowCapAction(address admin, address token, uint256 amount) internal {
    (uint256 previousCap, ) = contracts.protocolDataProvider.getReserveCaps(token);
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.BorrowCapChanged(token, previousCap, amount);

    vm.prank(admin);
    contracts.poolConfiguratorProxy.setBorrowCap(token, amount);

    (uint256 newCap, ) = contracts.protocolDataProvider.getReserveCaps(token);
    assertEq(newCap, amount, 'Cap should match cap amount passed by argument');
  }

  function test_default_borrowCap_zero() public view {
    (uint256 borrowCapUsdx, ) = contracts.protocolDataProvider.getReserveCaps(tokenList.usdx);
    assertEq(borrowCapUsdx, 0, 'Default borrow cap should be zero');
  }

  function test_reverts_unauthorized_setBorrowCap() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotRiskOrPoolAdmin.selector));

    vm.prank(bob);
    contracts.poolConfiguratorProxy.setBorrowCap(tokenList.usdx, 10);
  }

  function test_setBorrowCap() public {
    _setBorrowCapAction(poolAdmin, tokenList.usdx, 10);
  }

  function test_borrow_lt_cap() public {
    _setBorrowCapAction(poolAdmin, tokenList.usdx, 3240);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 1250e6, 2, 0, alice);

    assertEq(
      IERC20(tokenList.usdx).balanceOf(alice),
      1250e6,
      'Alice balance should match borrow amount'
    );
  }

  function test_borrow_eq_cap() public {
    _setBorrowCapAction(poolAdmin, tokenList.usdx, 5000);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 5000e6, 2, 0, alice);

    (uint256 borrowCapUsdx, ) = contracts.protocolDataProvider.getReserveCaps(tokenList.usdx);

    assertEq(
      IERC20(tokenList.usdx).balanceOf(alice),
      5000e6,
      'Alice balance should match borrow amount'
    );

    uint256 variableDebt = IERC20(contracts.poolProxy.getReserveVariableDebtToken(tokenList.usdx))
      .totalSupply();

    assertEq(
      variableDebt,
      borrowCapUsdx * 10 ** 6,
      'Borrow Cap should match same amount than total debt'
    );
  }

  function test_borrow_interests_reach_cap() public {
    _setBorrowCapAction(poolAdmin, tokenList.usdx, 5000);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 5000e6, 2, 0, alice);

    assertEq(
      IERC20(tokenList.usdx).balanceOf(alice),
      5000e6,
      'Alice balance should match borrow amount'
    );
    vm.warp(vm.getBlockTimestamp() + 30 days);

    uint256 variableDebt = IERC20(contracts.poolProxy.getReserveVariableDebtToken(tokenList.usdx))
      .totalSupply();

    (uint256 borrowCapUsdx, ) = contracts.protocolDataProvider.getReserveCaps(tokenList.usdx);

    assertGt(variableDebt, borrowCapUsdx * 10 ** 6, 'Total debt should be greater than cap');
  }

  function test_setBorrowCap_them_setBorrowCap_zero() public {
    _setBorrowCapAction(poolAdmin, tokenList.usdx, 100);
    _setBorrowCapAction(poolAdmin, tokenList.usdx, 0);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 5000e6, 2, 0, alice);

    assertEq(
      IERC20(tokenList.usdx).balanceOf(alice),
      5000e6,
      'Alice borrowed balance should match borrow amount'
    );
  }

  function test_reverts_borrow_gt_cap() public {
    _setBorrowCapAction(poolAdmin, tokenList.usdx, 1200);

    vm.expectRevert(abi.encodeWithSelector(Errors.BorrowCapExceeded.selector));
    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.usdx, 1999e6, 2, 0, bob);
  }

  function test_reverts_borrow_after_borrow_interests_reach_cap() public {
    test_borrow_interests_reach_cap();

    vm.expectRevert(abi.encodeWithSelector(Errors.BorrowCapExceeded.selector));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 200e6, 2, 0, alice);
  }

  function test_reverts_setBorrowCap_gt_max_cap() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBorrowCap.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setBorrowCap(tokenList.usdx, MAX_BORROW_CAP + 1);
  }
}
