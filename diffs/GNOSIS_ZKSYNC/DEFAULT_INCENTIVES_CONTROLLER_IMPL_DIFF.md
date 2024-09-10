```diff
diff --git a/./downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol b/./downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
index 46ab738..455ec9b 100644
--- a/./downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
+++ b/./downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: MIT
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
 
 interface IEACAggregatorProxy {
   function decimals() external view returns (uint8);
@@ -20,7 +20,7 @@ interface IEACAggregatorProxy {
   event NewRound(uint256 indexed roundId, address indexed startedBy);
 }
 
-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
 
 /**
  * @title IRewardsDistributor
@@ -197,7 +197,7 @@ interface IRewardsDistributor {
   function getEmissionManager() external view returns (address);
 }
 
-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
 
 interface ITransferStrategyBase {
   event EmergencyWithdrawal(
@@ -726,7 +726,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
 
 library RewardsDataTypes {
   struct RewardsConfigInput {
@@ -777,7 +777,7 @@ library RewardsDataTypes {
   }
 }
 
-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
 
 /**
  * @title IRewardsController
@@ -975,7 +975,7 @@ interface IRewardsController is IRewardsDistributor {
   ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
 }
 
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
 
-// downloads/GNOSIS/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsController.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsController.sol
 
 /**
  * @title RewardsController
```
