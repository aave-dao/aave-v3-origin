```diff
diff --git a/./downloads/GNOSIS/ORACLE.sol b/./downloads/ZKSYNC/ORACLE.sol
index 76ddbc4..a893adf 100644
--- a/./downloads/GNOSIS/ORACLE.sol
+++ b/./downloads/ZKSYNC/ORACLE.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/ORACLE/AaveOracle/src/core/contracts/dependencies/chainlink/AggregatorInterface.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/dependencies/chainlink/AggregatorInterface.sol
 
 // Chainlink Contracts v0.8
 
@@ -21,7 +21,7 @@ interface AggregatorInterface {
   event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
 }
 
-// downloads/GNOSIS/ORACLE/AaveOracle/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -248,7 +248,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/ORACLE/AaveOracle/src/core/contracts/interfaces/IPriceOracleGetter.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/interfaces/IPriceOracleGetter.sol
 
 /**
  * @title IPriceOracleGetter
@@ -278,7 +278,7 @@ interface IPriceOracleGetter {
   function getAssetPrice(address asset) external view returns (uint256);
 }
 
-// downloads/GNOSIS/ORACLE/AaveOracle/src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -376,9 +376,17 @@ library Errors {
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
 
-// downloads/GNOSIS/ORACLE/AaveOracle/src/core/contracts/interfaces/IACLManager.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -551,7 +559,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/GNOSIS/ORACLE/AaveOracle/src/core/contracts/interfaces/IAaveOracle.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/interfaces/IAaveOracle.sol
 
 /**
  * @title IAaveOracle
@@ -619,7 +627,7 @@ interface IAaveOracle is IPriceOracleGetter {
   function getFallbackOracle() external view returns (address);
 }
 
-// downloads/GNOSIS/ORACLE/AaveOracle/src/core/contracts/misc/AaveOracle.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/misc/AaveOracle.sol
 
 /**
  * @title AaveOracle
```
