```diff
diff --git a/./downloads/GNOSIS/POOL_ADDRESSES_PROVIDER.sol b/./downloads/SONIC/POOL_ADDRESSES_PROVIDER.sol
index ac6b143..d070e4e 100644
--- a/./downloads/GNOSIS/POOL_ADDRESSES_PROVIDER.sol
+++ b/./downloads/SONIC/POOL_ADDRESSES_PROVIDER.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: MIT
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -244,7 +244,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -471,7 +471,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
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
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/dependencies/openzeppelin/contracts/Ownable.sol
 
 /**
  * @dev Contract module which provides a basic access control mechanism, where
@@ -610,7 +618,7 @@ contract Ownable is Context {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
 
 /**
  * @title BaseUpgradeabilityProxy
@@ -673,7 +681,7 @@ contract BaseUpgradeabilityProxy is Proxy {
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
 
   modifier ifAdmin() {
@@ -756,7 +764,7 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
 
 /**
  * @title InitializableUpgradeabilityProxy
@@ -783,7 +791,7 @@ contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/misc/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title InitializableAdminUpgradeabilityProxy
@@ -808,7 +816,7 @@ contract InitializableImmutableAdminUpgradeabilityProxy is
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/configuration/PoolAddressesProvider.sol
+// downloads/SONIC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/contracts/protocol/configuration/PoolAddressesProvider.sol
 
 /**
  * @title PoolAddressesProvider
```
