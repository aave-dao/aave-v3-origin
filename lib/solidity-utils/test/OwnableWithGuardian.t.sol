// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {OwnableWithGuardian} from '../src/contracts/access-control/OwnableWithGuardian.sol';

contract ImplOwnableWithGuardian is OwnableWithGuardian {}

contract TestOfOwnableWithGuardian is Test {
  OwnableWithGuardian public withGuardian;

  function setUp() public {
    withGuardian = new ImplOwnableWithGuardian();
  }

  function testConstructorLogic() external {
    assertEq(withGuardian.owner(), address(this));
    assertEq(withGuardian.guardian(), address(this));
  }

  function testGuardianUpdate(address guardian) external {
    withGuardian.updateGuardian(guardian);
  }

  function testGuardianUpdateNoAccess(address guardian) external {
    vm.assume(guardian != address(this));

    vm.prank(guardian);
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    withGuardian.updateGuardian(guardian);
  }
}
