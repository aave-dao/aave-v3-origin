// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {MathUtils} from '../../../../src/contracts/protocol/libraries/math/MathUtils.sol';
import {MathUtilsWrapper} from '../../../../src/contracts/mocks/tests/MathUtilsWrapper.sol';

contract MathUtilsTests is Test {
  MathUtilsWrapper internal w;

  function setUp() public {
    w = new MathUtilsWrapper();
  }

  function test_constants() public view {
    assertEq(w.SECONDS_PER_YEAR(), 365 days);
  }

  function test_calculateLinearInterest() public {
    uint40 previousTimestamp = uint40(block.timestamp);
    vm.warp(block.timestamp + (365 days / 2));
    assertEq(w.calculateLinearInterest(1.0005e27, previousTimestamp), 1.50025e27);
  }

  function test_calculateCompoundInterest_1() public {
    uint40 previousTimestamp = uint40(block.timestamp);
    vm.warp(block.timestamp + (365 days / 2));
    assertEq(
      w.calculateCompoundedInterest(1.0005e27, previousTimestamp),
      1.646239361880034706419516000e27
    );
  }

  function test_calculateCompoundInterest_2() public {
    uint40 previousTimestamp = uint40(block.timestamp);
    vm.warp(block.timestamp + (365 days / 2));
    assertEq(
      w.calculateCompoundedInterest(1.0005e27, previousTimestamp, block.timestamp),
      1.646239361880034706419516000e27
    );
  }

  function test_calculateCompoundInterest_edge() public {
    vm.warp(block.timestamp + (365 days / 2));
    assertEq(
      w.calculateCompoundedInterest(1.0005e27, uint40(block.timestamp), block.timestamp),
      1e27
    );
  }
}
