```diff
diff --git a/./downloads/MAINNET/UI_POOL_DATA_PROVIDER.sol b/./downloads/ETHERFI/UI_POOL_DATA_PROVIDER.sol
index a888c89..25ba24c 100644
--- a/./downloads/MAINNET/UI_POOL_DATA_PROVIDER.sol
+++ b/./downloads/ETHERFI/UI_POOL_DATA_PROVIDER.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/MAINNET/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
+// downloads/ETHERFI/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
 
 interface IEACAggregatorProxy {
   function decimals() external view returns (uint8);
@@ -991,7 +991,7 @@ library DataTypes {
   }
 }
 
-// downloads/MAINNET/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/periphery/contracts/misc/interfaces/IERC20DetailedBytes.sol
+// downloads/ETHERFI/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/periphery/contracts/misc/interfaces/IERC20DetailedBytes.sol
 
 interface IERC20DetailedBytes is IERC20 {
   function name() external view returns (bytes32);
@@ -1001,7 +1001,7 @@ interface IERC20DetailedBytes is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/MAINNET/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/periphery/contracts/misc/interfaces/IUiPoolDataProviderV3.sol
+// downloads/ETHERFI/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/periphery/contracts/misc/interfaces/IUiPoolDataProviderV3.sol
 
 interface IUiPoolDataProviderV3 {
   struct InterestRates {
@@ -4051,7 +4051,7 @@ contract AaveProtocolDataProvider is IPoolDataProvider {
   }
 }
 
-// downloads/MAINNET/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/periphery/contracts/misc/UiPoolDataProviderV3.sol
+// downloads/ETHERFI/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/periphery/contracts/misc/UiPoolDataProviderV3.sol
 
 contract UiPoolDataProviderV3 is IUiPoolDataProviderV3 {
   using WadRayMath for uint256;
```
