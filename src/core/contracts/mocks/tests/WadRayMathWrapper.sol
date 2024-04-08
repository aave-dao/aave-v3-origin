// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {WadRayMath} from '../../protocol/libraries/math/WadRayMath.sol';

contract WadRayMathWrapper {
  function WAD() public pure returns (uint256) {
    return WadRayMath.WAD;
  }

  function RAY() public pure returns (uint256) {
    return WadRayMath.RAY;
  }

  function HALF_RAY() public pure returns (uint256) {
    return WadRayMath.HALF_RAY;
  }

  function HALF_WAD() public pure returns (uint256) {
    return WadRayMath.HALF_WAD;
  }

  function WAD_RAY_RATIO() public pure returns (uint256) {
    return WadRayMath.WAD_RAY_RATIO;
  }

  function wadMul(uint256 a, uint256 b) public pure returns (uint256) {
    return WadRayMath.wadMul(a, b);
  }

  function wadDiv(uint256 a, uint256 b) public pure returns (uint256) {
    return WadRayMath.wadDiv(a, b);
  }

  function rayMul(uint256 a, uint256 b) public pure returns (uint256) {
    return WadRayMath.rayMul(a, b);
  }

  function rayDiv(uint256 a, uint256 b) public pure returns (uint256) {
    return WadRayMath.rayDiv(a, b);
  }

  function rayToWad(uint256 a) public pure returns (uint256) {
    return WadRayMath.rayToWad(a);
  }

  function wadToRay(uint256 a) public pure returns (uint256) {
    return WadRayMath.wadToRay(a);
  }
}
