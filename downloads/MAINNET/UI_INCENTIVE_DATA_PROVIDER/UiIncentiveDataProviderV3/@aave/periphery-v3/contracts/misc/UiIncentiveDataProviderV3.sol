// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20Detailed} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IPoolAddressesProvider} from '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '@aave/core-v3/contracts/interfaces/IPool.sol';
import {IncentivizedERC20} from '@aave/core-v3/contracts/protocol/tokenization/base/IncentivizedERC20.sol';
import {UserConfiguration} from '@aave/core-v3/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol';
import {IRewardsController} from '../rewards/interfaces/IRewardsController.sol';
import {IEACAggregatorProxy} from './interfaces/IEACAggregatorProxy.sol';
import {IUiIncentiveDataProviderV3} from './interfaces/IUiIncentiveDataProviderV3.sol';

contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
  using UserConfiguration for DataTypes.UserConfigurationMap;

  function getFullReservesIncentiveData(IPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory)
  {
    return (_getReservesIncentivesData(provider), _getUserReservesIncentivesData(provider, user));
  }

  function getReservesIncentivesData(IPoolAddressesProvider provider)
    external
    view
    override
    returns (AggregatedReserveIncentiveData[] memory)
  {
    return _getReservesIncentivesData(provider);
  }

  function _getReservesIncentivesData(IPoolAddressesProvider provider)
    private
    view
    returns (AggregatedReserveIncentiveData[] memory)
  {
    IPool pool = IPool(provider.getPool());
    address[] memory reserves = pool.getReservesList();
    AggregatedReserveIncentiveData[]
      memory reservesIncentiveData = new AggregatedReserveIncentiveData[](reserves.length);
    // Iterate through the reserves to get all the information from the (a/s/v) Tokens
    for (uint256 i = 0; i < reserves.length; i++) {
      AggregatedReserveIncentiveData memory reserveIncentiveData = reservesIncentiveData[i];
      reserveIncentiveData.underlyingAsset = reserves[i];

      DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);

      // Get aTokens rewards information
      // TODO: check that this is deployed correctly on contract and remove casting
      IRewardsController aTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.aTokenAddress).getIncentivesController())
      );
      RewardInfo[] memory aRewardsInformation;
      if (address(aTokenIncentiveController) != address(0)) {
        address[] memory aTokenRewardAddresses = aTokenIncentiveController.getRewardsByAsset(
          baseData.aTokenAddress
        );

        aRewardsInformation = new RewardInfo[](aTokenRewardAddresses.length);
        for (uint256 j = 0; j < aTokenRewardAddresses.length; ++j) {
          RewardInfo memory rewardInformation;
          rewardInformation.rewardTokenAddress = aTokenRewardAddresses[j];

          (
            rewardInformation.tokenIncentivesIndex,
            rewardInformation.emissionPerSecond,
            rewardInformation.incentivesLastUpdateTimestamp,
            rewardInformation.emissionEndTimestamp
          ) = aTokenIncentiveController.getRewardsData(
            baseData.aTokenAddress,
            rewardInformation.rewardTokenAddress
          );

          rewardInformation.precision = aTokenIncentiveController.getAssetDecimals(
            baseData.aTokenAddress
          );
          rewardInformation.rewardTokenDecimals = IERC20Detailed(
            rewardInformation.rewardTokenAddress
          ).decimals();
          rewardInformation.rewardTokenSymbol = IERC20Detailed(rewardInformation.rewardTokenAddress)
            .symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          rewardInformation.rewardOracleAddress = aTokenIncentiveController.getRewardOracle(
            rewardInformation.rewardTokenAddress
          );
          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).decimals();
          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).latestAnswer();

          aRewardsInformation[j] = rewardInformation;
        }
      }

      reserveIncentiveData.aIncentiveData = IncentiveData(
        baseData.aTokenAddress,
        address(aTokenIncentiveController),
        aRewardsInformation
      );

      // Get vTokens rewards information
      IRewardsController vTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.variableDebtTokenAddress).getIncentivesController())
      );
      address[] memory vTokenRewardAddresses = vTokenIncentiveController.getRewardsByAsset(
        baseData.variableDebtTokenAddress
      );
      RewardInfo[] memory vRewardsInformation;

      if (address(vTokenIncentiveController) != address(0)) {
        vRewardsInformation = new RewardInfo[](vTokenRewardAddresses.length);
        for (uint256 j = 0; j < vTokenRewardAddresses.length; ++j) {
          RewardInfo memory rewardInformation;
          rewardInformation.rewardTokenAddress = vTokenRewardAddresses[j];

          (
            rewardInformation.tokenIncentivesIndex,
            rewardInformation.emissionPerSecond,
            rewardInformation.incentivesLastUpdateTimestamp,
            rewardInformation.emissionEndTimestamp
          ) = vTokenIncentiveController.getRewardsData(
            baseData.variableDebtTokenAddress,
            rewardInformation.rewardTokenAddress
          );

          rewardInformation.precision = vTokenIncentiveController.getAssetDecimals(
            baseData.variableDebtTokenAddress
          );
          rewardInformation.rewardTokenDecimals = IERC20Detailed(
            rewardInformation.rewardTokenAddress
          ).decimals();
          rewardInformation.rewardTokenSymbol = IERC20Detailed(rewardInformation.rewardTokenAddress)
            .symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          rewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
            rewardInformation.rewardTokenAddress
          );
          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).decimals();
          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).latestAnswer();

          vRewardsInformation[j] = rewardInformation;
        }
      }

      reserveIncentiveData.vIncentiveData = IncentiveData(
        baseData.variableDebtTokenAddress,
        address(vTokenIncentiveController),
        vRewardsInformation
      );

      // Get sTokens rewards information
      IRewardsController sTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.stableDebtTokenAddress).getIncentivesController())
      );
      address[] memory sTokenRewardAddresses = sTokenIncentiveController.getRewardsByAsset(
        baseData.stableDebtTokenAddress
      );
      RewardInfo[] memory sRewardsInformation;

      if (address(sTokenIncentiveController) != address(0)) {
        sRewardsInformation = new RewardInfo[](sTokenRewardAddresses.length);
        for (uint256 j = 0; j < sTokenRewardAddresses.length; ++j) {
          RewardInfo memory rewardInformation;
          rewardInformation.rewardTokenAddress = sTokenRewardAddresses[j];

          (
            rewardInformation.tokenIncentivesIndex,
            rewardInformation.emissionPerSecond,
            rewardInformation.incentivesLastUpdateTimestamp,
            rewardInformation.emissionEndTimestamp
          ) = sTokenIncentiveController.getRewardsData(
            baseData.stableDebtTokenAddress,
            rewardInformation.rewardTokenAddress
          );

          rewardInformation.precision = sTokenIncentiveController.getAssetDecimals(
            baseData.stableDebtTokenAddress
          );
          rewardInformation.rewardTokenDecimals = IERC20Detailed(
            rewardInformation.rewardTokenAddress
          ).decimals();
          rewardInformation.rewardTokenSymbol = IERC20Detailed(rewardInformation.rewardTokenAddress)
            .symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          rewardInformation.rewardOracleAddress = sTokenIncentiveController.getRewardOracle(
            rewardInformation.rewardTokenAddress
          );
          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).decimals();
          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).latestAnswer();

          sRewardsInformation[j] = rewardInformation;
        }
      }

      reserveIncentiveData.sIncentiveData = IncentiveData(
        baseData.stableDebtTokenAddress,
        address(sTokenIncentiveController),
        sRewardsInformation
      );
    }

    return (reservesIncentiveData);
  }

  function getUserReservesIncentivesData(IPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (UserReserveIncentiveData[] memory)
  {
    return _getUserReservesIncentivesData(provider, user);
  }

  function _getUserReservesIncentivesData(IPoolAddressesProvider provider, address user)
    private
    view
    returns (UserReserveIncentiveData[] memory)
  {
    IPool pool = IPool(provider.getPool());
    address[] memory reserves = pool.getReservesList();

    UserReserveIncentiveData[] memory userReservesIncentivesData = new UserReserveIncentiveData[](
      user != address(0) ? reserves.length : 0
    );

    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);

      // user reserve data
      userReservesIncentivesData[i].underlyingAsset = reserves[i];

      IRewardsController aTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.aTokenAddress).getIncentivesController())
      );
      if (address(aTokenIncentiveController) != address(0)) {
        // get all rewards information from the asset
        address[] memory aTokenRewardAddresses = aTokenIncentiveController.getRewardsByAsset(
          baseData.aTokenAddress
        );
        UserRewardInfo[] memory aUserRewardsInformation = new UserRewardInfo[](
          aTokenRewardAddresses.length
        );
        for (uint256 j = 0; j < aTokenRewardAddresses.length; ++j) {
          UserRewardInfo memory userRewardInformation;
          userRewardInformation.rewardTokenAddress = aTokenRewardAddresses[j];

          userRewardInformation.tokenIncentivesUserIndex = aTokenIncentiveController
            .getUserAssetIndex(
              user,
              baseData.aTokenAddress,
              userRewardInformation.rewardTokenAddress
            );

          userRewardInformation.userUnclaimedRewards = aTokenIncentiveController
            .getUserAccruedRewards(user, userRewardInformation.rewardTokenAddress);
          userRewardInformation.rewardTokenDecimals = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).decimals();
          userRewardInformation.rewardTokenSymbol = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          userRewardInformation.rewardOracleAddress = aTokenIncentiveController.getRewardOracle(
            userRewardInformation.rewardTokenAddress
          );
          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).decimals();
          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).latestAnswer();

          aUserRewardsInformation[j] = userRewardInformation;
        }

        userReservesIncentivesData[i].aTokenIncentivesUserData = UserIncentiveData(
          baseData.aTokenAddress,
          address(aTokenIncentiveController),
          aUserRewardsInformation
        );
      }

      // variable debt token
      IRewardsController vTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.variableDebtTokenAddress).getIncentivesController())
      );
      if (address(vTokenIncentiveController) != address(0)) {
        // get all rewards information from the asset
        address[] memory vTokenRewardAddresses = vTokenIncentiveController.getRewardsByAsset(
          baseData.variableDebtTokenAddress
        );
        UserRewardInfo[] memory vUserRewardsInformation = new UserRewardInfo[](
          vTokenRewardAddresses.length
        );
        for (uint256 j = 0; j < vTokenRewardAddresses.length; ++j) {
          UserRewardInfo memory userRewardInformation;
          userRewardInformation.rewardTokenAddress = vTokenRewardAddresses[j];

          userRewardInformation.tokenIncentivesUserIndex = vTokenIncentiveController
            .getUserAssetIndex(
              user,
              baseData.variableDebtTokenAddress,
              userRewardInformation.rewardTokenAddress
            );

          userRewardInformation.userUnclaimedRewards = vTokenIncentiveController
            .getUserAccruedRewards(user, userRewardInformation.rewardTokenAddress);
          userRewardInformation.rewardTokenDecimals = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).decimals();
          userRewardInformation.rewardTokenSymbol = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          userRewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
            userRewardInformation.rewardTokenAddress
          );
          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).decimals();
          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).latestAnswer();

          vUserRewardsInformation[j] = userRewardInformation;
        }

        userReservesIncentivesData[i].vTokenIncentivesUserData = UserIncentiveData(
          baseData.variableDebtTokenAddress,
          address(aTokenIncentiveController),
          vUserRewardsInformation
        );
      }

      // stable debt token
      IRewardsController sTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.stableDebtTokenAddress).getIncentivesController())
      );
      if (address(sTokenIncentiveController) != address(0)) {
        // get all rewards information from the asset
        address[] memory sTokenRewardAddresses = sTokenIncentiveController.getRewardsByAsset(
          baseData.stableDebtTokenAddress
        );
        UserRewardInfo[] memory sUserRewardsInformation = new UserRewardInfo[](
          sTokenRewardAddresses.length
        );
        for (uint256 j = 0; j < sTokenRewardAddresses.length; ++j) {
          UserRewardInfo memory userRewardInformation;
          userRewardInformation.rewardTokenAddress = sTokenRewardAddresses[j];

          userRewardInformation.tokenIncentivesUserIndex = sTokenIncentiveController
            .getUserAssetIndex(
              user,
              baseData.stableDebtTokenAddress,
              userRewardInformation.rewardTokenAddress
            );

          userRewardInformation.userUnclaimedRewards = sTokenIncentiveController
            .getUserAccruedRewards(user, userRewardInformation.rewardTokenAddress);
          userRewardInformation.rewardTokenDecimals = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).decimals();
          userRewardInformation.rewardTokenSymbol = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          userRewardInformation.rewardOracleAddress = sTokenIncentiveController.getRewardOracle(
            userRewardInformation.rewardTokenAddress
          );
          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).decimals();
          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).latestAnswer();

          sUserRewardsInformation[j] = userRewardInformation;
        }

        userReservesIncentivesData[i].sTokenIncentivesUserData = UserIncentiveData(
          baseData.stableDebtTokenAddress,
          address(aTokenIncentiveController),
          sUserRewardsInformation
        );
      }
    }

    return (userReservesIncentivesData);
  }
}
