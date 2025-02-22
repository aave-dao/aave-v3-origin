```diff
diff --git a/./downloads/GNOSIS/UI_POOL_DATA_PROVIDER.sol b/./downloads/CELO/UI_POOL_DATA_PROVIDER.sol
index 9db6a74..18a6e75 100644
--- a/./downloads/GNOSIS/UI_POOL_DATA_PROVIDER.sol
+++ b/./downloads/CELO/UI_POOL_DATA_PROVIDER.sol

-// downloads/GNOSIS/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/interfaces/IUiPoolDataProviderV3.sol
+// downloads/CELO/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/interfaces/IUiPoolDataProviderV3.sol

 interface IUiPoolDataProviderV3 {
   struct AggregatedReserveData {
@@ -2241,6 +2324,8 @@ interface IUiPoolDataProviderV3 {
     // v3.1
     bool virtualAccActive;
     uint128 virtualUnderlyingBalance;
+    // v3.3
+    uint128 deficit;
   }

-// downloads/GNOSIS/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/UiPoolDataProviderV3.sol
+// downloads/CELO/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/UiPoolDataProviderV3.sol

 contract UiPoolDataProviderV3 is IUiPoolDataProviderV3 {
   using WadRayMath for uint256;
   using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
   using UserConfiguration for DataTypes.UserConfigurationMap;

-  IEACAggregatorProxy public immutable networkBaseTokenPriceInUsdProxyAggregator;
-  IEACAggregatorProxy public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;
+  AggregatorInterface public immutable networkBaseTokenPriceInUsdProxyAggregator;
+  AggregatorInterface public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;
   uint256 public constant ETH_CURRENCY_UNIT = 1 ether;
   address public constant MKR_ADDRESS = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

   constructor(
-    IEACAggregatorProxy _networkBaseTokenPriceInUsdProxyAggregator,
-    IEACAggregatorProxy _marketReferenceCurrencyPriceInUsdProxyAggregator
+    AggregatorInterface _networkBaseTokenPriceInUsdProxyAggregator,
+    AggregatorInterface _marketReferenceCurrencyPriceInUsdProxyAggregator
   ) {
     networkBaseTokenPriceInUsdProxyAggregator = _networkBaseTokenPriceInUsdProxyAggregator;
     marketReferenceCurrencyPriceInUsdProxyAggregator = _marketReferenceCurrencyPriceInUsdProxyAggregator;
@@ -3930,6 +4018,7 @@ contract UiPoolDataProviderV3 is IUiPoolDataProviderV3 {
       } catch {}

       // v3 only
+      reserveData.deficit = uint128(pool.getReserveDeficit(reserveData.underlyingAsset));
       reserveData.debtCeiling = reserveConfigurationMap.getDebtCeiling();
       reserveData.debtCeilingDecimals = poolDataProvider.getDebtCeilingDecimals();
       (reserveData.borrowCap, reserveData.supplyCap) = reserveConfigurationMap.getCaps();
```
