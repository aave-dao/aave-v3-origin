```diff
diff --git a/./downloads/GNOSIS/COLLECTOR_IMPL.sol b/./downloads/CELO/COLLECTOR_IMPL.sol
index 2ac55c8..7a7eb91 100644
--- a/./downloads/GNOSIS/COLLECTOR_IMPL.sol
+++ b/./downloads/CELO/COLLECTOR_IMPL.sol
@@ -659,7 +659,7 @@ abstract contract ContextUpgradeable is Initializable {
   }
 }
 
-// downloads/GNOSIS/COLLECTOR_IMPL/CollectorWithCustomImpl/lib/aave-v3-origin/src/contracts/treasury/ICollector.sol
+// downloads/CELO/COLLECTOR_IMPL/Collector/src/contracts/treasury/ICollector.sol
 
 interface ICollector {
   struct Stream {
@@ -722,7 +722,7 @@ interface ICollector {
   /**
    * @dev Only caller with FUNDS_ADMIN role or stream recipient can call
    */
-  error OnlyFundsAdminOrRceipient();
+  error OnlyFundsAdminOrRecipient();
 
   /**
    * @dev The provided ID does not belong to an existing stream
@@ -1553,7 +1553,7 @@ library SafeERC20 {
   }
 }
 
-// downloads/GNOSIS/COLLECTOR_IMPL/CollectorWithCustomImpl/lib/aave-v3-origin/src/contracts/treasury/Collector.sol
+// downloads/CELO/COLLECTOR_IMPL/Collector/src/contracts/treasury/Collector.sol
 
 /**
  * @title Collector
@@ -1616,7 +1616,7 @@ contract Collector is AccessControlUpgradeable, ReentrancyGuardUpgradeable, ICol
    */
   modifier onlyAdminOrRecipient(uint256 streamId) {
     if (_onlyFundsAdmin() == false && msg.sender != _streams[streamId].recipient) {
-      revert OnlyFundsAdminOrRceipient();
+      revert OnlyFundsAdminOrRecipient();
     }
     _;
   }
@@ -1643,6 +1643,7 @@ contract Collector is AccessControlUpgradeable, ReentrancyGuardUpgradeable, ICol
     __AccessControl_init();
     __ReentrancyGuard_init();
     _grantRole(DEFAULT_ADMIN_ROLE, admin);
+    _grantRole(FUNDS_ADMIN_ROLE, admin);
     if (nextStreamId != 0) {
       _nextStreamId = nextStreamId;
     }
@@ -1883,28 +1884,3 @@ contract Collector is AccessControlUpgradeable, ReentrancyGuardUpgradeable, ICol
   /// @dev needed in order to receive ETH from the Aave v1 ecosystem reserve
   receive() external payable {}
 }
-
-// downloads/GNOSIS/COLLECTOR_IMPL/CollectorWithCustomImpl/src/CollectorWithCustomImpl.sol
-
-/**
- * @title Collector
- * Custom modifications of this implementation:
- * - the initialize function manually alters private storage slots via assembly
- * - storage slot 0 (previously revision) is reset to zero
- * - storage slot 51 (previously _status) is set to zero
- * - storage slot 52 (previously _fundsAdmin) is set to zero
- * @author BGD Labs
- *
- */
-contract CollectorWithCustomImpl is Collector {
-  function initialize(uint256, address admin) external virtual override initializer {
-    assembly {
-      sstore(0, 0) // this slot was revision, which is no longer used
-      sstore(51, 0) // this slot was _status, but is now part of the gap
-      sstore(52, 0) // this slot was _fundsAdmin, but is now unused
-    }
-    __AccessControl_init();
-    __ReentrancyGuard_init();
-    _grantRole(DEFAULT_ADMIN_ROLE, admin);
-  }
-}
```
