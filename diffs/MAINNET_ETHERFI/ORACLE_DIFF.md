```diff
diff --git a/./downloads/MAINNET/ORACLE.sol b/./downloads/ETHERFI/ORACLE.sol
index 389dfc3..e21a63c 100644
--- a/./downloads/MAINNET/ORACLE.sol
+++ b/./downloads/ETHERFI/ORACLE.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: BUSL-1.1
-pragma solidity =0.8.10 ^0.8.0;
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/MAINNET/ORACLE/AaveOracle/@aave/core-v3/contracts/dependencies/chainlink/AggregatorInterface.sol
+// downloads/ETHERFI/ORACLE/AaveOracle/src/core/contracts/dependencies/chainlink/AggregatorInterface.sol
 
 // Chainlink Contracts v0.8
 
@@ -21,7 +21,7 @@ interface AggregatorInterface {
   event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
 }
 
-// downloads/MAINNET/ORACLE/AaveOracle/@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ETHERFI/ORACLE/AaveOracle/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -248,7 +248,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/MAINNET/ORACLE/AaveOracle/@aave/core-v3/contracts/interfaces/IPriceOracleGetter.sol
+// downloads/ETHERFI/ORACLE/AaveOracle/src/core/contracts/interfaces/IPriceOracleGetter.sol
 
 /**
  * @title IPriceOracleGetter
@@ -278,7 +278,7 @@ interface IPriceOracleGetter {
   function getAssetPrice(address asset) external view returns (uint256);
 }
 
-// downloads/MAINNET/ORACLE/AaveOracle/@aave/core-v3/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ETHERFI/ORACLE/AaveOracle/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -346,7 +346,7 @@ library Errors {
   string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
   string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
   string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
-  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
+  string public constant USER_IN_ISOLATION_MODE_OR_LTV_ZERO = '62'; // 'User is in isolation mode or ltv is zero'
   string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
   string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
   string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
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
 
-// downloads/MAINNET/ORACLE/AaveOracle/@aave/core-v3/contracts/interfaces/IACLManager.sol
+// downloads/ETHERFI/ORACLE/AaveOracle/src/core/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -551,7 +559,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/MAINNET/ORACLE/AaveOracle/@aave/core-v3/contracts/interfaces/IAaveOracle.sol
+// downloads/ETHERFI/ORACLE/AaveOracle/src/core/contracts/interfaces/IAaveOracle.sol
 
 /**
  * @title IAaveOracle
@@ -619,7 +627,7 @@ interface IAaveOracle is IPriceOracleGetter {
   function getFallbackOracle() external view returns (address);
 }
 
-// downloads/MAINNET/ORACLE/AaveOracle/@aave/core-v3/contracts/misc/AaveOracle.sol
+// downloads/ETHERFI/ORACLE/AaveOracle/src/core/contracts/misc/AaveOracle.sol
 
 /**
  * @title AaveOracle
```
