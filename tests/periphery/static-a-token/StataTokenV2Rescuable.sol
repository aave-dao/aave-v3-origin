// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IRescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
import {BaseTest} from './TestBase.sol';

contract StataTokenV2RescuableTest is BaseTest {
  function test_whoCanRescue() external view {
    assertEq(IRescuable(address(stataTokenV2)).whoCanRescue(), poolAdmin);
  }

  function test_rescuable_shouldRevertForInvalidCaller() external {
    deal(tokenList.usdx, address(stataTokenV2), 1 ether);
    vm.expectRevert('ONLY_RESCUE_GUARDIAN');
    IRescuable(address(stataTokenV2)).emergencyTokenTransfer(
      tokenList.usdx,
      address(this),
      1 ether
    );
  }

  function test_rescuable_shouldSuceedForOwner() external {
    deal(tokenList.usdx, address(stataTokenV2), 1 ether);
    vm.startPrank(poolAdmin);
    IRescuable(address(stataTokenV2)).emergencyTokenTransfer(
      tokenList.usdx,
      address(this),
      1 ether
    );
  }
}
