// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from 'src/contracts/protocol/libraries/helpers/Errors.sol';
import {RwaAToken} from 'src/contracts/protocol/tokenization/RwaAToken.sol';
import {TestnetProcedures} from 'tests/utils/TestnetProcedures.sol';

contract RwaATokenAllowanceTests is TestnetProcedures {
  RwaAToken public aBuidl;

  function setUp() public {
    initTestEnvironment();
    aBuidl = RwaAToken(rwaATokenList.aBuidl);
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
}
