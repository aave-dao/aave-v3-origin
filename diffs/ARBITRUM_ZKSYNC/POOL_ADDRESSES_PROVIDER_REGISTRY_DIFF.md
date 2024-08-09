```diff
diff --git a/./downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER_REGISTRY.sol b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY.sol
index b396e1f..84a6931 100644
--- a/./downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER_REGISTRY.sol
+++ b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
-pragma solidity =0.8.10;
+pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,13 +24,13 @@ abstract contract Context {
   }
 }
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/@aave/core-v3/contracts/interfaces/IPoolAddressesProviderRegistry.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/interfaces/IPoolAddressesProviderRegistry.sol
 
 /**
  * @title IPoolAddressesProviderRegistry
  * @author Aave
  * @notice Defines the basic interface for an Aave Pool Addresses Provider Registry.
- **/
+ */
 interface IPoolAddressesProviderRegistry {
   /**
    * @dev Emitted when a new AddressesProvider is registered.
@@ -49,7 +49,7 @@ interface IPoolAddressesProviderRegistry {
   /**
    * @notice Returns the list of registered addresses providers
    * @return The list of addresses providers
-   **/
+   */
   function getAddressesProvidersList() external view returns (address[] memory);
 
   /**
@@ -74,17 +74,17 @@ interface IPoolAddressesProviderRegistry {
    * @dev The id must not be used by an already registered PoolAddressesProvider
    * @param provider The address of the new PoolAddressesProvider
    * @param id The id for the new PoolAddressesProvider, referring to the market it belongs to
-   **/
+   */
   function registerAddressesProvider(address provider, uint256 id) external;
 
   /**
    * @notice Removes an addresses provider from the list of registered addresses providers
    * @param provider The PoolAddressesProvider address
-   **/
+   */
   function unregisterAddressesProvider(address provider) external;
 }
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/@aave/core-v3/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -139,13 +139,12 @@ library Errors {
   string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '45'; // 'Health factor is not below the threshold'
   string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = '46'; // 'The collateral chosen cannot be liquidated'
   string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '47'; // 'User did not borrow the specified currency'
-  string public constant SAME_BLOCK_BORROW_REPAY = '48'; // 'Borrow and repay in same block is not allowed'
   string public constant INCONSISTENT_FLASHLOAN_PARAMS = '49'; // 'Inconsistent flashloan parameters'
   string public constant BORROW_CAP_EXCEEDED = '50'; // 'Borrow cap is exceeded'
   string public constant SUPPLY_CAP_EXCEEDED = '51'; // 'Supply cap is exceeded'
   string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
   string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
-  string public constant ATOKEN_SUPPLY_NOT_ZERO = '54'; // 'AToken supply is not zero'
+  string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = '54'; // 'Claimable rights over underlying not zero (aToken supply or accruedToTreasury)'
   string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
   string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
   string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
@@ -153,7 +152,7 @@ library Errors {
   string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
   string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
   string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
-  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
+  string public constant USER_IN_ISOLATION_MODE_OR_LTV_ZERO = '62'; // 'User is in isolation mode or ltv is zero'
   string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
   string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
   string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
@@ -182,9 +181,18 @@ library Errors {
   string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
   string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
   string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
+  string public constant FLASHLOAN_DISABLED = '91'; // FlashLoaning for this asset is disabled
+  string public constant INVALID_MAX_RATE = '92'; // The expect maximum borrow rate is invalid
+  string public constant WITHDRAW_TO_ATOKEN = '93'; // Withdrawing to the aToken is not allowed
+  string public constant SUPPLY_TO_ATOKEN = '94'; // Supplying to the aToken is not allowed
+  string public constant SLOPE_2_MUST_BE_GTE_SLOPE_1 = '95'; // Variable interest rate slope 2 can not be lower than slope 1
+  string public constant CALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN = '96'; // 'The caller of the function is not a risk, pool or emergency admin'
+  string public constant LIQUIDATION_GRACE_SENTINEL_CHECK_FAILED = '97'; // 'Liquidation grace sentinel validation failed'
+  string public constant INVALID_GRACE_PERIOD = '98'; // Grace period above a valid range
+  string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
 }
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
 
 /**
  * @dev Contract module which provides a basic access control mechanism, where
@@ -250,7 +258,7 @@ contract Ownable is Context {
   }
 }
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/@aave/core-v3/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY/PoolAddressesProviderRegistry/src/core/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol
 
 /**
  * @title PoolAddressesProviderRegistry
@@ -258,7 +266,7 @@ contract Ownable is Context {
  * @notice Main registry of PoolAddressesProvider of Aave markets.
  * @dev Used for indexing purposes of Aave protocol's markets. The id assigned to a PoolAddressesProvider refers to the
  * market it is connected with, for example with `1` for the Aave main market and `2` for the next created.
- **/
+ */
 contract PoolAddressesProviderRegistry is Ownable, IPoolAddressesProviderRegistry {
   // Map of address provider ids (addressesProvider => id)
   mapping(address => uint256) private _addressesProviderToId;
```
