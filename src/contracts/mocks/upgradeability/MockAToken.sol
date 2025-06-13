// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ATokenInstance} from '../../instances/ATokenInstance.sol';
import {IPool} from '../../interfaces/IPool.sol';

contract MockAToken is ATokenInstance {
  constructor(
    IPool pool,
    address rewardsController,
    address treasury
  ) ATokenInstance(pool, rewardsController, treasury) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }
}
