// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {StableDebtTokenInstance, IPool} from '../../src/contracts/instances/StableDebtTokenInstance.sol';

contract StableDebtTokenHarness is StableDebtTokenInstance {
  constructor(IPool pool) StableDebtTokenInstance(pool) {}

  function _getRevision() public pure returns (uint256) {
    return super.getRevision();
  }
}
