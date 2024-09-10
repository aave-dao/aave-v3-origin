```diff
diff --git a/./downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol b/./downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol

-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsDistributor.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsDistributor.sol

 /**
  * @title RewardsDistributor
@@ -1015,7 +1015,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
   function getRewardsData(
     address asset,
     address reward
-  ) public view override returns (uint256, uint256, uint256, uint256) {
+  ) external view override returns (uint256, uint256, uint256, uint256) {
     return (
       _assets[asset].rewards[reward].index,
       _assets[asset].rewards[reward].emissionPerSecond,
@@ -1067,7 +1067,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
     address user,
     address asset,
     address reward
-  ) public view override returns (uint256) {
+  ) external view override returns (uint256) {
     return _assets[asset].rewards[reward].usersData[user].index;
   }

@@ -1506,7 +1506,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
   }
 }
```
