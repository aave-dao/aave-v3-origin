// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {WadRayMath} from '../../../../src/contracts/protocol/libraries/math/WadRayMath.sol';

/// forge-config: default.allow_internal_expect_revert = true
contract WadRayMathTests is Test {
  function test_constants() public pure {
    assertEq(WadRayMath.WAD, 1e18, 'wad');
    assertEq(WadRayMath.HALF_WAD, 1e18 / 2, 'half wad');
    assertEq(WadRayMath.RAY, 1e27, 'ray');
    assertEq(WadRayMath.HALF_RAY, 1e27 / 2, 'half_ray');
  }

  function test_wadMul_edge() public pure {
    assertEq(WadRayMath.wadMul(0, 1e18), 0);
    assertEq(WadRayMath.wadMul(1e18, 0), 0);
    assertEq(WadRayMath.wadMul(0, 0), 0);
  }

  function test_wadMul_fuzzing(uint256 a, uint256 b) public {
    if ((b == 0 || (a > (type(uint256).max - WadRayMath.HALF_WAD) / b) == false) == false) {
      vm.expectRevert();
      WadRayMath.wadMul(a, b);
      return;
    }

    assertEq(WadRayMath.wadMul(a, b), ((a * b) + WadRayMath.HALF_WAD) / WadRayMath.WAD);
  }

  function test_wadDiv_fuzzing(uint256 a, uint256 b) public {
    if ((b == 0) || (((a > ((type(uint256).max - b / 2) / WadRayMath.WAD)) == false) == false)) {
      vm.expectRevert();
      WadRayMath.wadDiv(a, b);
      return;
    }

    assertEq(WadRayMath.wadDiv(a, b), ((a * WadRayMath.WAD) + (b / 2)) / b);
  }

  function test_wadMul() public pure {
    assertEq(WadRayMath.wadMul(2.5e18, 0.5e18), 1.25e18);
    assertEq(WadRayMath.wadMul(412.2e18, 1e18), 412.2e18);
    assertEq(WadRayMath.wadMul(6e18, 2e18), 12e18);
  }

  function test_rayMul() public pure {
    assertEq(WadRayMath.rayMul(2.5e27, 0.5e27), 1.25e27);
    assertEq(WadRayMath.rayMul(412.2e27, 1e27), 412.2e27);
    assertEq(WadRayMath.rayMul(6e27, 2e27), 12e27);
  }

  function test_wadDiv() public pure {
    assertEq(WadRayMath.wadDiv(2.5e18, 0.5e18), 5e18);
    assertEq(WadRayMath.wadDiv(412.2e18, 1e18), 412.2e18);
    assertEq(WadRayMath.wadDiv(8.745e18, 0.67e18), 13.052238805970149254e18);
    assertEq(WadRayMath.wadDiv(6e18, 2e18), 3e18);
  }

  function test_rayDiv() public pure {
    assertEq(WadRayMath.rayDiv(2.5e27, 0.5e27), 5e27);
    assertEq(WadRayMath.rayDiv(412.2e27, 1e27), 412.2e27);
    assertEq(WadRayMath.rayDiv(8.745e27, 0.67e27), 13.052238805970149253731343284e27);
    assertEq(WadRayMath.rayDiv(6e27, 2e27), 3e27);
  }

  function test_wadToRay() public pure {
    assertEq(WadRayMath.wadToRay(1e18), 1e27);
    assertEq(WadRayMath.wadToRay(412.2e18), 412.2e27);
    assertEq(WadRayMath.wadToRay(0), 0);
  }

  function test_rayToWad() public pure {
    assertEq(WadRayMath.rayToWad(1e27), 1e18);
    assertEq(WadRayMath.rayToWad(412.2e27), 412.2e18);
    assertEq(WadRayMath.rayToWad(0), 0);
  }

  function test_wadToRay_fuzz(uint256 a) public {
    uint256 b;
    bool safetyCheck;
    unchecked {
      b = a * WadRayMath.WAD_RAY_RATIO;
      safetyCheck = b / WadRayMath.WAD_RAY_RATIO == a;
    }
    if (!safetyCheck) {
      vm.expectRevert();
      WadRayMath.wadToRay(a);
    } else {
      assertEq(WadRayMath.wadToRay(a), a * WadRayMath.WAD_RAY_RATIO);
      assertEq(WadRayMath.wadToRay(a), b);
    }
  }

  function test_rayToWad_fuzz(uint256 a) public pure {
    uint256 b;
    uint256 remainder;
    bool roundHalf;
    unchecked {
      b = a / WadRayMath.WAD_RAY_RATIO;
      remainder = a % WadRayMath.WAD_RAY_RATIO;
      roundHalf = remainder < WadRayMath.WAD_RAY_RATIO / 2;
    }
    if (!roundHalf) {
      assertEq(WadRayMath.rayToWad(a), (a / WadRayMath.WAD_RAY_RATIO) + 1);
      assertEq(WadRayMath.rayToWad(a), b + 1);
    } else {
      assertEq(WadRayMath.rayToWad(a), a / WadRayMath.WAD_RAY_RATIO);
      assertEq(WadRayMath.rayToWad(a), b);
    }
  }

  function testRayMulFloor_Exact() public pure {
    assertEq(WadRayMath.rayMulFloor(1e27, 5e27), 5e27);
  }

  function testRayMulFloor_Truncation() public pure {
    assertEq(WadRayMath.rayMulFloor(3, 5), 0); // 15 / RAY → 0
  }

  function testRayMulFloor_Zero() public pure {
    assertEq(WadRayMath.rayMulFloor(0, 123), 0);
    assertEq(WadRayMath.rayMulFloor(123, 0), 0);
  }

  function testRayMulFloor_RevertOnOverflow() public {
    uint256 max = type(uint256).max;
    vm.expectRevert();
    WadRayMath.rayMulFloor(max, 2);
  }

  function testRayMulCeil_Exact() public pure {
    assertEq(WadRayMath.rayMulCeil(1e27, 5e27), 5e27);
  }

  function testRayMulCeil_WithCeil() public pure {
    assertEq(WadRayMath.rayMulCeil(3, 5), 1); // 15 / RAY → ceil to 1
  }

  function testRayMulCeil_Zero() public pure {
    assertEq(WadRayMath.rayMulCeil(0, 123), 0);
    assertEq(WadRayMath.rayMulCeil(123, 0), 0);
  }

  function testRayMulCeil_RevertOnOverflow() public {
    uint256 max = type(uint256).max;
    vm.expectRevert();
    WadRayMath.rayMulCeil(max, 2);
  }

  function testRayDivCeil_Exact() public pure {
    assertEq(WadRayMath.rayDivCeil(1e27, 1e27), 1e27);
  }

  function testRayDivCeil_WithCeil() public pure {
    assertEq(WadRayMath.rayDivCeil(5, 3), 1666666666666666666666666667); // (5 * RAY) / 3 = 1.66e27 → ceil
  }

  function testRayDivCeil_ZeroNumerator() public pure {
    assertEq(WadRayMath.rayDivCeil(0, 123), 0);
  }

  function testRayDivCeil_RevertOnDivByZero() public {
    vm.expectRevert();
    WadRayMath.rayDivCeil(100, 0);
  }

  function testRayDivCeil_RevertOnOverflow() public {
    uint256 max = type(uint256).max;
    vm.expectRevert();
    WadRayMath.rayDivCeil(max, 1); // max * RAY will overflow
  }

  function testRayDivFloor_Exact() public pure {
    assertEq(WadRayMath.rayDivFloor(1e27, 1e27), 1e27);
  }

  function testRayDivFloor_Truncation() public pure {
    assertEq(WadRayMath.rayDivFloor(5, 3), 1666666666666666666666666666); // floor of (5 * RAY / 3)
  }

  function testRayDivFloor_ZeroNumerator() public pure {
    assertEq(WadRayMath.rayDivFloor(0, 123), 0);
  }

  function testRayDivFloor_RevertOnDivByZero() public {
    vm.expectRevert();
    WadRayMath.rayDivFloor(100, 0);
  }

  function testRayDivFloor_RevertOnOverflow() public {
    uint256 max = type(uint256).max;
    vm.expectRevert();
    WadRayMath.rayDivFloor(max, 1); // max * RAY overflows
  }
}
