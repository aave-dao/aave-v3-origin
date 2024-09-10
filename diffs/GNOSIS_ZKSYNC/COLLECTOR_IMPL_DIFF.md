```diff
diff --git a/./downloads/GNOSIS/COLLECTOR_IMPL.sol b/./downloads/ZKSYNC/COLLECTOR_IMPL.sol

-// downloads/GNOSIS/COLLECTOR_IMPL/Collector/lib/aave-collector-unification/src/contracts/Collector.sol
+// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/periphery/contracts/treasury/Collector.sol

 /**
  * @title Collector
@@ -903,8 +782,6 @@ contract Collector is VersionedInitializable, ICollector, ReentrancyGuard {
       _nextStreamId = nextStreamId;
     }

-    // can be removed after first deployment
-    _initGuard();
     _setFundsAdmin(fundsAdmin);
   }

@@ -1021,9 +898,6 @@ contract Collector is VersionedInitializable, ICollector, ReentrancyGuard {
     }
   }

-  /// @dev needed in order to receive ETH from the Aave v1 ecosystem reserve
-  receive() external payable {}
-
   /// @inheritdoc ICollector
   function setFundsAdmin(address admin) external onlyFundsAdmin {
     _setFundsAdmin(admin);
```
