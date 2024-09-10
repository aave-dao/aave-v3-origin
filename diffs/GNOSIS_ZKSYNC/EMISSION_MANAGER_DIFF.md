```diff
diff --git a/./downloads/GNOSIS/EMISSION_MANAGER.sol b/./downloads/ZKSYNC/EMISSION_MANAGER.sol
index 3ee783b..16d9cb7 100644
--- a/./downloads/GNOSIS/EMISSION_MANAGER.sol
+++ b/./downloads/ZKSYNC/EMISSION_MANAGER.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: MIT
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.10;
 
-// downloads/GNOSIS/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
 
 interface IEACAggregatorProxy {
   function decimals() external view returns (uint8);
@@ -20,7 +20,7 @@ interface IEACAggregatorProxy {
   event NewRound(uint256 indexed roundId, address indexed startedBy);
 }
 
-// downloads/GNOSIS/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
 
 /**
  * @title IRewardsDistributor
@@ -197,7 +197,7 @@ interface IRewardsDistributor {
   function getEmissionManager() external view returns (address);
 }
 
-// downloads/GNOSIS/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
 
 interface ITransferStrategyBase {
   event EmergencyWithdrawal(
@@ -324,7 +324,7 @@ contract Ownable is Context {
   }
 }
 
-// downloads/GNOSIS/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
 
 library RewardsDataTypes {
   struct RewardsConfigInput {
@@ -375,7 +375,7 @@ library RewardsDataTypes {
   }
 }
 
-// downloads/GNOSIS/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
 
 /**
  * @title IRewardsController
@@ -573,7 +573,7 @@ interface IRewardsController is IRewardsDistributor {
   ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
 }
 
-// downloads/GNOSIS/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/IEmissionManager.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/IEmissionManager.sol
 
 /**
  * @title IEmissionManager
@@ -686,7 +686,7 @@ interface IEmissionManager {
   function getEmissionAdmin(address reward) external view returns (address);
 }
 
-// downloads/GNOSIS/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/EmissionManager.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/EmissionManager.sol
 
 /**
  * @title EmissionManager
```
