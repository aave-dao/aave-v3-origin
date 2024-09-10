```diff
diff --git a/./downloads/GNOSIS/POOL_ADDRESSES_PROVIDER_REGISTRY.sol b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY.sol
index 272a77e..84a6931 100644
--- a/./downloads/GNOSIS/POOL_ADDRESSES_PROVIDER_REGISTRY.sol
+++ b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: MIT
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +24,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/interfaces/IPoolAddressesProviderRegistry.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/interfaces/IPoolAddressesProviderRegistry.sol
 
 /**
  * @title IPoolAddressesProviderRegistry
@@ -84,7 +84,7 @@ interface IPoolAddressesProviderRegistry {
   function unregisterAddressesProvider(address provider) external;
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -182,9 +182,17 @@ library Errors {
   string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
   string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
   string public constant FLASHLOAN_DISABLED = '91'; // FlashLoaning for this asset is disabled
+  string public constant INVALID_MAX_RATE = '92'; // The expect maximum borrow rate is invalid
+  string public constant WITHDRAW_TO_ATOKEN = '93'; // Withdrawing to the aToken is not allowed
+  string public constant SUPPLY_TO_ATOKEN = '94'; // Supplying to the aToken is not allowed
+  string public constant SLOPE_2_MUST_BE_GTE_SLOPE_1 = '95'; // Variable interest rate slope 2 can not be lower than slope 1
+  string public constant CALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN = '96'; // 'The caller of the function is not a risk, pool or emergency admin'
+  string public constant LIQUIDATION_GRACE_SENTINEL_CHECK_FAILED = '97'; // 'Liquidation grace sentinel validation failed'
+  string public constant INVALID_GRACE_PERIOD = '98'; // Grace period above a valid range
+  string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
 
 /**
  * @dev Contract module which provides a basic access control mechanism, where
@@ -250,7 +258,7 @@ contract Ownable is Context {
   }
 }
 
-// downloads/GNOSIS/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol
 
 /**
  * @title PoolAddressesProviderRegistry
```
