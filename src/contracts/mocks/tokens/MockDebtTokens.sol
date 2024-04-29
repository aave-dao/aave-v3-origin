// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {VariableDebtTokenInstance} from '../../instances/VariableDebtTokenInstance.sol';
import {StableDebtTokenInstance} from '../../instances/StableDebtTokenInstance.sol';
import {IPool} from '../../interfaces/IPool.sol';

contract MockVariableDebtToken is VariableDebtTokenInstance {
  constructor(IPool pool) VariableDebtTokenInstance(pool) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }
}

contract MockStableDebtToken is StableDebtTokenInstance {
  constructor(IPool pool) StableDebtTokenInstance(pool) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }
}
