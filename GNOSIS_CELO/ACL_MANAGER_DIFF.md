```diff
diff --git a/./downloads/GNOSIS/ACL_MANAGER.sol b/./downloads/CELO/ACL_MANAGER.sol
index 5f26b31..aba09ce 100644
--- a/./downloads/GNOSIS/ACL_MANAGER.sol
+++ b/./downloads/CELO/ACL_MANAGER.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: MIT
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +24,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -62,17 +62,14 @@ library Errors {
   string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
   string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
   string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
-  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
   string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
   string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
   string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
   string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
   string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
   string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
-  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
   string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
   string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
-  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
   string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
   string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
   string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
@@ -85,7 +82,6 @@ library Errors {
   string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
   string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
   string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = '54'; // 'Claimable rights over underlying not zero (aToken supply or accruedToTreasury)'
-  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
   string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
   string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
   string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
@@ -114,17 +110,28 @@ library Errors {
   string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
   string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
   string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
-  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
   string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
   string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
   string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
-  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
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
+  string public constant NOT_BORROWABLE_IN_EMODE = '100'; // Asset not borrowable in eMode
+  string public constant CALLER_NOT_UMBRELLA = '101'; // The caller of the function is not the umbrella contract
+  string public constant RESERVE_NOT_IN_DEFICIT = '102'; // The reserve is not in deficit
+  string public constant MUST_NOT_LEAVE_DUST = '103'; // Below a certain threshold liquidators need to take the full position
+  string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
 
 /**
  * @dev External interface of AccessControl declared to support ERC165 detection.
@@ -214,7 +221,7 @@ interface IAccessControl {
   function renounceRole(bytes32 role, address account) external;
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/IERC165.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/IERC165.sol
 
 /**
  * @dev Interface of the ERC165 standard, as defined in the
@@ -237,7 +244,7 @@ interface IERC165 {
   function supportsInterface(bytes4 interfaceId) external view returns (bool);
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -464,7 +471,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/Strings.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/Strings.sol
 
 /**
  * @dev String operations.
@@ -529,7 +536,7 @@ library Strings {
   }
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/ERC165.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/ERC165.sol
 
 /**
  * @dev Implementation of the {IERC165} interface.
@@ -554,7 +561,7 @@ abstract contract ERC165 is IERC165 {
   }
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/interfaces/IACLManager.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -727,7 +734,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/dependencies/openzeppelin/contracts/AccessControl.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/dependencies/openzeppelin/contracts/AccessControl.sol
 
 /**
  * @dev Contract module that allows children to implement role-based access
@@ -937,7 +944,7 @@ abstract contract AccessControl is Context, IAccessControl, ERC165 {
   }
 }
 
-// downloads/GNOSIS/ACL_MANAGER/ACLManager/src/core/contracts/protocol/configuration/ACLManager.sol
+// downloads/CELO/ACL_MANAGER/ACLManager/src/contracts/protocol/configuration/ACLManager.sol
 
 /**
  * @title ACLManager
```
