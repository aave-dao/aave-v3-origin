// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from 'src/contracts/protocol/libraries/helpers/Errors.sol';
import {IRwaAToken} from 'src/contracts/interfaces/IRwaAToken.sol';
import {TestnetProcedures} from 'tests/utils/TestnetProcedures.sol';

contract PoolBorrowRwaTests is TestnetProcedures {
  function setUp() public {
    initTestEnvironment();

    // set buidl borrowing config
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveBorrowing(tokenList.buidl, true);

    _seedLiquidity({token: tokenList.buidl, amount: 50_000e6, isRwa: true});
  }

  function test_fuzz_reverts_borrow_TransferUnderlyingTo_OperationNotSupported(
    uint256 borrowAmount
  ) public {
    borrowAmount = bound(borrowAmount, 1, 8_000e6);

    vm.prank(bob);
    contracts.poolProxy.supply(tokenList.wbtc, 0.4e8, bob, 0);

    vm.expectCall(
      rwaATokenList.aBuidl,
      abi.encodeCall(IRwaAToken.transferUnderlyingTo, (bob, borrowAmount))
    );

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED), rwaATokenList.aBuidl);

    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.buidl, borrowAmount, 2, 0, bob);
  }
}
