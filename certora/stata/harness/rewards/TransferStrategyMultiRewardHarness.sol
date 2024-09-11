pragma solidity ^0.8.10;

import {IERC20} from '../../munged/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {TransferStrategyBase} from '../../munged/lib/aave-v3-periphery/contracts/rewards/transfer-strategies/TransferStrategyBase.sol';

contract TransferStrategyMultiRewardHarness is TransferStrategyBase {
  constructor(
    address incentivesController,
    address rewardsAdmin
  ) TransferStrategyBase(incentivesController, rewardsAdmin) {}

  IERC20 public REWARD;
  IERC20 public REWARD_B;

  // executes the actual transfer of the rewards to the receiver
  function performTransfer(
    address to,
    address reward,
    uint256 amount
  ) external override(TransferStrategyBase) returns (bool) {
    require(reward == address(REWARD) || reward == address(REWARD_B));

    if (reward == address(REWARD)) {
      return REWARD.transfer(to, amount);
    } else if (reward == address(REWARD_B)) {
      return REWARD_B.transfer(to, amount);
    }
    return false;
  }
}
