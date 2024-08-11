```diff
diff --git a/./downloads/ARBITRUM/ORACLE.sol b/./downloads/ZKSYNC/ORACLE.sol
index 4729969..a893adf 100644
--- a/./downloads/ARBITRUM/ORACLE.sol
+++ b/./downloads/ZKSYNC/ORACLE.sol

-// downloads/ARBITRUM/ORACLE/AaveOracle/@aave/core-v3/contracts/misc/AaveOracle.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/misc/AaveOracle.sol

 /**
  * @title AaveOracle
@@ -641,7 +649,7 @@ contract AaveOracle is IAaveOracle {

   /**
    * @dev Only asset listing or pool admin can call functions marked by this modifier.
-   **/
+   */
   modifier onlyAssetListingOrPoolAdmins() {
     _onlyAssetListingOrPoolAdmins();
     _;
```
