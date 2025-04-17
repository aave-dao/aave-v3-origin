```diff
diff --git a/./downloads/LINEA/ACL_MANAGER.sol b/./downloads/MANTLE/ACL_MANAGER.sol
index 920985b..bd04b30 100644
--- a/./downloads/LINEA/ACL_MANAGER.sol
+++ b/./downloads/MANTLE/ACL_MANAGER.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +24,7 @@ abstract contract Context {
   }
 }
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -125,9 +125,13 @@ library Errors {
   string public constant INVALID_GRACE_PERIOD = '98'; // Grace period above a valid range
   string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
   string public constant NOT_BORROWABLE_IN_EMODE = '100'; // Asset not borrowable in eMode
+  string public constant CALLER_NOT_UMBRELLA = '101'; // The caller of the function is not the umbrella contract
+  string public constant RESERVE_NOT_IN_DEFICIT = '102'; // The reserve is not in deficit
+  string public constant MUST_NOT_LEAVE_DUST = '103'; // Below a certain threshold liquidators need to take the full position
+  string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
 
 /**
  * @dev External interface of AccessControl declared to support ERC165 detection.
@@ -217,7 +221,7 @@ interface IAccessControl {
   function renounceRole(bytes32 role, address account) external;
 }
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/IERC165.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/IERC165.sol
 
 /**
  * @dev Interface of the ERC165 standard, as defined in the
@@ -240,7 +244,7 @@ interface IERC165 {
   function supportsInterface(bytes4 interfaceId) external view returns (bool);
 }
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -467,7 +471,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/Strings.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/Strings.sol
 
 /**
  * @dev String operations.
@@ -532,7 +536,7 @@ library Strings {
   }
 }
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/ERC165.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/ERC165.sol
 
 /**
  * @dev Implementation of the {IERC165} interface.
@@ -557,7 +561,7 @@ abstract contract ERC165 is IERC165 {
   }
 }
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/interfaces/IACLManager.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -730,7 +734,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/AccessControl.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/AccessControl.sol
 
 /**
  * @dev Contract module that allows children to implement role-based access
@@ -940,7 +944,7 @@ abstract contract AccessControl is Context, IAccessControl, ERC165 {
   }
 }
 
-// downloads/LINEA/ACL_MANAGER/ACLManager/src/contracts/protocol/configuration/ACLManager.sol
+// downloads/MANTLE/ACL_MANAGER/ACLManager/src/contracts/protocol/configuration/ACLManager.sol
 
 /**
  * @title ACLManager
```
