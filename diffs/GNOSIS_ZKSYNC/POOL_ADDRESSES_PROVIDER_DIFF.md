```diff
diff --git a/./downloads/GNOSIS/POOL_ADDRESSES_PROVIDER.sol b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER.sol
index dabaad8..7b370c5 100644
--- a/./downloads/GNOSIS/POOL_ADDRESSES_PROVIDER.sol
+++ b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: MIT
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -244,7 +244,7 @@ abstract contract Context {
   }
 }
 
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
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -544,7 +552,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
 
 /**
  * @dev Contract module which provides a basic access control mechanism, where
@@ -610,7 +618,7 @@ contract Ownable is Context {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
 
 /**
  * @title BaseUpgradeabilityProxy
@@ -673,7 +681,7 @@ contract BaseUpgradeabilityProxy is Proxy {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
 
 /**
  * @title InitializableUpgradeabilityProxy
@@ -700,7 +708,7 @@ contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
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
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title InitializableAdminUpgradeabilityProxy
@@ -808,7 +816,7 @@ contract InitializableImmutableAdminUpgradeabilityProxy is
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/configuration/PoolAddressesProvider.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/configuration/PoolAddressesProvider.sol
 
 /**
  * @title PoolAddressesProvider
```
