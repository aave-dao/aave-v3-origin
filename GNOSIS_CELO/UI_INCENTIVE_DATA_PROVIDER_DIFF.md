```diff
diff --git a/./downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER.sol b/./downloads/CELO/UI_INCENTIVE_DATA_PROVIDER.sol
index 62824f1..63bc81b 100644
--- a/./downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER.sol
+++ b/./downloads/CELO/UI_INCENTIVE_DATA_PROVIDER.sol

-// downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/CELO/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/interfaces/IRewardsController.sol

 /**
  * @title IRewardsController
@@ -3404,9 +3483,9 @@ interface IRewardsController is IRewardsDistributor {
    * This check is enforced for integrators to be able to show incentives at
    * the current Aave UI without the need to setup an external price registry
    * @param reward The address of the reward to set the price aggregator
-   * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
+   * @param rewardOracle The address of price aggregator that follows AggregatorInterface interface
    */
-  function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;
+  function setRewardOracle(address reward, AggregatorInterface rewardOracle) external;

   /**
    * @dev Get the price aggregator oracle address
@@ -3438,8 +3517,8 @@ interface IRewardsController is IRewardsDistributor {
    *   address asset: The asset address to incentivize
    *   address reward: The reward token address
    *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
-   *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
-   *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
+   *   AggregatorInterface rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
+   *                                     Must follow Chainlink Aggregator AggregatorInterface interface to be compatible.
    */
   function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

@@ -3536,7 +3615,7 @@ interface IRewardsController is IRewardsDistributor {
   ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
 }

-// downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/UiIncentiveDataProviderV3.sol
+// downloads/CELO/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/UiIncentiveDataProviderV3.sol

 contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
   using UserConfiguration for DataTypes.UserConfigurationMap;
@@ -3834,10 +3913,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           rewardInformation.rewardOracleAddress = aTokenIncentiveController.getRewardOracle(
             rewardInformation.rewardTokenAddress
           );
-          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          rewardInformation.priceFeedDecimals = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).decimals();
-          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          rewardInformation.rewardPriceFeed = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).latestAnswer();

@@ -3888,10 +3967,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           rewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
             rewardInformation.rewardTokenAddress
           );
-          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          rewardInformation.priceFeedDecimals = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).decimals();
-          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          rewardInformation.rewardPriceFeed = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).latestAnswer();

@@ -3968,10 +4047,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           userRewardInformation.rewardOracleAddress = aTokenIncentiveController.getRewardOracle(
             userRewardInformation.rewardTokenAddress
           );
-          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          userRewardInformation.priceFeedDecimals = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).decimals();
-          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          userRewardInformation.rewardPriceFeed = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).latestAnswer();

@@ -4021,10 +4100,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           userRewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
             userRewardInformation.rewardTokenAddress
           );
-          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          userRewardInformation.priceFeedDecimals = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).decimals();
-          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          userRewardInformation.rewardPriceFeed = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).latestAnswer();

```
