```diff
diff --git a/./downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER.sol b/./downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER.sol
index 3ef0f72..8a55fee 100644
--- a/./downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER.sol
+++ b/./downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: MIT
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
 
 interface IEACAggregatorProxy {
   function decimals() external view returns (uint8);
@@ -20,7 +20,7 @@ interface IEACAggregatorProxy {
   event NewRound(uint256 indexed roundId, address indexed startedBy);
 }
 
-// downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
 
 /**
  * @title IRewardsDistributor
@@ -197,7 +197,7 @@ interface IRewardsDistributor {
   function getEmissionManager() external view returns (address);
 }
 
-// downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
 
 interface ITransferStrategyBase {
   event EmergencyWithdrawal(
@@ -1383,7 +1383,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/misc/interfaces/IUiIncentiveDataProviderV3.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/misc/interfaces/IUiIncentiveDataProviderV3.sol
 
 interface IUiIncentiveDataProviderV3 {
   struct AggregatedReserveIncentiveData {
@@ -1639,7 +1639,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
 
 library RewardsDataTypes {
   struct RewardsConfigInput {
@@ -3391,7 +3391,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
 
 /**
  * @title IRewardsController
@@ -3813,7 +3813,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }
 
-// downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/misc/UiIncentiveDataProviderV3.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/misc/UiIncentiveDataProviderV3.sol
 
 contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
   using UserConfiguration for DataTypes.UserConfigurationMap;
@@ -3848,7 +3848,7 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
       AggregatedReserveIncentiveData memory reserveIncentiveData = reservesIncentiveData[i];
       reserveIncentiveData.underlyingAsset = reserves[i];
 
-      DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);
+      DataTypes.ReserveDataLegacy memory baseData = pool.getReserveData(reserves[i]);
 
       // Get aTokens rewards information
       // TODO: check that this is deployed correctly on contract and remove casting
@@ -4037,7 +4037,7 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
     );
 
     for (uint256 i = 0; i < reserves.length; i++) {
-      DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);
+      DataTypes.ReserveDataLegacy memory baseData = pool.getReserveData(reserves[i]);
 
       // user reserve data
       userReservesIncentivesData[i].underlyingAsset = reserves[i];
```
