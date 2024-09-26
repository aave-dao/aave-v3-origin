// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ATokenInstance} from '../../instances/ATokenInstance.sol';
import {IPool} from '../../interfaces/IPool.sol';

contract MockATokenRepayment is ATokenInstance {
  event MockRepayment(address user, address onBehalfOf, uint256 amount);

  constructor(IPool pool) ATokenInstance(pool) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }

  function handleRepayment(
    address user,
    address onBehalfOf,
    uint256 amount
  ) external override onlyPool {
    emit MockRepayment(user, onBehalfOf, amount);
  }
}
