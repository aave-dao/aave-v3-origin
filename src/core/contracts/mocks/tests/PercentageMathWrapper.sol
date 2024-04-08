// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {PercentageMath} from '../../protocol/libraries/math/PercentageMath.sol';

contract PercentageMathWrapper {
  function PERCENTAGE_FACTOR() public pure returns (uint256) {
    return PercentageMath.PERCENTAGE_FACTOR;
  }

  function HALF_PERCENTAGE_FACTOR() public pure returns (uint256) {
    return PercentageMath.HALF_PERCENTAGE_FACTOR;
  }

  function percentMul(uint256 value, uint256 percentage) public pure returns (uint256) {
    return PercentageMath.percentMul(value, percentage);
  }

  function percentDiv(uint256 value, uint256 percentage) public pure returns (uint256) {
    return PercentageMath.percentDiv(value, percentage);
  }
}
