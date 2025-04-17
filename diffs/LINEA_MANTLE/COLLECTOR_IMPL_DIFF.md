```diff
diff --git a/./downloads/LINEA/COLLECTOR_IMPL.sol b/./downloads/MANTLE/COLLECTOR_IMPL.sol
index 7b1af34..f1bf291 100644
--- a/./downloads/LINEA/COLLECTOR_IMPL.sol
+++ b/./downloads/MANTLE/COLLECTOR_IMPL.sol
@@ -646,7 +646,7 @@ abstract contract ContextUpgradeable is Initializable {
     }
 }
 
-// downloads/LINEA/COLLECTOR_IMPL/CollectorWithCustomImplNewLayout/lib/aave-v3-origin/src/contracts/treasury/ICollector.sol
+// downloads/MANTLE/COLLECTOR_IMPL/Collector/src/contracts/treasury/ICollector.sol
 
 interface ICollector {
   struct Stream {
@@ -709,7 +709,7 @@ interface ICollector {
   /**
    * @dev Only caller with FUNDS_ADMIN role or stream recipient can call
    */
-  error OnlyFundsAdminOrRceipient();
+  error OnlyFundsAdminOrRecipient();
 
   /**
    * @dev The provided ID does not belong to an existing stream
@@ -1510,7 +1510,7 @@ library SafeERC20 {
     }
 }
 
-// downloads/LINEA/COLLECTOR_IMPL/CollectorWithCustomImplNewLayout/lib/aave-v3-origin/src/contracts/treasury/Collector.sol
+// downloads/MANTLE/COLLECTOR_IMPL/Collector/src/contracts/treasury/Collector.sol
 
 /**
  * @title Collector
@@ -1573,7 +1573,7 @@ contract Collector is AccessControlUpgradeable, ReentrancyGuardUpgradeable, ICol
    */
   modifier onlyAdminOrRecipient(uint256 streamId) {
     if (_onlyFundsAdmin() == false && msg.sender != _streams[streamId].recipient) {
-      revert OnlyFundsAdminOrRceipient();
+      revert OnlyFundsAdminOrRecipient();
     }
     _;
   }
@@ -1600,6 +1600,7 @@ contract Collector is AccessControlUpgradeable, ReentrancyGuardUpgradeable, ICol
     __AccessControl_init();
     __ReentrancyGuard_init();
     _grantRole(DEFAULT_ADMIN_ROLE, admin);
+    _grantRole(FUNDS_ADMIN_ROLE, admin);
     if (nextStreamId != 0) {
       _nextStreamId = nextStreamId;
     }
@@ -1840,28 +1841,3 @@ contract Collector is AccessControlUpgradeable, ReentrancyGuardUpgradeable, ICol
   /// @dev needed in order to receive ETH from the Aave v1 ecosystem reserve
   receive() external payable {}
 }
-
-// downloads/LINEA/COLLECTOR_IMPL/CollectorWithCustomImplNewLayout/src/CollectorWithCustomImplNewLayout.sol
-
-/**
- * @title Collector
- * Custom modifications of this implementation:
- * - the initialize function manually alters private storage slots via assembly
- * - storage slot 0 (previously revision) is reset to zero
- * - storage slot 53 (previously fundsAdmin) is set to 100000 (the previous nextStreamId)
- * - storage slot 54 (previously nextStreamId) is reset to 0
- * @author BGD Labs
- *
- */
-contract CollectorWithCustomImplNewLayout is Collector {
-  function initialize(uint256, address admin) external virtual override initializer {
-    assembly {
-      sstore(0, 0) // this slot was revision, which is no longer used
-      sstore(53, 100000) // this slot was _fundsAdmin, but is now _nextStreamId
-      sstore(54, 0) // this slot was _nextStreamId, but is now _streams
-    }
-    __AccessControl_init();
-    __ReentrancyGuard_init();
-    _grantRole(DEFAULT_ADMIN_ROLE, admin);
-  }
-}
```
