pragma solidity ^0.8.10;

import {RewardsController, RewardsDataTypes} from '../../munged/src/contracts/rewards/RewardsController.sol';

contract RewardsControllerHarness is RewardsController {
  constructor(address emissionManager) RewardsController(emissionManager) {}

  // returns the available rewardscount of a given asset in the rewards controller
  function getAvailableRewardsCount(address asset) external view returns (uint128) {
    return _assets[asset].availableRewardsCount;
  }

  // returns the i-th available reward of a given asset in the rewards controller
  /// @dev assume i < availableRewardsCount
  function getRewardsByAsset(address asset, uint128 i) external view returns (address) {
    return _assets[asset].availableRewards[i];
  }

  // returns the i-th asset in the reward controller
  function getAssetByIndex(uint256 i) external view returns (address) {
    return _assetsList[i];
  }

  // returns the length of the asset list in the reward controller
  function getAssetListLength() external view returns (uint256) {
    return _assetsList.length;
  }

  // returns the a user's accrued rewards for a given reward baring asset and a specified reward
  function getUserAccruedReward(
    address user,
    address asset,
    address reward
  ) external view returns (uint256) {
    return _assets[asset].rewards[reward].usersData[user].accrued;
  }

  // returns the a user's reward index for a given reward baring asset and a specified reward
  function getRewardsIndex(address asset, address reward) external view returns (uint256) {
    return _assets[asset].rewards[reward].index;
  }
}
