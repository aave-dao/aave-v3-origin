// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VariableDebtTokenInstance, IPool} from '../../src/contracts/instances/VariableDebtTokenInstance.sol';

contract VariableDebtTokenHarness is VariableDebtTokenInstance {
  constructor(IPool pool) VariableDebtTokenInstance(pool) {}

  function _getRevision() public pure returns (uint256) {
    return super.getRevision();
  }
}
