// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../protocol/tokenization/base/ScaledBalanceTokenBase.sol';
import '../../protocol/libraries/math/WadRayMath.sol';

contract MockScaledToken is ScaledBalanceTokenBase {
  using WadRayMath for uint256;

  constructor(
    IPool pool,
    address rewardsController
  ) ScaledBalanceTokenBase(pool, 'A', 'A', 6, rewardsController) {
    // Intentionally left blank
  }

  function setStorage(
    address alice,
    address bob,
    uint256 previousIndex,
    uint256 aliceScaledBalance,
    uint256 bobScaledBalance
  ) public {
    _userState[alice].additionalData = uint128(previousIndex);
    _userState[bob].additionalData = uint128(previousIndex);
    _userState[alice].balance = uint120(aliceScaledBalance);
    _userState[bob].balance = uint120(bobScaledBalance);
  }

  function getBalanceOf(uint256 scaledBalance, uint256 newIndex) internal pure returns (uint256) {
    return scaledBalance.rayMul(newIndex);
  }
}
