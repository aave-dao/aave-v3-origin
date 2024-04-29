// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {StableDebtTokenInstance} from '../munged/contracts/instances/StableDebtTokenInstance.sol';
import {IncentivizedERC20} from '../munged/contracts/protocol/tokenization/base/IncentivizedERC20.sol';
import {IPool} from '../munged/contracts/interfaces/IPool.sol';

contract StableDebtTokenHarness is StableDebtTokenInstance {
  constructor(IPool pool) public StableDebtTokenInstance(pool) {}

  function additionalData(address user) public view returns (uint128) {
    return _userState[user].additionalData;
  }

  function debtTotalSupply() public view returns (uint256) {
    return super.totalSupply();
  }
}
