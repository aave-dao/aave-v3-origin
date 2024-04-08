// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {MathUtils} from '../../protocol/libraries/math/MathUtils.sol';

contract MathUtilsWrapper {
  function SECONDS_PER_YEAR() public pure returns (uint256) {
    return MathUtils.SECONDS_PER_YEAR;
  }

  function calculateLinearInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp
  ) public view returns (uint256) {
    return MathUtils.calculateLinearInterest(rate, lastUpdateTimestamp);
  }

  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) public pure returns (uint256) {
    return MathUtils.calculateCompoundedInterest(rate, lastUpdateTimestamp, currentTimestamp);
  }

  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp
  ) public view returns (uint256) {
    return MathUtils.calculateCompoundedInterest(rate, lastUpdateTimestamp);
  }
}
