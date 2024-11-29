// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20AaveLM {
  struct UserRewardsData {
    uint128 rewardsIndexOnLastInteraction;
    uint128 unclaimedRewards;
  }

  struct RewardIndexCache {
    bool isRegistered;
    uint248 lastUpdatedIndex;
  }

  error ZeroIncentivesControllerIsForbidden();
  error InvalidClaimer(address claimer);
  error RewardNotInitialized(address reward);

  event RewardTokenRegistered(address indexed reward, uint256 startIndex);

  /**
   * @notice Claims rewards from `INCENTIVES_CONTROLLER` and updates internal accounting of rewards.
   * @param reward The reward to claim
   * @return uint256 Amount collected
   */
  function collectAndUpdateRewards(address reward) external returns (uint256);

  /**
   * @notice Claim rewards on behalf of a user and send them to a receiver
   * @dev Only callable by if sender is onBehalfOf or sender is approved claimer
   * @param onBehalfOf The address to claim on behalf of
   * @param receiver The address to receive the rewards
   * @param rewards The rewards to claim
   */
  function claimRewardsOnBehalf(
    address onBehalfOf,
    address receiver,
    address[] memory rewards
  ) external;

  /**
   * @notice Claim rewards and send them to a receiver
   * @param receiver The address to receive the rewards
   * @param rewards The rewards to claim
   */
  function claimRewards(address receiver, address[] memory rewards) external;

  /**
   * @notice Claim rewards
   * @param rewards The rewards to claim
   */
  function claimRewardsToSelf(address[] memory rewards) external;

  /**
   * @notice Get the total claimable rewards of the contract.
   * @param reward The reward to claim
   * @return uint256 The current balance + pending rewards from the `_incentivesController`
   */
  function getTotalClaimableRewards(address reward) external view returns (uint256);

  /**
   * @notice Get the total claimable rewards for a user in asset decimals
   * @param user The address of the user
   * @param reward The reward to claim
   * @return uint256 The claimable amount of rewards in asset decimals
   */
  function getClaimableRewards(address user, address reward) external view returns (uint256);

  /**
   * @notice The unclaimed rewards for a user in asset decimals
   * @param user The address of the user
   * @param reward The reward to claim
   * @return uint256 The unclaimed amount of rewards in asset decimals
   */
  function getUnclaimedRewards(address user, address reward) external view returns (uint256);

  /**
   * @notice The underlying asset reward index in RAY
   * @param reward The reward to claim
   * @return uint256 The underlying asset reward index in RAY
   */
  function getCurrentRewardsIndex(address reward) external view returns (uint256);

  /**
   * @notice Returns reference a/v token address used on INCENTIVES_CONTROLLER for tracking
   * @return address of reference token
   */
  function getReferenceAsset() external view returns (address);

  /**
   * @notice The IERC20s that are currently rewarded to addresses of the vault via LM on incentivescontroller.
   * @return IERC20 The IERC20s of the rewards.
   */
  function rewardTokens() external view returns (address[] memory);

  /**
   * @notice Fetches all rewardTokens from the incentivecontroller and registers the missing ones.
   */
  function refreshRewardTokens() external;

  /**
   * @notice Checks if the passed token is a registered reward.
   * @param reward The reward to claim
   * @return bool signaling if token is a registered reward.
   */
  function isRegisteredRewardToken(address reward) external view returns (bool);
}
