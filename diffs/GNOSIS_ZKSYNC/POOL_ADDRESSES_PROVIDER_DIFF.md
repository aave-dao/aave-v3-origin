```diff
diff --git a/./downloads/GNOSIS/POOL_ADDRESSES_PROVIDER.sol b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER.sol

-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol

 /**
  * @title Proxy
@@ -263,6 +263,14 @@ abstract contract Proxy {
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
@@ -317,7 +325,7 @@ abstract contract Proxy {
   }
 }

-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol

 /**
  * @title BaseImmutableAdminUpgradeabilityProxy
@@ -717,10 +725,10 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {

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

   modifier ifAdmin() {
@@ -783,7 +791,7 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }

```
