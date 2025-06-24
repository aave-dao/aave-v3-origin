// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

import {ATokenInstance} from '../../instances/ATokenInstance.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {TokenMath} from '../../protocol/libraries/helpers/TokenMath.sol';

contract MockAToken is ATokenInstance {
  using TokenMath for uint256;
  using SafeCast for uint256;

  constructor(
    IPool pool,
    address rewardsController,
    address treasury
  ) ATokenInstance(pool, rewardsController, treasury) {}

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

  function transferWithIndex(
    address sender,
    address recipient,
    uint256 amount,
    uint256 newIndex
  ) public {
    _transfer(
      sender,
      recipient,
      amount,
      amount.getATokenTransferScaledAmount(newIndex).toUint120(),
      newIndex
    );
  }

  function getRevision() internal pure override returns (uint256) {
    return ATOKEN_REVISION + 1;
  }
}
