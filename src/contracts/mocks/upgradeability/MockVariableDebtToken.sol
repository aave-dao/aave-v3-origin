// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {VariableDebtTokenInstance} from '../../instances/VariableDebtTokenInstance.sol';
import {IPool} from '../../interfaces/IPool.sol';

contract MockVariableDebtToken is VariableDebtTokenInstance {
  constructor(
    IPool pool,
    address rewardsController
  ) VariableDebtTokenInstance(pool, rewardsController) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }
}
