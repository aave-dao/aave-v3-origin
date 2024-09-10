```diff
diff --git a/./downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL.sol b/./downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL.sol

-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/StaticATokenLM.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/StaticATokenLM.sol

 /**
  * @title StaticATokenLM
@@ -7540,7 +6090,7 @@ contract StaticATokenLM is
   ///@inheritdoc IERC4626
   function maxRedeem(address owner) public view virtual returns (uint256) {
     address cachedATokenUnderlying = _aTokenUnderlying;
-    DataTypes.ReserveData memory reserveData = POOL.getReserveData(cachedATokenUnderlying);
+    DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(cachedATokenUnderlying);

     // if paused or inactive users cannot withdraw underlying
     if (
@@ -7564,7 +6114,7 @@ contract StaticATokenLM is

   ///@inheritdoc IERC4626
   function maxDeposit(address) public view virtual returns (uint256) {
-    DataTypes.ReserveData memory reserveData = POOL.getReserveData(_aTokenUnderlying);
+    DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(_aTokenUnderlying);

     // if inactive, paused or frozen users cannot deposit underlying
     if (
@@ -7880,7 +6430,7 @@ contract StaticATokenLM is
    * @return The normalized income, expressed in ray
    */
   function _getNormalizedIncome(
-    DataTypes.ReserveData memory reserve
+    DataTypes.ReserveDataLegacy memory reserve
   ) internal view returns (uint256) {
     uint40 timestamp = reserve.lastUpdateTimestamp;

@@ -7897,7 +6447,7 @@ contract StaticATokenLM is
   }
 }

-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/StaticATokenFactory.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/StaticATokenFactory.sol

 /**
  * @title StaticATokenFactory
@@ -7937,7 +6487,7 @@ contract StaticATokenFactory is Initializable, IStaticATokenFactory {
     for (uint256 i = 0; i < underlyings.length; i++) {
       address cachedStaticAToken = _underlyingToStaticAToken[underlyings[i]];
       if (cachedStaticAToken == address(0)) {
-        DataTypes.ReserveData memory reserveData = POOL.getReserveData(underlyings[i]);
+        DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(underlyings[i]);
         require(reserveData.aTokenAddress != address(0), 'UNDERLYING_NOT_LISTED');
         bytes memory symbol = abi.encodePacked(
           'stat',
```
