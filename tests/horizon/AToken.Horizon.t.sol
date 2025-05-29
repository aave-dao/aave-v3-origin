// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {RwaAToken} from '../../src/contracts/protocol/tokenization/RwaAToken.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

import {stdError} from 'forge-std/Test.sol';

contract ATokenHorizonTests is TestnetProcedures {
  RwaAToken public aBuidl;

  function setUp() public {
    initTestEnvironment();
    aBuidl = RwaAToken(rwaATokenList.aBuidl);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.buidl, 100e6, alice, 0);
    vm.stopPrank();

    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.buidl, 1e6, carol, 0);
  }

  function test_fuzz_reverts_rwaAToken_permit_OperationNotSupported(
    address sender,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    vm.assume(sender != report.poolConfiguratorProxy); // otherwise the proxy will not fallback

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(sender);
    aBuidl.permit(owner, spender, value, deadline, v, r, s);
  }

  function test_reverts_rwaAToken_permit_OperationNotSupported() public {
    test_fuzz_reverts_rwaAToken_permit_OperationNotSupported({
      sender: alice,
      owner: alice,
      spender: bob,
      value: 100e6,
      deadline: block.timestamp + 1,
      v: 0,
      r: bytes32(0),
      s: bytes32(0)
    });
  }

  function test_fuzz_reverts_rwaAToken_approve_OperationNotSupported(
    address sender,
    address spender,
    uint256 amount
  ) public {
    vm.assume(sender != report.poolConfiguratorProxy); // otherwise the proxy will not fallback

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(sender);
    aBuidl.approve(spender, amount);
  }

  function test_reverts_rwaAToken_approve_OperationNotSupported() public {
    test_fuzz_reverts_rwaAToken_approve_OperationNotSupported({
      sender: alice,
      spender: bob,
      amount: 100e6
    });
  }

  function test_fuzz_reverts_rwaAToken_increaseAllowance_OperationNotSupported(
    address sender,
    address spender,
    uint256 addedValue
  ) public {
    vm.assume(sender != report.poolConfiguratorProxy); // otherwise the proxy will not fallback

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(sender);
    aBuidl.increaseAllowance(spender, addedValue);
  }

  function test_reverts_rwaAToken_increaseAllowance_OperationNotSupported() public {
    test_fuzz_reverts_rwaAToken_increaseAllowance_OperationNotSupported({
      sender: alice,
      spender: bob,
      addedValue: 100e6
    });
  }

  function test_fuzz_reverts_rwaAToken_decreaseAllowance_OperationNotSupported(
    address sender,
    address spender,
    uint256 subtractedValue
  ) public {
    vm.assume(sender != report.poolConfiguratorProxy); // otherwise the proxy will not fallback

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(sender);
    aBuidl.decreaseAllowance(spender, subtractedValue);
  }

  function test_reverts_rwaAToken_decreaseAllowance_OperationNotSupported() public {
    test_fuzz_reverts_rwaAToken_decreaseAllowance_OperationNotSupported({
      sender: alice,
      spender: bob,
      subtractedValue: 100e6
    });
  }

  function test_fuzz_reverts_rwaAToken_transfer_OperationNotSupported(
    address sender,
    address to,
    uint256 amount
  ) public {
    vm.assume(sender != report.poolConfiguratorProxy); // otherwise the proxy will not fallback

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(sender);
    aBuidl.transfer(to, amount);
  }

  function test_reverts_rwaAToken_transfer_OperationNotSupported() public {
    test_fuzz_reverts_rwaAToken_transfer_OperationNotSupported({sender: alice, to: bob, amount: 0});
  }

  function test_fuzz_reverts_rwaAToken_transferFrom_OperationNotSupported(
    address sender,
    address from,
    address to,
    uint256 amount
  ) public {
    vm.assume(sender != report.poolConfiguratorProxy); // otherwise the proxy will not fallback

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(sender);
    aBuidl.transferFrom(from, to, amount);
  }

  function test_reverts_rwaAToken_transferFrom_OperationNotSupported() public {
    test_fuzz_reverts_rwaAToken_transferFrom_OperationNotSupported({
      sender: rwaATokenTransferAdmin,
      from: alice,
      to: bob,
      amount: 0
    });
  }

  function test_fuzz_rwaAToken_authorizedTransfer_by_rwaATokenTransferAdmin(
    address from,
    address to,
    uint256 amount
  ) public {
    uint256 fromBalanceBefore = aBuidl.balanceOf(from);
    amount = bound(amount, 0, fromBalanceBefore);

    uint256 toBalanceBefore = aBuidl.balanceOf(to);

    vm.expectCall(
      report.poolProxy,
      abi.encodeCall(
        IPool.finalizeTransfer,
        (tokenList.buidl, from, to, amount, fromBalanceBefore, toBalanceBefore)
      )
    );

    vm.expectEmit(address(aBuidl));
    emit IERC20.Transfer(from, to, amount);

    vm.prank(rwaATokenTransferAdmin);
    bool success = aBuidl.authorizedTransfer(from, to, amount);
    assertTrue(success, 'authorizedTransfer returned false');

    assertEq(aBuidl.balanceOf(from), fromBalanceBefore - amount, 'Unexpected from balance');
    assertEq(aBuidl.balanceOf(to), toBalanceBefore + amount, 'Unexpected to balance');
  }

  function test_rwaAToken_authorizedTransfer_by_rwaATokenTransferAdmin_all() public {
    test_fuzz_rwaAToken_authorizedTransfer_by_rwaATokenTransferAdmin({
      from: alice,
      to: bob,
      amount: aBuidl.balanceOf(alice)
    });
  }

  function test_rwaAToken_authorizedTransfer_by_rwaATokenTransferAdmin_partial() public {
    test_fuzz_rwaAToken_authorizedTransfer_by_rwaATokenTransferAdmin({
      from: alice,
      to: bob,
      amount: 1
    });
  }

  function test_rwaAToken_authorizedTransfer_by_rwaATokenTransferAdmin_zero() public {
    test_fuzz_rwaAToken_authorizedTransfer_by_rwaATokenTransferAdmin({
      from: alice,
      to: bob,
      amount: 0
    });
  }

  function test_fuzz_reverts_rwaAToken_authorizedTransfer_CallerNotRwaATokenTransferAdmin(
    address sender,
    address from,
    address to,
    uint256 amount
  ) public {
    vm.assume(sender != rwaATokenTransferAdmin);
    vm.assume(sender != report.poolConfiguratorProxy); // otherwise the proxy will not fallback

    vm.expectRevert(bytes(Errors.CALLER_NOT_ATOKEN_TRANSFER_ADMIN));

    vm.prank(sender);
    aBuidl.authorizedTransfer(from, to, amount);
  }

  function test_reverts_rwaAToken_authorizedTransfer_CallerNotRwaATokenTransferAdmin() public {
    test_fuzz_reverts_rwaAToken_authorizedTransfer_CallerNotRwaATokenTransferAdmin({
      sender: carol,
      from: alice,
      to: bob,
      amount: 0
    });
  }

  function test_fuzz_reverts_rwaAToken_authorizedTransfer_NotEnoughBalance(
    address from,
    address to,
    uint256 amount
  ) public {
    amount = bound(amount, aBuidl.balanceOf(from) + 1, type(uint128).max);

    vm.expectRevert(stdError.arithmeticError);

    vm.prank(rwaATokenTransferAdmin);
    aBuidl.authorizedTransfer(from, to, amount);
  }

  function test_reverts_rwaAToken_authorizedTransfer_NotEnoughBalance() public {
    uint256 amount = 101e6;
    assertGt(amount, aBuidl.balanceOf(alice));
    test_fuzz_reverts_rwaAToken_authorizedTransfer_NotEnoughBalance(alice, bob, amount);
  }

  function test_fuzz_reverts_rwaAToken_transferOnLiquidation_OperationNotSupported(
    address sender,
    address from,
    address to,
    uint256 amount
  ) public {
    vm.assume(sender != report.poolConfiguratorProxy); // otherwise the proxy will not fallback

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(sender);
    aBuidl.transferOnLiquidation(from, to, amount);
  }

  function test_reverts_rwaAtoken_transferOnLiquidation_OperationNotSupported() public {
    test_fuzz_reverts_rwaAToken_transferOnLiquidation_OperationNotSupported({
      sender: report.poolProxy,
      from: alice,
      to: bob,
      amount: 1e6
    });
  }
}
