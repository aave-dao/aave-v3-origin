```diff
diff --git a/./downloads/GNOSIS/ACL_MANAGER.sol b/./downloads/ZKSYNC/ACL_MANAGER.sol
index 5c5e328..88e1973 100644
--- a/./downloads/GNOSIS/ACL_MANAGER.sol
+++ b/./downloads/ZKSYNC/ACL_MANAGER.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: MIT
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +24,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
 
 /**
  * @dev External interface of AccessControl declared to support ERC165 detection.
@@ -114,7 +114,7 @@ interface IAccessControl {
   function renounceRole(bytes32 role, address account) external;
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/IERC165.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/IERC165.sol
 
 /**
  * @dev Interface of the ERC165 standard, as defined in the
@@ -137,7 +137,7 @@ interface IERC165 {
   function supportsInterface(bytes4 interfaceId) external view returns (bool);
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/Strings.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/Strings.sol
 
 /**
  * @dev String operations.
@@ -202,7 +202,7 @@ library Strings {
   }
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -429,7 +429,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -527,9 +527,17 @@ library Errors {
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
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/ERC165.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/ERC165.sol
 
 /**
  * @dev Implementation of the {IERC165} interface.
@@ -554,7 +562,7 @@ abstract contract ERC165 is IERC165 {
   }
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/interfaces/IACLManager.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -727,7 +735,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/AccessControl.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/AccessControl.sol
 
 /**
  * @dev Contract module that allows children to implement role-based access
@@ -937,7 +945,7 @@ abstract contract AccessControl is Context, IAccessControl, ERC165 {
   }
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/protocol/configuration/ACLManager.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/protocol/configuration/ACLManager.sol
 
 /**
  * @title ACLManager
```
