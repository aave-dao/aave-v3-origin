// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveOracle} from '../../src/contracts/misc/AaveOracle.sol';
import {WrappedTokenGatewayV3} from '../../src/contracts/helpers/WrappedTokenGatewayV3.sol';
import {AaveProtocolDataProvider} from '../../src/contracts/helpers/AaveProtocolDataProvider.sol';
import {AToken} from '../../src/contracts/protocol/tokenization/AToken.sol';
import {VariableDebtToken} from '../../src/contracts/protocol/tokenization/VariableDebtToken.sol';
import {DataTypes} from '../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {EIP712SigUtils} from '../utils/EIP712SigUtils.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract WrappedTokenGatewayTests is TestnetProcedures {
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );

  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  AaveOracle internal aaveOracle;
  WrappedTokenGatewayV3 internal wrappedTokenGatewayV3;

  AToken internal aWEth;
  VariableDebtToken internal wEthVariableDebtToken;
  AToken internal aUsdx;
  VariableDebtToken internal usdxVariableDebtToken;
  uint256 internal depositSize = 5e18;
  uint256 internal usdxSize = 10000e18;

  function setUp() public {
    initTestEnvironment(false);

    // Give eth to the users in order call the payable functions
    vm.deal(alice, 100e18);
    vm.deal(bob, 100e18);

    aaveOracle = AaveOracle(report.aaveOracle);
    assertTrue(
      report.wrappedTokenGateway != address(0),
      'WrappedTokenGateway missing at deployment'
    );
    wrappedTokenGatewayV3 = WrappedTokenGatewayV3(payable(report.wrappedTokenGateway));
    contracts.protocolDataProvider = AaveProtocolDataProvider(report.protocolDataProvider);
    (address aWEthAddr, , address wEthVariableDebt) = contracts
      .protocolDataProvider
      .getReserveTokensAddresses(tokenList.weth);
    aWEth = AToken(aWEthAddr);
    wEthVariableDebtToken = VariableDebtToken(wEthVariableDebt);
    (address aUsdxAddr, , address usdxVariableDebt) = contracts
      .protocolDataProvider
      .getReserveTokensAddresses(tokenList.usdx);
    aUsdx = AToken(aUsdxAddr);
    usdxVariableDebtToken = VariableDebtToken(usdxVariableDebt);
  }

  function test_getWETHAddress() public view {
    assertEq(wrappedTokenGatewayV3.getWETHAddress(), tokenList.weth);
  }

  function test_depositNativeEthInPool() public {
    vm.startPrank(alice);
    vm.expectEmit();
    emit ReserveUsedAsCollateralEnabled(tokenList.weth, alice);
    vm.expectEmit();
    emit Supply(tokenList.weth, address(wrappedTokenGatewayV3), alice, depositSize, 0);
    wrappedTokenGatewayV3.depositETH{value: depositSize}(report.poolProxy, alice, 0);
    vm.stopPrank();

    assertEq(
      aWEth.balanceOf(alice),
      depositSize,
      'The a token balance should match the deposit size'
    );
  }

  function test_withdrawEth_partial() public {
    uint256 partialWithdraw = depositSize / 2;

    test_depositNativeEthInPool();

    vm.startPrank(alice);

    aWEth.approve(report.wrappedTokenGateway, partialWithdraw);

    assertEq(
      aWEth.allowance(alice, report.wrappedTokenGateway),
      partialWithdraw,
      'The allowance should be equal to the partial withdraw'
    );

    uint256 userEthBalanceBefore = alice.balance;
    vm.expectEmit();
    emit Withdraw(
      tokenList.weth,
      report.wrappedTokenGateway,
      report.wrappedTokenGateway,
      partialWithdraw
    );
    wrappedTokenGatewayV3.withdrawETH(report.poolProxy, partialWithdraw, alice);
    vm.stopPrank();

    uint256 userEthBalanceAfter = alice.balance;

    assertEq(
      userEthBalanceAfter - userEthBalanceBefore,
      partialWithdraw,
      'The user balance should increase by the partial withdraw'
    );
    assertEq(
      aWEth.balanceOf(alice),
      partialWithdraw,
      'The user aToken balance should decrease by half'
    );
  }

  function test_withdrawEth_permit() public {
    test_depositNativeEthInPool();

    uint256 withdrawAmount = 0.6e18;

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: address(wrappedTokenGatewayV3),
      value: withdrawAmount,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aWEth.name()),
      bytes('1'),
      address(aWEth)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    uint256 userEthBalanceBefore = alice.balance;

    vm.expectEmit();
    emit Withdraw(
      tokenList.weth,
      report.wrappedTokenGateway,
      report.wrappedTokenGateway,
      withdrawAmount
    );

    vm.prank(alice);
    wrappedTokenGatewayV3.withdrawETHWithPermit(
      report.poolProxy,
      withdrawAmount,
      alice,
      permit.deadline,
      v,
      r,
      s
    );

    assertEq(alice.balance, userEthBalanceBefore + withdrawAmount);
  }

  function test_withdrawEth_permit_full() public {
    test_depositNativeEthInPool();

    uint256 withdrawAmount = UINT256_MAX;

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: address(wrappedTokenGatewayV3),
      value: withdrawAmount,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aWEth.name()),
      bytes('1'),
      address(aWEth)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    uint256 userEthBalanceBefore = alice.balance;
    uint256 userATokenBalance = aWEth.balanceOf(alice);
    vm.expectEmit();
    emit Withdraw(
      tokenList.weth,
      report.wrappedTokenGateway,
      report.wrappedTokenGateway,
      userATokenBalance
    );

    vm.prank(alice);
    wrappedTokenGatewayV3.withdrawETHWithPermit(
      report.poolProxy,
      withdrawAmount,
      alice,
      permit.deadline,
      v,
      r,
      s
    );

    assertEq(alice.balance, userEthBalanceBefore + userATokenBalance);
  }

  function test_withdrawEth_permit_frontrunRegression() public {
    test_depositNativeEthInPool();

    uint256 withdrawAmount = 0.6e18;

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: address(wrappedTokenGatewayV3),
      value: withdrawAmount,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aWEth.name()),
      bytes('1'),
      address(aWEth)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    uint256 userEthBalanceBefore = alice.balance;

    vm.prank(alice);
    aWEth.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

    // should not revert if permit is already executed
    vm.prank(alice);
    wrappedTokenGatewayV3.withdrawETHWithPermit(
      report.poolProxy,
      withdrawAmount,
      alice,
      permit.deadline,
      v,
      r,
      s
    );
  }

  function test_withdrawEth_full() public {
    uint256 fullWithdraw = depositSize;

    test_depositNativeEthInPool();

    vm.startPrank(alice);

    aWEth.approve(report.wrappedTokenGateway, fullWithdraw);

    assertEq(
      aWEth.allowance(alice, report.wrappedTokenGateway),
      fullWithdraw,
      'The allowance should be equal to the full withdraw'
    );

    uint256 userEthBalanceBefore = alice.balance;
    vm.expectEmit();
    emit Withdraw(
      tokenList.weth,
      report.wrappedTokenGateway,
      report.wrappedTokenGateway,
      fullWithdraw
    );
    wrappedTokenGatewayV3.withdrawETH(report.poolProxy, UINT256_MAX, alice);
    vm.stopPrank();

    uint256 userEthBalanceAfter = alice.balance;

    assertEq(
      userEthBalanceAfter - userEthBalanceBefore,
      fullWithdraw,
      'The user balance should increase by the full withdraw'
    );
    assertEq(aWEth.balanceOf(alice), 0, 'The user aToken balance should be 0');
  }

  function test_borrowVariableDebtWeth_repayWithEth() public {
    uint256 borrowSize = 1e18;
    uint256 partialRepayment = borrowSize / 2;

    test_depositNativeEthInPool();

    vm.prank(poolAdmin);
    usdx.mint(bob, usdxSize);

    assertEq(usdx.balanceOf(bob), usdxSize, 'The balance of the user should match the minted size');

    vm.startPrank(bob);
    usdx.approve(address(contracts.poolProxy), usdxSize);

    vm.expectEmit();
    emit ReserveUsedAsCollateralEnabled(tokenList.usdx, bob);
    vm.expectEmit();
    emit Supply(tokenList.usdx, bob, bob, usdxSize, 0);
    contracts.poolProxy.deposit(address(usdx), usdxSize, bob, 0);

    assertEq(
      aUsdx.balanceOf(bob),
      usdxSize,
      'The deposited balance should match the user AToken balance'
    );
    contracts.poolProxy.borrow(tokenList.weth, borrowSize, 2, 0, bob);

    assertEq(
      wEthVariableDebtToken.balanceOf(bob),
      borrowSize,
      'The users debt variable token balance should match the borrowed size'
    );

    vm.expectEmit(address(contracts.poolProxy));
    emit Repay(tokenList.weth, bob, address(wrappedTokenGatewayV3), partialRepayment, false);
    // Partial repayment
    wrappedTokenGatewayV3.repayETH{value: partialRepayment}(
      report.poolProxy,
      partialRepayment,
      bob
    );

    assertEq(
      wEthVariableDebtToken.balanceOf(bob),
      partialRepayment,
      'The users debt should be half of the initial borrow'
    );

    vm.expectEmit(address(contracts.poolProxy));
    emit Repay(tokenList.weth, bob, address(wrappedTokenGatewayV3), partialRepayment, false);
    // Full repayment
    wrappedTokenGatewayV3.repayETH{value: partialRepayment}(report.poolProxy, type(uint).max, bob);

    assertEq(wEthVariableDebtToken.balanceOf(bob), 0, 'The users debt should be 0');

    // Withdraw usdx
    usdx.approve(address(contracts.poolProxy), usdxSize);

    vm.expectEmit();
    emit Withdraw(address(usdx), bob, bob, usdxSize);
    contracts.poolProxy.withdraw(address(usdx), usdxSize, bob);
    vm.stopPrank();

    assertEq(usdx.balanceOf(bob), usdxSize, 'The user balance should match the withdrawn amount');
  }

  /**
   * @dev regression test
   * In a previous version of the WrappedTokenGateway the transaction reverted when there was a surplus on msg.value
   */
  function test_borrowVariableDebtWeth_repayWithEth_mismatchedValues() public {
    uint256 borrowSize = 1e18;
    uint256 partialRepayment = borrowSize / 2;

    test_depositNativeEthInPool();

    vm.prank(poolAdmin);
    usdx.mint(bob, usdxSize);

    assertEq(usdx.balanceOf(bob), usdxSize, 'The balance of the user should match the minted size');

    vm.startPrank(bob);
    usdx.approve(address(contracts.poolProxy), usdxSize);

    vm.expectEmit();
    emit ReserveUsedAsCollateralEnabled(tokenList.usdx, bob);
    vm.expectEmit();
    emit Supply(tokenList.usdx, bob, bob, usdxSize, 0);
    contracts.poolProxy.deposit(address(usdx), usdxSize, bob, 0);

    assertEq(
      aUsdx.balanceOf(bob),
      usdxSize,
      'The deposited balance should match the user AToken balance'
    );
    contracts.poolProxy.borrow(tokenList.weth, borrowSize, 2, 0, bob);

    assertEq(
      wEthVariableDebtToken.balanceOf(bob),
      borrowSize,
      'The users debt variable token balance should match the borrowed size'
    );

    vm.expectEmit(address(contracts.poolProxy));
    emit Repay(tokenList.weth, bob, address(wrappedTokenGatewayV3), partialRepayment, false);
    // Partial repayment with surplus on msg.value
    wrappedTokenGatewayV3.repayETH{value: partialRepayment + 1}(
      report.poolProxy,
      partialRepayment,
      bob
    );

    assertEq(
      wEthVariableDebtToken.balanceOf(bob),
      partialRepayment,
      'The users debt should be half of the initial borrow'
    );

    vm.expectEmit(address(contracts.poolProxy));
    emit Repay(tokenList.weth, bob, address(wrappedTokenGatewayV3), partialRepayment, false);
    // Full repayment
    wrappedTokenGatewayV3.repayETH{value: partialRepayment}(report.poolProxy, type(uint).max, bob);
  }

  function test_borrowDelegateApprove_repay() public {
    uint256 borrowSize = 1e18;

    test_depositNativeEthInPool();

    vm.startPrank(alice);

    wEthVariableDebtToken.approveDelegation(address(wrappedTokenGatewayV3), borrowSize);

    wrappedTokenGatewayV3.borrowETH(address(contracts.poolProxy), borrowSize, 0);

    assertEq(
      wEthVariableDebtToken.balanceOf(alice),
      borrowSize,
      'The user variable debt balance should match the borrowed size'
    );

    // Full repayment
    wrappedTokenGatewayV3.repayETH{value: borrowSize}(report.poolProxy, type(uint).max, alice);
    vm.stopPrank();

    assertEq(wEthVariableDebtToken.balanceOf(alice), 0, 'The users debt should be 0');
  }

  // The only allowed address to send ETH to the wrappedTokenGatewayV3 is the WETH contract
  function test_sendEth_revert() public {
    vm.expectRevert('Receive not allowed');
    (bool success, ) = address(wrappedTokenGatewayV3).call{value: 1e18}('');
    success;
  }

  function test_sendEthFallback_revert() public {
    vm.expectRevert('Fallback not allowed');
    (bool success, ) = address(wrappedTokenGatewayV3).call{value: 1e18}('sampleFunction()');
    success;
  }

  function test_fallback_revert() public {
    vm.expectRevert('Fallback not allowed');
    (bool success, ) = address(wrappedTokenGatewayV3).call('sampleFunction()');
    success;
  }

  function test_ownerCanRescueTokens() public {
    uint256 mintSize = 10e18;

    vm.prank(poolAdmin);
    usdx.mint(alice, mintSize);
    assertEq(usdx.balanceOf(alice), mintSize, 'The user balance should reflect the minted size');

    vm.prank(alice);
    usdx.transfer(address(wrappedTokenGatewayV3), mintSize);

    assertEq(
      usdx.balanceOf(alice),
      0,
      'The user should have lost the funds due to the improper transfer'
    );

    vm.prank(poolAdmin);
    wrappedTokenGatewayV3.emergencyTokenTransfer(address(usdx), alice, mintSize);

    assertEq(usdx.balanceOf(alice), mintSize, 'The user should have the initial balance back');
  }

  function test_ownerCanRescueEth() public {
    uint256 lostAmount = 1e18;
    vm.deal(address(wrappedTokenGatewayV3), lostAmount);

    uint256 balanceBefore = alice.balance;

    vm.prank(poolAdmin);
    // Recover the funds from the contract and sends back to the user
    wrappedTokenGatewayV3.emergencyEtherTransfer(alice, lostAmount);

    assertEq(
      alice.balance,
      balanceBefore + lostAmount,
      'The user should have recovered the lost amount'
    );
    assertEq(
      address(wrappedTokenGatewayV3).balance,
      0,
      'The balance of the wrapped token gateway contract should now be 0'
    );
  }
}
