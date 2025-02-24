// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {ISequencerOracle} from '../../../src/contracts/interfaces/ISequencerOracle.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {UserConfiguration} from '../../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {PriceOracleSentinel} from '../../../src/contracts/misc/PriceOracleSentinel.sol';
import {SequencerOracle} from '../../../src/contracts/mocks/oracle/SequencerOracle.sol';
import {BorrowLogic, IERC20} from '../../../src/contracts/protocol/libraries/logic/BorrowLogic.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {EIP712SigUtils} from '../../utils/EIP712SigUtils.sol';

contract PoolRepayTests is TestnetProcedures {
  using UserConfiguration for DataTypes.UserConfigurationMap;

  IVariableDebtToken internal varDebtUSDX;
  address internal aUSDX;

  PriceOracleSentinel internal priceOracleSentinel;
  SequencerOracle internal sequencerOracleMock;

  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  function setUp() public {
    initTestEnvironment();

    (address atoken, , address variableDebtUSDX) = contracts
      .protocolDataProvider
      .getReserveTokensAddresses(tokenList.usdx);
    aUSDX = atoken;
    varDebtUSDX = IVariableDebtToken(variableDebtUSDX);

    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);
    vm.stopPrank();

    sequencerOracleMock = new SequencerOracle(poolAdmin);
    priceOracleSentinel = new PriceOracleSentinel(
      IPoolAddressesProvider(report.poolAddressesProvider),
      ISequencerOracle(address(sequencerOracleMock)),
      1 days
    );

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(false, 0);
  }

  function test_repay_full_variable_borrow() public {
    uint256 amount = 2000e6;
    uint256 borrowAmount = 800e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.warp(block.timestamp + 10 days);

    uint256 tokenBalanceBefore = usdx.balanceOf(alice);
    uint256 debtBalanceBefore = IERC20(address(varDebtUSDX)).balanceOf(alice);
    assertGt(debtBalanceBefore, 0);

    vm.expectEmit(report.poolProxy);
    emit BorrowLogic.Repay(
      tokenList.usdx,
      alice,
      alice,
      IERC20(address(varDebtUSDX)).balanceOf(alice),
      false
    );

    contracts.poolProxy.repay(tokenList.usdx, UINT256_MAX, 2, alice);
    vm.stopPrank();

    uint256 debtBalanceAfter = varDebtUSDX.scaledBalanceOf(alice);

    assertEq(debtBalanceAfter, 0);
    assertEq(usdx.balanceOf(alice), tokenBalanceBefore - debtBalanceBefore);
    assertEq(
      contracts.poolProxy.getUserConfiguration(alice).isBorrowing(
        contracts.poolProxy.getReserveData(tokenList.usdx).id
      ),
      false
    );
  }

  function test_revert_repay_full_stable_borrow() public {
    uint256 amount = 2000e6;
    uint256 borrowAmount = 800e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.warp(block.timestamp + 10 days);

    vm.expectRevert(bytes(Errors.INVALID_INTEREST_RATE_MODE_SELECTED));
    contracts.poolProxy.repay(tokenList.usdx, UINT256_MAX, 1, alice);
    vm.stopPrank();
  }

  function test_repayWithATokens_full_variable_borrow() public {
    uint256 amount = 2000e6;
    uint256 borrowAmount = 800e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.warp(block.timestamp + 10 days);

    uint256 tokenBalanceBefore = IERC20(aUSDX).balanceOf(alice);
    uint256 debtBalanceBefore = IERC20(address(varDebtUSDX)).balanceOf(alice);
    assertGt(debtBalanceBefore, borrowAmount);

    vm.expectEmit(report.poolProxy);
    emit BorrowLogic.Repay(
      tokenList.usdx,
      alice,
      alice,
      IERC20(address(varDebtUSDX)).balanceOf(alice),
      true
    );

    contracts.poolProxy.repayWithATokens(tokenList.usdx, UINT256_MAX, 2);
    vm.stopPrank();

    uint256 debtBalanceAfter = varDebtUSDX.scaledBalanceOf(alice);

    assertEq(debtBalanceAfter, 0);
    assertEq(IERC20(aUSDX).balanceOf(alice), tokenBalanceBefore - debtBalanceBefore);
    assertEq(
      contracts.poolProxy.getUserConfiguration(alice).isBorrowing(
        contracts.poolProxy.getReserveData(tokenList.usdx).id
      ),
      false
    );
  }

  function test_repayWithATokens_full_collateral_variable_borrow() public {
    uint256 amount = 2000e6;
    uint256 borrowAmount = 2000e6;
    vm.startPrank(alice);
    // supply enough collateral to borrow out everything
    contracts.poolProxy.supply(tokenList.weth, IERC20(tokenList.weth).balanceOf(alice), alice, 0);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.warp(block.timestamp + 10 days);

    uint256 tokenBalanceBefore = IERC20(aUSDX).balanceOf(alice);
    uint256 debtBalanceBefore = IERC20(address(varDebtUSDX)).balanceOf(alice);
    assertGt(debtBalanceBefore, borrowAmount);

    vm.expectEmit(report.poolProxy);
    emit BorrowLogic.Repay(
      tokenList.usdx,
      alice,
      alice,
      IERC20(address(aUSDX)).balanceOf(alice),
      true
    );

    contracts.poolProxy.repayWithATokens(tokenList.usdx, UINT256_MAX, 2);
    vm.stopPrank();

    uint256 debtBalanceAfter = IERC20(address(varDebtUSDX)).balanceOf(alice);

    assertApproxEqAbs(debtBalanceAfter, debtBalanceBefore - tokenBalanceBefore, 1);
    assertEq(IERC20(aUSDX).balanceOf(alice), 0);
    assertEq(
      contracts.poolProxy.getUserConfiguration(alice).isBorrowing(
        contracts.poolProxy.getReserveData(tokenList.usdx).id
      ),
      true
    );
    assertEq(
      contracts.poolProxy.getUserConfiguration(alice).isUsingAsCollateral(
        contracts.poolProxy.getReserveData(tokenList.usdx).id
      ),
      false
    );
  }

  function test_repayWithATokens_fuzz_collateral_variable_borrow(
    uint256 repayAmount,
    uint32 timeDelta
  ) public {
    uint256 amount = 2000e6;
    vm.assume(repayAmount <= amount && repayAmount > 0);
    uint256 borrowAmount = 2000e6;
    vm.startPrank(alice);
    // supply enough collateral to borrow out everything
    contracts.poolProxy.supply(tokenList.weth, IERC20(tokenList.weth).balanceOf(alice), alice, 0);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.warp(block.timestamp + timeDelta);

    uint256 debtBalanceBefore = IERC20(address(varDebtUSDX)).balanceOf(alice);

    vm.expectEmit(report.poolProxy);
    emit BorrowLogic.Repay(tokenList.usdx, alice, alice, repayAmount, true);

    contracts.poolProxy.repayWithATokens(tokenList.usdx, repayAmount, 2);
    vm.stopPrank();

    uint256 debtBalanceAfter = IERC20(address(varDebtUSDX)).balanceOf(alice);
    uint256 collateralBalanceAfter = IERC20(aUSDX).balanceOf(alice);

    assertApproxEqAbs(debtBalanceAfter, debtBalanceBefore - repayAmount, 1);
    assertEq(
      contracts.poolProxy.getUserConfiguration(alice).isBorrowing(
        contracts.poolProxy.getReserveData(tokenList.usdx).id
      ),
      debtBalanceAfter == 0 ? false : true
    );
    assertEq(
      contracts.poolProxy.getUserConfiguration(alice).isUsingAsCollateral(
        contracts.poolProxy.getReserveData(tokenList.usdx).id
      ),
      collateralBalanceAfter == 0 ? false : true
    );
  }

  function test_repayWithPermit(
    uint128 userPk,
    uint128 supplyAmount,
    uint128 underlyingBalance,
    uint128 borrowAmount,
    uint128 repayAmount
  ) public {
    vm.assume(userPk != 0);
    underlyingBalance = uint128(bound(underlyingBalance, 2, type(uint120).max));
    supplyAmount = uint128(bound(supplyAmount, 2, underlyingBalance));
    borrowAmount = uint128(bound(borrowAmount, 1, supplyAmount / 2));
    repayAmount = uint128(bound(repayAmount, 1, borrowAmount));
    address user = vm.addr(userPk);
    deal(tokenList.usdx, user, underlyingBalance);
    vm.startPrank(user);

    usdx.approve(address(contracts.poolProxy), supplyAmount);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, user, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, user);
    vm.warp(block.timestamp + 10 days);

    uint256 underlyingBalanceBeforeRepayment = IERC20(tokenList.usdx).balanceOf(user);
    uint256 debtBalanceBefore = IERC20(address(varDebtUSDX)).balanceOf(user);

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: user,
      spender: address(contracts.poolProxy),
      value: repayAmount,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(TestnetERC20(tokenList.usdx).name()),
      bytes('1'),
      tokenList.usdx
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    vm.expectEmit(report.poolProxy);
    emit BorrowLogic.Repay(tokenList.usdx, user, user, repayAmount, false);

    contracts.poolProxy.repayWithPermit(
      tokenList.usdx,
      repayAmount,
      2,
      user,
      permit.deadline,
      v,
      r,
      s
    );
    vm.stopPrank();

    assertEq(usdx.balanceOf(user), underlyingBalanceBeforeRepayment - repayAmount);
    assertApproxEqAbs(
      IERC20(address(varDebtUSDX)).balanceOf(user),
      debtBalanceBefore - repayAmount,
      1
    );
  }

  function test_repayWithPermit_not_failing_if_permit_was_used(
    uint128 userPk,
    uint128 supplyAmount,
    uint128 underlyingBalance,
    uint128 borrowAmount,
    uint128 repayAmount
  ) public {
    vm.assume(userPk != 0);
    underlyingBalance = uint128(bound(underlyingBalance, 2, type(uint120).max));
    supplyAmount = uint128(bound(supplyAmount, 2, underlyingBalance));
    borrowAmount = uint128(bound(borrowAmount, 1, supplyAmount / 2));
    repayAmount = uint128(bound(repayAmount, 1, borrowAmount));
    address user = vm.addr(userPk);
    deal(tokenList.usdx, user, underlyingBalance);
    vm.startPrank(user);

    usdx.approve(address(contracts.poolProxy), supplyAmount);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, user, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, user);
    vm.warp(block.timestamp + 10 days);

    uint256 underlyingBalanceBeforeRepayment = IERC20(tokenList.usdx).balanceOf(user);
    uint256 debtBalanceBefore = IERC20(address(varDebtUSDX)).balanceOf(user);

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: user,
      spender: address(contracts.poolProxy),
      value: repayAmount,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(TestnetERC20(tokenList.usdx).name()),
      bytes('1'),
      tokenList.usdx
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    usdx.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

    vm.expectEmit(report.poolProxy);
    emit BorrowLogic.Repay(tokenList.usdx, user, user, repayAmount, false);

    contracts.poolProxy.repayWithPermit(
      tokenList.usdx,
      repayAmount,
      2,
      user,
      permit.deadline,
      v,
      r,
      s
    );
    vm.stopPrank();

    assertEq(usdx.balanceOf(user), underlyingBalanceBeforeRepayment - repayAmount);
    assertApproxEqAbs(
      IERC20(address(varDebtUSDX)).balanceOf(user),
      debtBalanceBefore - repayAmount,
      1
    );
  }

  function test_repayWithPermit_should_revert_if_permit_is_less_then_repay_amount(
    uint128 userPk,
    uint128 supplyAmount,
    uint128 underlyingBalance,
    uint128 borrowAmount,
    uint128 repayAmount
  ) public {
    vm.assume(userPk != 0);
    underlyingBalance = uint128(bound(underlyingBalance, 2, type(uint120).max));
    supplyAmount = uint128(bound(supplyAmount, 2, underlyingBalance));
    borrowAmount = uint128(bound(borrowAmount, 1, supplyAmount / 2));
    repayAmount = uint128(bound(repayAmount, 1, borrowAmount));
    address user = vm.addr(userPk);
    deal(tokenList.usdx, user, underlyingBalance);
    vm.startPrank(user);

    usdx.approve(address(contracts.poolProxy), supplyAmount);
    contracts.poolProxy.supply(tokenList.usdx, supplyAmount, user, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, user);
    vm.warp(block.timestamp + 10 days);

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: user,
      spender: address(contracts.poolProxy),
      value: repayAmount - 1,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(TestnetERC20(tokenList.usdx).name()),
      bytes('1'),
      tokenList.usdx
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    vm.expectRevert(bytes('ERC20: transfer amount exceeds allowance'));
    contracts.poolProxy.repayWithPermit(
      tokenList.usdx,
      repayAmount,
      2,
      user,
      permit.deadline,
      v,
      r,
      s
    );
    vm.stopPrank();
  }

  function test_full_repay_borrow_variable_in_isolation() public {
    uint256 borrowAmount = 100e6;
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000_00);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    vm.expectEmit(address(contracts.poolProxy));
    emit IsolationModeTotalDebtUpdated(tokenList.wbtc, 100_00);

    // Perform borrow in isolated position
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);

    uint256 balanceBefore = usdx.balanceOf(alice);
    uint256 debtBalanceBefore = varDebtUSDX.scaledBalanceOf(alice);

    vm.expectEmit(report.poolProxy);
    emit IsolationModeTotalDebtUpdated(tokenList.wbtc, 0);

    vm.expectEmit(report.poolProxy);
    emit BorrowLogic.Repay(
      tokenList.usdx,
      alice,
      alice,
      IERC20(address(varDebtUSDX)).balanceOf(alice),
      false
    );

    contracts.poolProxy.repay(tokenList.usdx, UINT256_MAX, 2, alice);
    vm.stopPrank();

    uint256 debtBalanceAfter = varDebtUSDX.scaledBalanceOf(alice);

    assertEq(debtBalanceAfter, 0);
    assertEq(usdx.balanceOf(alice), balanceBefore - debtBalanceBefore);
    assertEq(
      contracts.poolProxy.getUserConfiguration(alice).isBorrowing(
        contracts.poolProxy.getReserveData(tokenList.usdx).id
      ),
      false
    );
  }

  function test_partial_repay_borrow_variable_in_isolation() public {
    uint256 borrowAmount = 100e6;
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000_00);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    vm.expectEmit(address(contracts.poolProxy));
    emit IsolationModeTotalDebtUpdated(tokenList.wbtc, 100_00);

    // Perform borrow in isolated position
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);

    uint256 balanceBefore = usdx.balanceOf(alice);
    uint256 debtBalanceBefore = varDebtUSDX.scaledBalanceOf(alice);
    uint256 repayAmount = varDebtUSDX.scaledBalanceOf(alice) / 2;
    uint256 isolationDebtRepaid = repayAmount /
      (10 ** (6 - contracts.protocolDataProvider.getDebtCeilingDecimals()));
    uint256 isolationModeTotalDebt = contracts
      .poolProxy
      .getReserveData(tokenList.wbtc)
      .isolationModeTotalDebt;

    vm.expectEmit(report.poolProxy);
    emit IsolationModeTotalDebtUpdated(
      tokenList.wbtc,
      isolationModeTotalDebt - isolationDebtRepaid
    );

    vm.expectEmit(report.poolProxy);
    emit BorrowLogic.Repay(tokenList.usdx, alice, alice, repayAmount, false);

    contracts.poolProxy.repay(tokenList.usdx, repayAmount, 2, alice);
    vm.stopPrank();

    uint256 debtBalanceAfter = varDebtUSDX.scaledBalanceOf(alice);

    assertEq(debtBalanceAfter, debtBalanceBefore - repayAmount);
    assertEq(usdx.balanceOf(alice), balanceBefore - repayAmount);
    assertEq(
      contracts.poolProxy.getUserConfiguration(alice).isBorrowing(
        contracts.poolProxy.getReserveData(tokenList.usdx).id
      ),
      true
    );
    assertEq(
      contracts.poolProxy.getReserveData(tokenList.wbtc).isolationModeTotalDebt,
      isolationModeTotalDebt - isolationDebtRepaid
    );
  }

  function test_reverts_borrow_invalidAmount() public {
    vm.expectRevert(bytes(Errors.INVALID_AMOUNT));

    vm.prank(alice);
    contracts.poolProxy.repay(tokenList.usdx, 0, 2, alice);
  }

  function test_reverts_borrow_reserveInactive() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.wbtc, false);

    vm.expectRevert(bytes(Errors.RESERVE_INACTIVE));

    vm.prank(alice);
    contracts.poolProxy.repay(tokenList.wbtc, UINT256_MAX, 2, alice);
  }

  function test_reverts_borrow_reservePaused() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.wbtc, true, 0);

    vm.expectRevert(bytes(Errors.RESERVE_PAUSED));

    vm.prank(alice);
    contracts.poolProxy.repay(tokenList.wbtc, UINT256_MAX, 2, alice);
  }

  function test_reverts_repay_no_debt() public {
    vm.expectRevert(bytes(Errors.NO_DEBT_OF_SELECTED_TYPE));

    vm.prank(alice);
    contracts.poolProxy.repay(tokenList.wbtc, UINT256_MAX, 2, alice);
  }

  function test_reverts_no_explicit_repay_on_behalf() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 1000e6, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 100e6, 2, 0, alice);
    vm.stopPrank();

    vm.expectRevert(bytes(Errors.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF));

    vm.prank(bob);
    contracts.poolProxy.repay(tokenList.usdx, UINT256_MAX, 2, alice);
  }
}
