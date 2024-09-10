```diff
diff --git a/./downloads/GNOSIS/UI_INCENTIVE_DATA_PROVIDER.sol b/./downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER.sol

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
