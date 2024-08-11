```diff
diff --git a/./downloads/ARBITRUM/L2_ENCODER.sol b/./downloads/ZKSYNC/L2_ENCODER.sol
index ab9c6a7..4595def 100644
--- a/./downloads/ARBITRUM/L2_ENCODER.sol
+++ b/./downloads/ZKSYNC/L2_ENCODER.sol

-// downloads/ARBITRUM/L2_ENCODER/L2Encoder/@aave/core-v3/contracts/misc/L2Encoder.sol
+// downloads/ZKSYNC/L2_ENCODER/L2Encoder/src/core/contracts/misc/L2Encoder.sol

 /**
  * @title L2Encoder
@@ -1512,7 +1663,7 @@ contract L2Encoder {
     uint256 amount,
     uint16 referralCode
   ) external view returns (bytes32) {
-    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
+    DataTypes.ReserveDataLegacy memory data = POOL.getReserveData(asset);

     uint16 assetId = data.id;
     uint128 shortenedAmount = amount.toUint128();
@@ -1548,7 +1699,7 @@ contract L2Encoder {
     bytes32 permitR,
     bytes32 permitS
   ) external view returns (bytes32, bytes32, bytes32) {
-    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
+    DataTypes.ReserveDataLegacy memory data = POOL.getReserveData(asset);

     uint16 assetId = data.id;
     uint128 shortenedAmount = amount.toUint128();
@@ -1576,7 +1727,7 @@ contract L2Encoder {
    * @return compact representation of withdraw parameters
    */
   function encodeWithdrawParams(address asset, uint256 amount) external view returns (bytes32) {
-    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
+    DataTypes.ReserveDataLegacy memory data = POOL.getReserveData(asset);

     uint16 assetId = data.id;
     uint128 shortenedAmount = amount == type(uint256).max ? type(uint128).max : amount.toUint128();
@@ -1604,7 +1755,7 @@ contract L2Encoder {
     uint256 interestRateMode,
     uint16 referralCode
   ) external view returns (bytes32) {
-    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
+    DataTypes.ReserveDataLegacy memory data = POOL.getReserveData(asset);

     uint16 assetId = data.id;
     uint128 shortenedAmount = amount.toUint128();
@@ -1636,7 +1787,7 @@ contract L2Encoder {
     uint256 amount,
     uint256 interestRateMode
   ) public view returns (bytes32) {
-    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
+    DataTypes.ReserveDataLegacy memory data = POOL.getReserveData(asset);

     uint16 assetId = data.id;
     uint128 shortenedAmount = amount == type(uint256).max ? type(uint128).max : amount.toUint128();
@@ -1673,7 +1824,7 @@ contract L2Encoder {
     bytes32 permitR,
     bytes32 permitS
   ) external view returns (bytes32, bytes32, bytes32) {
-    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
+    DataTypes.ReserveDataLegacy memory data = POOL.getReserveData(asset);

     uint16 assetId = data.id;
     uint128 shortenedAmount = amount == type(uint256).max ? type(uint128).max : amount.toUint128();
@@ -1722,7 +1873,7 @@ contract L2Encoder {
     address asset,
     uint256 interestRateMode
   ) external view returns (bytes32) {
-    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
+    DataTypes.ReserveDataLegacy memory data = POOL.getReserveData(asset);
     uint16 assetId = data.id;
     uint8 shortenedInterestRateMode = interestRateMode.toUint8();
     bytes32 res;
@@ -1742,7 +1893,7 @@ contract L2Encoder {
     address asset,
     address user
   ) external view returns (bytes32) {
-    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
+    DataTypes.ReserveDataLegacy memory data = POOL.getReserveData(asset);
     uint16 assetId = data.id;

     bytes32 res;
@@ -1762,7 +1913,7 @@ contract L2Encoder {
     address asset,
     bool useAsCollateral
   ) external view returns (bytes32) {
-    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
+    DataTypes.ReserveDataLegacy memory data = POOL.getReserveData(asset);
     uint16 assetId = data.id;
     bytes32 res;
     assembly {
@@ -1789,10 +1940,10 @@ contract L2Encoder {
     uint256 debtToCover,
     bool receiveAToken
   ) external view returns (bytes32, bytes32) {
-    DataTypes.ReserveData memory collateralData = POOL.getReserveData(collateralAsset);
+    DataTypes.ReserveDataLegacy memory collateralData = POOL.getReserveData(collateralAsset);
     uint16 collateralAssetId = collateralData.id;

-    DataTypes.ReserveData memory debtData = POOL.getReserveData(debtAsset);
+    DataTypes.ReserveDataLegacy memory debtData = POOL.getReserveData(debtAsset);
     uint16 debtAssetId = debtData.id;

     uint128 shortenedDebtToCover = debtToCover == type(uint256).max
@@ -1809,5 +1960,3 @@ contract L2Encoder {
     return (res1, res2);
   }
 }

```
