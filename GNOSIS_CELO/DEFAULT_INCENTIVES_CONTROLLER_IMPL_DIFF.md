```diff
diff --git a/./downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol b/./downloads/CELO/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
index 470a2d4..ade74e4 100644
--- a/./downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
+++ b/./downloads/CELO/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol

-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
+// downloads/CELO/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/contracts/rewards/libraries/RewardsDataTypes.sol

 library RewardsDataTypes {
   struct RewardsConfigInput {
@@ -736,7 +765,7 @@ library RewardsDataTypes {
     address asset;
     address reward;
     ITransferStrategyBase transferStrategy;
-    IEACAggregatorProxy rewardOracle;
+    AggregatorInterface rewardOracle;
   }

   struct UserAssetBalance {
@@ -777,7 +806,7 @@ library RewardsDataTypes {
   }
 }

-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/CELO/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/contracts/rewards/interfaces/IRewardsController.sol

 /**
  * @title IRewardsController
@@ -843,9 +872,9 @@ interface IRewardsController is IRewardsDistributor {
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
@@ -877,8 +906,8 @@ interface IRewardsController is IRewardsDistributor {
    *   address asset: The asset address to incentivize
    *   address reward: The reward token address
    *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
-   *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
-   *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
+   *   AggregatorInterface rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
+   *                                     Must follow Chainlink Aggregator AggregatorInterface interface to be compatible.
    */
   function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

@@ -975,7 +1004,7 @@ interface IRewardsController is IRewardsDistributor {
   ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
 }

-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsDistributor.sol
+// downloads/CELO/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/contracts/rewards/RewardsDistributor.sol

 /**
  * @title RewardsDistributor
@@ -1015,7 +1044,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
   function getRewardsData(
     address asset,
     address reward
-  ) public view override returns (uint256, uint256, uint256, uint256) {
+  ) external view override returns (uint256, uint256, uint256, uint256) {
     return (
       _assets[asset].rewards[reward].index,
       _assets[asset].rewards[reward].emissionPerSecond,
@@ -1067,7 +1096,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
     address user,
     address asset,
     address reward
-  ) public view override returns (uint256) {
+  ) external view override returns (uint256) {
     return _assets[asset].rewards[reward].usersData[user].index;
   }

@@ -1506,7 +1535,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
   }
 }

-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsController.sol
+// downloads/CELO/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/contracts/rewards/RewardsController.sol

 /**
  * @title RewardsController
@@ -1532,7 +1561,7 @@ contract RewardsController is RewardsDistributor, VersionedInitializable, IRewar
   // the current Aave UI without the need to setup an external price registry
   // At the moment of reward configuration, the Incentives Controller performs
   // a check to see if the provided reward oracle contains `latestAnswer`.
-  mapping(address => IEACAggregatorProxy) internal _rewardOracle;
+  mapping(address => AggregatorInterface) internal _rewardOracle;

   modifier onlyAuthorizedClaimers(address claimer, address user) {
     require(_authorizedClaimers[user] == claimer, 'CLAIMER_UNAUTHORIZED');
@@ -1598,7 +1627,7 @@ contract RewardsController is RewardsDistributor, VersionedInitializable, IRewar
   /// @inheritdoc IRewardsController
   function setRewardOracle(
     address reward,
-    IEACAggregatorProxy rewardOracle
+    AggregatorInterface rewardOracle
   ) external onlyEmissionManager {
     _setRewardOracle(reward, rewardOracle);
   }
@@ -1839,13 +1868,13 @@ contract RewardsController is RewardsDistributor, VersionedInitializable, IRewar
   }

   /**
-   * @dev Update the Price Oracle of a reward token. The Price Oracle must follow Chainlink IEACAggregatorProxy interface.
+   * @dev Update the Price Oracle of a reward token. The Price Oracle must follow Chainlink AggregatorInterface interface.
    * @notice The Price Oracle of a reward is used for displaying correct data about the incentives at the UI frontend.
    * @param reward The address of the reward token
    * @param rewardOracle The address of the price oracle
    */

-  function _setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) internal {
+  function _setRewardOracle(address reward, AggregatorInterface rewardOracle) internal {
     require(rewardOracle.latestAnswer() > 0, 'ORACLE_MUST_RETURN_PRICE');
     _rewardOracle[reward] = rewardOracle;
     emit RewardOracleUpdated(reward, address(rewardOracle));
```
