```diff
diff --git a/./downloads/GNOSIS/POOL_ADDRESSES_PROVIDER.sol b/./downloads/SONIC/POOL_ADDRESSES_PROVIDER.sol
index ac6b143..d070e4e 100644
--- a/./downloads/GNOSIS/POOL_ADDRESSES_PROVIDER.sol
+++ b/./downloads/SONIC/POOL_ADDRESSES_PROVIDER.sol

-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol

 /**
  * @title Proxy
@@ -490,6 +490,14 @@ abstract contract Proxy {
     _fallback();
   }

+  /**
+   * @dev Fallback function that will run if call data is empty.
+   * IMPORTANT. receive() on implementation contracts will be unreachable
+   */
+  receive() external payable {
+    _fallback();
+  }
+
   /**
    * @return The Address of the implementation.
    */
@@ -544,7 +552,7 @@ abstract contract Proxy {
   }
 }

-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/misc/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol

 /**
  * @title BaseImmutableAdminUpgradeabilityProxy
@@ -690,10 +698,10 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {

   /**
    * @dev Constructor.
-   * @param admin The address of the admin
+   * @param admin_ The address of the admin
    */
-  constructor(address admin) {
-    _admin = admin;
+  constructor(address admin_) {
+    _admin = admin_;
   }
```
