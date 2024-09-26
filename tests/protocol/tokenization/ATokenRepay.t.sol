// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken} from '../../../src/contracts/interfaces/IAToken.sol';
import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {IERC20Detailed} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

interface IVariableDebtTokenWithERC20 is IVariableDebtToken, IERC20Detailed {}

contract ATokenRepayTests is TestnetProcedures {
  IAToken public aToken;
  IVariableDebtTokenWithERC20 public variableDebtToken;

  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  function setUp() public {
    initTestEnvironment(false);

    (address aUSDX, , address variableDebtUSDX) = contracts
      .protocolDataProvider
      .getReserveTokensAddresses(tokenList.usdx);
    aToken = IAToken(aUSDX);
    variableDebtToken = IVariableDebtTokenWithERC20(variableDebtUSDX);

    // Perform setup of user positions
    uint256 mintAmount = 100_000e6;
    vm.startPrank(poolAdmin);

    usdx.mint(bob, mintAmount);
    wbtc.mint(alice, 10e8);

    vm.stopPrank();

    vm.startPrank(bob);
    usdx.approve(report.poolProxy, UINT256_MAX);

    contracts.poolProxy.supply(tokenList.usdx, mintAmount, bob, 0);

    vm.stopPrank();

    vm.startPrank(alice);

    wbtc.approve(report.poolProxy, UINT256_MAX);

    contracts.poolProxy.supply(tokenList.wbtc, 10e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 1000e6, 2, 0, alice);
    vm.warp(block.timestamp + 1 days);

    vm.stopPrank();
  }

  function test_revert_repay_withoutFunds() public {
    vm.expectRevert(stdError.arithmeticError);
    vm.prank(alice);
    contracts.poolProxy.repayWithATokens(tokenList.usdx, 500e6, 2);
  }

  function test_repay_partialDebt() public {
    vm.prank(bob);
    aToken.transfer(alice, 500e6);

    uint256 previousDebt = variableDebtToken.balanceOf(alice);
    vm.expectEmit(address(contracts.poolProxy));
    emit Repay(tokenList.usdx, alice, alice, 500e6, true);

    vm.prank(alice);
    contracts.poolProxy.repayWithATokens(tokenList.usdx, 500e6, 2);

    assertApproxEqRel(
      variableDebtToken.balanceOf(alice),
      previousDebt - 500e6,
      0.01e18,
      'Some debt should have been repaid'
    );
    assertEq(aToken.balanceOf(alice), 0, 'AToken balance should be zero');
  }

  function test_repay_allDebt() public {
    vm.prank(bob);
    aToken.transfer(alice, 1200e6);
    uint256 aTokenBalance = aToken.balanceOf(alice);
    uint256 debt = variableDebtToken.balanceOf(alice);

    vm.expectEmit();
    emit Repay(tokenList.usdx, alice, alice, debt, true);

    vm.prank(alice);
    contracts.poolProxy.repayWithATokens(tokenList.usdx, UINT256_MAX, 2);

    assertEq(variableDebtToken.balanceOf(alice), 0, 'All debt should have been repaid');
    assertEq(aToken.balanceOf(alice), aTokenBalance - debt, 'AToken balance should be lower');
  }
}
