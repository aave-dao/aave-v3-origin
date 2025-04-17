// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';

interface IUiIncentiveDataProviderV3 {
  struct AggregatedReserveIncentiveData {
    address underlyingAsset;
    IncentiveData aIncentiveData;
    IncentiveData vIncentiveData;
  }

  struct IncentiveData {
    address tokenAddress;
    address incentiveControllerAddress;
    RewardInfo[] rewardsTokenInformation;
  }

  struct RewardInfo {
    string rewardTokenSymbol;
    address rewardTokenAddress;
    address rewardOracleAddress;
    uint256 emissionPerSecond;
    uint256 incentivesLastUpdateTimestamp;
    uint256 tokenIncentivesIndex;
    uint256 emissionEndTimestamp;
    int256 rewardPriceFeed;
    uint8 rewardTokenDecimals;
    uint8 precision;
    uint8 priceFeedDecimals;
  }

  struct UserReserveIncentiveData {
    address underlyingAsset;
    UserIncentiveData aTokenIncentivesUserData;
    UserIncentiveData vTokenIncentivesUserData;
  }

  struct UserIncentiveData {
    address tokenAddress;
    address incentiveControllerAddress;
    UserRewardInfo[] userRewardsInformation;
  }

  struct UserRewardInfo {
    string rewardTokenSymbol;
    address rewardOracleAddress;
    address rewardTokenAddress;
    uint256 userUnclaimedRewards;
    uint256 tokenIncentivesUserIndex;
    int256 rewardPriceFeed;
    uint8 priceFeedDecimals;
    uint8 rewardTokenDecimals;
  }

  function getReservesIncentivesData(
    IPoolAddressesProvider provider
  ) external view returns (AggregatedReserveIncentiveData[] memory);

  function getUserReservesIncentivesData(
    IPoolAddressesProvider provider,
    address user
  ) external view returns (UserReserveIncentiveData[] memory);

  // generic method with full data
  function getFullReservesIncentiveData(
    IPoolAddressesProvider provider,
    address user
  )
    external
    view
    returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory);
}
