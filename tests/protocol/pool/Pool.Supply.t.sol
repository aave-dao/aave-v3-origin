// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetERC20, IERC20WithPermit} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {EIP712SigUtils} from '../../utils/EIP712SigUtils.sol';

contract PoolSupplyTests is TestnetProcedures {
  IPool internal pool;

  address internal aUSDX;
  address internal aWBTC;

  function setUp() public {
    initTestEnvironment();

    aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    aWBTC = contracts.poolProxy.getReserveAToken(tokenList.wbtc);
  }

  function test_first_supply() public {
    uint256 supplyAmount = 0.2e8;
    uint256 underlyingBalanceBefore = IERC20(tokenList.wbtc).balanceOf(alice);

    vm.expectEmit(report.poolProxy);
    emit IPool.ReserveUsedAsCollateralEnabled(tokenList.wbtc, alice);
    vm.expectEmit(report.poolProxy);
    emit IPool.Supply(tokenList.wbtc, alice, alice, supplyAmount, 0);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, supplyAmount, alice, 0);

    assertEq(IERC20(tokenList.wbtc).balanceOf(alice), underlyingBalanceBefore - supplyAmount);
    assertEq(IAToken(aWBTC).scaledBalanceOf(alice), supplyAmount);
  }

  function test_first_supply_on_behalf() public {
    uint256 supplyAmount = 0.2e8;
    uint256 underlyingBalanceBefore = IERC20(tokenList.wbtc).balanceOf(alice);

    vm.expectEmit(report.poolProxy);
    emit IPool.ReserveUsedAsCollateralEnabled(tokenList.wbtc, bob);
    vm.expectEmit(report.poolProxy);
    emit IPool.Supply(tokenList.wbtc, alice, bob, supplyAmount, 0);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, supplyAmount, bob, 0);

    assertEq(IERC20(tokenList.wbtc).balanceOf(alice), underlyingBalanceBefore - supplyAmount);
    assertEq(IAToken(aWBTC).scaledBalanceOf(bob), supplyAmount);
  }

  function test_supply_after_collateral_enabled() public {
    test_first_supply();
    uint256 supplyAmount = 0.4e8;
    uint256 underlyingBalanceBefore = IERC20(tokenList.wbtc).balanceOf(alice);
    uint256 scaledBalanceTokenBase = IAToken(aWBTC).scaledBalanceOf(alice);

    vm.expectEmit(report.poolProxy);
    emit IPool.Supply(tokenList.wbtc, alice, alice, supplyAmount, 0);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, supplyAmount, alice, 0);

    assertEq(IERC20(tokenList.wbtc).balanceOf(alice), underlyingBalanceBefore - supplyAmount);
    assertEq(IAToken(aWBTC).scaledBalanceOf(alice), scaledBalanceTokenBase + supplyAmount);
  }

  function test_supplyWithPermit(
    uint128 userPk,
    uint120 supplyAmount,
    uint128 underlyingBalance
  ) public {
    vm.assume(userPk != 0);
    vm.assume(supplyAmount != 0 && supplyAmount <= underlyingBalance);
    address user = vm.addr(userPk);
    deal(tokenList.wbtc, user, underlyingBalance);

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: user,
      spender: address(contracts.poolProxy),
      value: supplyAmount,
      nonce: 0,
      deadline: vm.getBlockTimestamp() + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(TestnetERC20(tokenList.wbtc).name()),
      bytes('1'),
      tokenList.wbtc
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    vm.expectEmit(report.poolProxy);
    emit IPool.ReserveUsedAsCollateralEnabled(tokenList.wbtc, user);
    vm.expectEmit(report.poolProxy);
    emit IPool.Supply(tokenList.wbtc, user, user, supplyAmount, 0);

    vm.prank(user);
    contracts.poolProxy.supplyWithPermit(
      tokenList.wbtc,
      supplyAmount,
      user,
      0,
      permit.deadline,
      v,
      r,
      s
    );

    assertEq(IERC20(tokenList.wbtc).balanceOf(user), underlyingBalance - supplyAmount);
    assertEq(IAToken(aWBTC).scaledBalanceOf(user), supplyAmount);
  }

  function test_supplyWithPermit_not_failing_if_permit_was_used(
    uint128 userPk,
    uint120 supplyAmount,
    uint128 underlyingBalance
  ) public {
    vm.assume(userPk != 0);
    vm.assume(supplyAmount != 0 && supplyAmount <= underlyingBalance);
    address user = vm.addr(userPk);
    deal(tokenList.wbtc, user, underlyingBalance);

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: user,
      spender: address(contracts.poolProxy),
      value: supplyAmount,
      nonce: 0,
      deadline: vm.getBlockTimestamp() + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(TestnetERC20(tokenList.wbtc).name()),
      bytes('1'),
      tokenList.wbtc
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    wbtc.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

    vm.prank(user);
    contracts.poolProxy.supplyWithPermit(
      tokenList.wbtc,
      supplyAmount,
      user,
      0,
      permit.deadline,
      v,
      r,
      s
    );

    assertEq(IERC20(tokenList.wbtc).balanceOf(user), underlyingBalance - supplyAmount);
    assertEq(IAToken(aWBTC).scaledBalanceOf(user), supplyAmount);
  }

  function test_supplyWithPermit_should_revert_if_permit_is_less_then_supply_amount(
    uint128 valueInPermit,
    uint128 supplyAmount
  ) public {
    uint128 userPk = 0xB000;
    vm.assume(supplyAmount != 0 && valueInPermit < supplyAmount);
    address user = vm.addr(userPk);
    deal(tokenList.wbtc, user, supplyAmount);

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: user,
      spender: address(contracts.poolProxy),
      value: supplyAmount - 1,
      nonce: 0,
      deadline: vm.getBlockTimestamp() + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(TestnetERC20(tokenList.wbtc).name()),
      bytes('1'),
      tokenList.wbtc
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    vm.prank(user);
    vm.expectRevert(bytes('ERC20: transfer amount exceeds allowance'));
    contracts.poolProxy.supplyWithPermit(
      tokenList.wbtc,
      supplyAmount,
      user,
      0,
      permit.deadline,
      v,
      r,
      s
    );
  }

  function test_deprecated_deposit() public {
    uint256 supplyAmount = 0.2e8;
    uint256 underlyingBalanceBefore = IERC20(tokenList.wbtc).balanceOf(alice);

    vm.expectEmit(report.poolProxy);
    emit IPool.ReserveUsedAsCollateralEnabled(tokenList.wbtc, alice);
    vm.expectEmit(report.poolProxy);
    emit IPool.Supply(tokenList.wbtc, alice, alice, supplyAmount, 0);

    vm.prank(alice);
    contracts.poolProxy.deposit(tokenList.wbtc, supplyAmount, alice, 0);

    assertEq(IERC20(tokenList.wbtc).balanceOf(alice), underlyingBalanceBefore - supplyAmount);
    assertEq(IAToken(aWBTC).scaledBalanceOf(alice), supplyAmount);
  }

  function test_reverts_supply_invalidAmount() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAmount.selector));

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0, alice, 0);
  }

  function test_reverts_SupplyToAToken() public {
    uint256 supplyAmount = 0.2e8;

    vm.expectRevert(abi.encodeWithSelector(Errors.SupplyToAToken.selector));

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, supplyAmount, aWBTC, 0);
  }

  function test_reverts_supply_reserveInactive() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.wbtc, false);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveInactive.selector));

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.2e8, alice, 0);
  }

  function test_reverts_supply_reservePaused() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.wbtc, true, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReservePaused.selector));

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.2e8, alice, 0);
  }

  function test_reverts_supply_reserveFrozen() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.wbtc, true);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveFrozen.selector));

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.2e8, alice, 0);
  }

  function test_reverts_supply_cap() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setSupplyCap(tokenList.wbtc, 1);

    vm.expectRevert(abi.encodeWithSelector(Errors.SupplyCapExceeded.selector));

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 2e8, alice, 0);
  }
}
