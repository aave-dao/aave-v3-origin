// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract PoolWithdrawTests is TestnetProcedures {
  address internal aUSDX;
  address internal aWBTC;

  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  function setUp() public {
    initTestEnvironment();

    (aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
    (aWBTC, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.wbtc);
  }

  function test_full_withdraw() public {
    uint256 amount = 142e6;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);

    vm.warp(block.timestamp + 10 days);

    uint256 amountToWithdraw = IAToken(aUSDX).balanceOf(alice);
    uint256 balanceBefore = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(contracts.poolProxy));
    emit ReserveUsedAsCollateralDisabled(tokenList.usdx, alice);
    vm.expectEmit(address(contracts.poolProxy));
    emit Withdraw(tokenList.usdx, alice, alice, amountToWithdraw);

    contracts.poolProxy.withdraw(tokenList.usdx, amountToWithdraw, alice);
    vm.stopPrank();

    assertEq(IERC20(tokenList.usdx).balanceOf(alice), balanceBefore + amountToWithdraw);
    assertEq(IAToken(aUSDX).balanceOf(alice), 0);
  }

  function test_partial_withdraw() public {
    uint256 amount = 142e6;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);

    vm.warp(block.timestamp + 10 days);

    uint256 amountToWithdraw = IAToken(aUSDX).balanceOf(alice);
    uint256 balanceBefore = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(contracts.poolProxy));
    emit ReserveUsedAsCollateralDisabled(tokenList.usdx, alice);
    vm.expectEmit(address(contracts.poolProxy));
    emit Withdraw(tokenList.usdx, alice, alice, amountToWithdraw);

    contracts.poolProxy.withdraw(tokenList.usdx, type(uint256).max, alice);
    vm.stopPrank();

    assertEq(IERC20(tokenList.usdx).balanceOf(alice), balanceBefore + amountToWithdraw);
  }

  function test_full_withdraw_to() public {
    uint256 amount = 142e6;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);

    vm.warp(block.timestamp + 10 days);

    uint256 amountToWithdraw = IAToken(aUSDX).balanceOf(alice);
    uint256 balanceBefore = IERC20(tokenList.usdx).balanceOf(bob);

    vm.expectEmit(address(contracts.poolProxy));
    emit ReserveUsedAsCollateralDisabled(tokenList.usdx, alice);
    vm.expectEmit(address(contracts.poolProxy));
    emit Withdraw(tokenList.usdx, alice, bob, amountToWithdraw);

    contracts.poolProxy.withdraw(tokenList.usdx, type(uint256).max, bob);
    vm.stopPrank();

    assertEq(IERC20(tokenList.usdx).balanceOf(bob), balanceBefore + amountToWithdraw);
    assertEq(IAToken(aUSDX).balanceOf(alice), 0);
  }

  function test_withdraw_not_enabled_as_collateral() public {
    uint256 amount = 142e6;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);

    vm.expectEmit(address(contracts.poolProxy));
    emit ReserveUsedAsCollateralDisabled(tokenList.usdx, alice);
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.usdx, false);

    vm.warp(block.timestamp + 10 days);

    uint256 amountToWithdraw = IAToken(aUSDX).balanceOf(alice);
    uint256 balanceBefore = IERC20(tokenList.usdx).balanceOf(alice);

    vm.expectEmit(address(contracts.poolProxy));
    emit Withdraw(tokenList.usdx, alice, alice, amountToWithdraw);

    contracts.poolProxy.withdraw(tokenList.usdx, type(uint256).max, alice);
    vm.stopPrank();

    assertEq(IERC20(tokenList.usdx).balanceOf(alice), balanceBefore + amountToWithdraw);
    assertEq(IAToken(aUSDX).balanceOf(alice), 0);
  }

  function test_reverts_withdraw_invalidAmount() public {
    uint256 amount = 142e6;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);

    vm.expectRevert(bytes(Errors.INVALID_AMOUNT));

    contracts.poolProxy.withdraw(tokenList.usdx, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_withdraw_to_atoken() public {
    uint256 amount = 142e6;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);

    vm.expectRevert(bytes(Errors.WITHDRAW_TO_ATOKEN));

    contracts.poolProxy.withdraw(tokenList.usdx, amount, aUSDX);
    vm.stopPrank();
  }

  function test_Reverts_withdraw_transferred_funds() public {
    uint256 wethSupplyAmount = 2e18;
    uint256 amount = 142e6;

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.weth, wethSupplyAmount, alice, 0);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, amount, 2, 0, alice);
    assertEq(IERC20(tokenList.usdx).balanceOf(aUSDX), 0);

    IERC20(tokenList.usdx).transfer(aUSDX, amount);

    vm.expectRevert(stdError.arithmeticError);

    contracts.poolProxy.withdraw(tokenList.usdx, amount, alice);
    vm.stopPrank();
  }

  function test_reverts_withdraw_invalidBalance() public {
    uint256 amount = 142e6;
    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.usdx, amount, carol, 0);

    vm.expectRevert(bytes(Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE));

    contracts.poolProxy.withdraw(tokenList.usdx, 200e6, alice);
    vm.stopPrank();
  }

  function test_reverts_withdraw_reserveInactive() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.usdx, false);

    vm.prank(report.poolProxy);
    IAToken(aUSDX).mint(alice, alice, 1000e6, 1e27);

    vm.expectRevert(bytes(Errors.RESERVE_INACTIVE));

    vm.prank(alice);
    contracts.poolProxy.withdraw(tokenList.usdx, 1000e6, alice);
  }

  function test_reverts_withdraw_reservePaused() public {
    uint256 amount = 142e6;
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.usdx, true, 0);

    vm.expectRevert(bytes(Errors.RESERVE_PAUSED));

    vm.prank(alice);
    contracts.poolProxy.withdraw(tokenList.usdx, 122, alice);
  }

  function test_reverts_withdraw_hf_lt_lqt() public {
    vm.prank(bob);
    contracts.poolProxy.supply(tokenList.usdx, 50_000e6, bob, 0);
    uint256 amount = 1e8;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    vm.warp(block.timestamp + 1 days);
    contracts.poolProxy.borrow(tokenList.usdx, 8000e6, 2, 0, alice);
    vm.stopPrank();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      tokenList.wbtc,
      10_00,
      20_00,
      105_00
    );

    vm.expectRevert(bytes(Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD));

    vm.prank(alice);
    contracts.poolProxy.withdraw(tokenList.wbtc, 0.5e8, alice);
  }
}
