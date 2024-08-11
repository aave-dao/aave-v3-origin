```diff
diff --git a/./downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol b/./downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
index 8c00995..455ec9b 100644
--- a/./downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
+++ b/./downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
@@ -1,7 +1,241 @@
 // SPDX-License-Identifier: BUSL-1.1

-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-periphery/contracts/rewards/RewardsDistributor.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsDistributor.sol

 /**
  * @title RewardsDistributor
@@ -1014,7 +1015,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
   function getRewardsData(
     address asset,
     address reward
-  ) public view override returns (uint256, uint256, uint256, uint256) {
+  ) external view override returns (uint256, uint256, uint256, uint256) {
     return (
       _assets[asset].rewards[reward].index,
       _assets[asset].rewards[reward].emissionPerSecond,
@@ -1066,7 +1067,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
     address user,
     address asset,
     address reward
-  ) public view override returns (uint256) {
+  ) external view override returns (uint256) {
     return _assets[asset].rewards[reward].usersData[user].index;
   }

@@ -1505,7 +1506,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
   }
 }

-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-periphery/contracts/rewards/RewardsController.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsController.sol

 /**
  * @title RewardsController
@@ -1515,7 +1516,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
 contract RewardsController is RewardsDistributor, VersionedInitializable, IRewardsController {
   using SafeCast for uint256;

-  uint256 public constant REVISION = 2;
+  uint256 public constant REVISION = 1;

   // This mapping allows whitelisted addresses to claim on behalf of others
   // useful for contracts that hold tokens to be rewarded but don't have any native logic to claim Liquidity Mining rewards
```
