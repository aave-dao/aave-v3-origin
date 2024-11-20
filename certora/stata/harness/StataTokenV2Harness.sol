// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {IERC20} from 'openzeppelin-contracts/contracts/interfaces/IERC20.sol';
import {StataTokenV2, IPool, IRewardsController} from '../munged/src/contracts/extensions/stata-token/StataTokenV2.sol';
import {SymbolicLendingPool} from './pool/SymbolicLendingPool.sol';

contract StataTokenV2Harness is StataTokenV2 {
  address internal _reward_A;

  constructor(
    IPool pool,
    IRewardsController rewardsController
  ) StataTokenV2(pool, rewardsController) {}

  function rate() external view returns (uint256) {
    return _rate();
  }

  // returns the address of the i-th reward token in the reward tokens list maintained by the static aToken
  function getRewardToken(uint256 i) external view returns (address) {
    return rewardTokens()[i];
  }

  // returns the length of the reward tokens list maintained by the static aToken
  function getRewardTokensLength() external view returns (uint256) {
    return rewardTokens().length;
  }

  // returns a user's reward index on last interaction for a given reward
  // function getRewardsIndexOnLastInteraction(address user, address reward)
  // external view returns (uint128) {
  //     UserRewardsData memory currentUserRewardsData = _userRewardsData[user][reward];
  //     return currentUserRewardsData.rewardsIndexOnLastInteraction;
  // }

  // claims rewards for a user on the static aToken.
  // the method builds the rewards array with a single reward and calls the internal claim function with it
  function claimSingleRewardOnBehalf(
    address onBehalfOf,
    address receiver,
    address reward
  ) external {
    require(reward == _reward_A);
    address[] memory rewards = new address[](1);
    rewards[0] = _reward_A;

    // @MM - think of the best way to get rid of this require
    require(msg.sender == onBehalfOf || msg.sender == INCENTIVES_CONTROLLER.getClaimer(onBehalfOf));
    _claimRewardsOnBehalf(onBehalfOf, receiver, rewards);
  }

  // claims rewards for a user on the static aToken.
  // the method builds the rewards array with 2 identical rewards and calls the internal claim function with it
  function claimDoubleRewardOnBehalfSame(
    address onBehalfOf,
    address receiver,
    address reward
  ) external {
    require(reward == _reward_A);
    address[] memory rewards = new address[](2);
    rewards[0] = _reward_A;
    rewards[1] = _reward_A;

    require(msg.sender == onBehalfOf || msg.sender == INCENTIVES_CONTROLLER.getClaimer(onBehalfOf));
    _claimRewardsOnBehalf(onBehalfOf, receiver, rewards);
  }

  // wrapper function for the erc20 _mint function. Used to reduce running times
  function _mintWrapper(address to, uint256 amount) external {
    _mint(to, amount);
  }
}
