// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {VariableDebtTokenInstance} from '../munged/src/contracts/instances/VariableDebtTokenInstance.sol';
import {WadRayMath} from '../munged/src/contracts/protocol/libraries/math/WadRayMath.sol';
import {IPool} from '../munged/src/contracts/interfaces/IPool.sol';

contract VariableDebtTokenHarness is VariableDebtTokenInstance {
  using WadRayMath for uint256;

  constructor(
    IPool pool,
    address rewardsController
  ) public VariableDebtTokenInstance(pool, rewardsController) {}

  function scaledBalanceOfToBalanceOf(uint256 bal) public view returns (uint256) {
    return bal.rayMul(POOL.getReserveNormalizedVariableDebt(_underlyingAsset));
  }
}
