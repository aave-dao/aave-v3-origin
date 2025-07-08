// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {MathUtils} from '../../../../src/contracts/protocol/libraries/math/MathUtils.sol';

contract MathUtilsTests is Test {
  function test_constants() public pure {
    assertEq(MathUtils.SECONDS_PER_YEAR, 365 days);
  }

  function test_calculateLinearInterest() public {
    uint40 previousTimestamp = uint40(vm.getBlockTimestamp());
    vm.warp(vm.getBlockTimestamp() + (365 days * 7));
    assertEq(MathUtils.calculateLinearInterest(0.08e27, previousTimestamp), 1.56e27);
  }

  function test_calculateCompoundInterest_1() public {
    uint40 previousTimestamp = uint40(vm.getBlockTimestamp());
    vm.warp(vm.getBlockTimestamp() + (365 days * 7));

    // calculations compound interest using the ideal formula - e^(rate per year * number of years)
    // 8% per year, passed 7 years:
    // e^(0.08 * 7) = 1.75067250029610108254997643500185205749211144457507553975736492360100362...

    assertApproxEqRel(
      // 8% per year, passed 7 years
      MathUtils.calculateCompoundedInterest(0.08e27, previousTimestamp),
      1.750672500296101082549976435e27,
      0.003e18 // max 0.3% deviation
    );
  }

  function test_calculateCompoundInterest_2() public {
    uint40 previousTimestamp = uint40(vm.getBlockTimestamp());
    vm.warp(vm.getBlockTimestamp() + (365 days * 7));

    // calculations compound interest using the ideal formula - e^(rate per year * number of years)
    // 8% per year, passed 7 years:
    // e^(0.08 * 7) = 1.75067250029610108254997643500185205749211144457507553975736492360100362...

    assertApproxEqRel(
      // 8% per year, passed 7 years
      MathUtils.calculateCompoundedInterest(0.08e27, previousTimestamp, vm.getBlockTimestamp()),
      1.750672500296101082549976435e27,
      0.003e18 // max 0.3% deviation
    );
  }

  function test_calculateCompoundInterest_edge() public {
    vm.warp(vm.getBlockTimestamp() + (365 days * 7));
    assertEq(
      MathUtils.calculateCompoundedInterest(
        0.08e27,
        uint40(vm.getBlockTimestamp()),
        vm.getBlockTimestamp()
      ),
      1e27
    );
  }

  function test_calculateCompoundInterest_shouldNotOverflow() public {
    uint40 currentTimestamp = uint40(vm.getBlockTimestamp());
    uint40 calculationTimestamp = currentTimestamp + 365 days * 10_000;

    // calculations compound interest using the ideal formula - e^(rate per year * number of years)
    // 100_000% per year = 1_000 * 100, passed 10_000 years:
    // e^(1_000 * 10_000) = 6.5922325346184394895608861310659088446667722661221381641234330770... × 10^4342944

    // The current formula in the contract returns:
    // 1.66666716666676666667 × 10^20
    // This happens because the contract uses a polynomial approximation of the ideal formula
    // and on big numbers the ideal formula with exponential function has much more speed.
    // Used approximation in contracts is not precise enough on such big numbers.
    //
    // But we can be sure that the current formula in contracts can't overflow on such big numbers
    // and we can use unchecked arithmetics to save gas.

    assertEq(
      MathUtils.calculateCompoundedInterest(1_000e27, currentTimestamp, calculationTimestamp),
      166666716666676666667666666666666600000000000000
    );
  }
}
