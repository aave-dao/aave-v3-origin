```diff
diff --git a/./downloads/ARBITRUM/ORACLE.sol b/./downloads/ZKSYNC/ORACLE.sol
index 4729969..a893adf 100644
--- a/./downloads/ARBITRUM/ORACLE.sol
+++ b/./downloads/ZKSYNC/ORACLE.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: BUSL-1.1
-pragma solidity =0.8.10 ^0.8.0;
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/ARBITRUM/ORACLE/AaveOracle/@aave/core-v3/contracts/dependencies/chainlink/AggregatorInterface.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/dependencies/chainlink/AggregatorInterface.sol
 
 // Chainlink Contracts v0.8
 
@@ -21,13 +21,13 @@ interface AggregatorInterface {
   event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
 }
 
-// downloads/ARBITRUM/ORACLE/AaveOracle/@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
  * @author Aave
  * @notice Defines the basic interface for a Pool Addresses Provider.
- **/
+ */
 interface IPoolAddressesProvider {
   /**
    * @dev Emitted when the market identifier is updated.
@@ -122,7 +122,7 @@ interface IPoolAddressesProvider {
   /**
    * @notice Returns the id of the Aave market to which this contract points to.
    * @return The market id
-   **/
+   */
   function getMarketId() external view returns (string memory);
 
   /**
@@ -164,27 +164,27 @@ interface IPoolAddressesProvider {
   /**
    * @notice Returns the address of the Pool proxy.
    * @return The Pool proxy address
-   **/
+   */
   function getPool() external view returns (address);
 
   /**
    * @notice Updates the implementation of the Pool, or creates a proxy
    * setting the new `pool` implementation when the function is called for the first time.
    * @param newPoolImpl The new Pool implementation
-   **/
+   */
   function setPoolImpl(address newPoolImpl) external;
 
   /**
    * @notice Returns the address of the PoolConfigurator proxy.
    * @return The PoolConfigurator proxy address
-   **/
+   */
   function getPoolConfigurator() external view returns (address);
 
   /**
    * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
    * setting the new `PoolConfigurator` implementation when the function is called for the first time.
    * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
-   **/
+   */
   function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;
 
   /**
@@ -208,7 +208,7 @@ interface IPoolAddressesProvider {
   /**
    * @notice Updates the address of the ACL manager.
    * @param newAclManager The address of the new ACLManager
-   **/
+   */
   function setACLManager(address newAclManager) external;
 
   /**
@@ -232,7 +232,7 @@ interface IPoolAddressesProvider {
   /**
    * @notice Updates the address of the price oracle sentinel.
    * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
-   **/
+   */
   function setPriceOracleSentinel(address newPriceOracleSentinel) external;
 
   /**
@@ -244,41 +244,41 @@ interface IPoolAddressesProvider {
   /**
    * @notice Updates the address of the data provider.
    * @param newDataProvider The address of the new DataProvider
-   **/
+   */
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/ARBITRUM/ORACLE/AaveOracle/@aave/core-v3/contracts/interfaces/IPriceOracleGetter.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/interfaces/IPriceOracleGetter.sol
 
 /**
  * @title IPriceOracleGetter
  * @author Aave
  * @notice Interface for the Aave price oracle.
- **/
+ */
 interface IPriceOracleGetter {
   /**
    * @notice Returns the base currency address
    * @dev Address 0x0 is reserved for USD as base currency.
    * @return Returns the base currency address.
-   **/
+   */
   function BASE_CURRENCY() external view returns (address);
 
   /**
    * @notice Returns the base currency unit
    * @dev 1 ether for ETH, 1e8 for USD.
    * @return Returns the base currency unit.
-   **/
+   */
   function BASE_CURRENCY_UNIT() external view returns (uint256);
 
   /**
    * @notice Returns the asset price in the base currency
    * @param asset The address of the asset
    * @return The price of the asset
-   **/
+   */
   function getAssetPrice(address asset) external view returns (uint256);
 }
 
-// downloads/ARBITRUM/ORACLE/AaveOracle/@aave/core-v3/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -333,13 +333,12 @@ library Errors {
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
@@ -347,7 +346,7 @@ library Errors {
   string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
   string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
   string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
-  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
+  string public constant USER_IN_ISOLATION_MODE_OR_LTV_ZERO = '62'; // 'User is in isolation mode or ltv is zero'
   string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
   string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
   string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
@@ -376,15 +375,24 @@ library Errors {
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
 
-// downloads/ARBITRUM/ORACLE/AaveOracle/@aave/core-v3/contracts/interfaces/IACLManager.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
  * @author Aave
  * @notice Defines the basic interface for the ACL Manager
- **/
+ */
 interface IACLManager {
   /**
    * @notice Returns the contract address of the PoolAddressesProvider
@@ -500,7 +508,7 @@ interface IACLManager {
   function addFlashBorrower(address borrower) external;
 
   /**
-   * @notice Removes an admin as FlashBorrower
+   * @notice Removes an address as FlashBorrower
    * @param borrower The address of the FlashBorrower to remove
    */
   function removeFlashBorrower(address borrower) external;
@@ -551,7 +559,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/ARBITRUM/ORACLE/AaveOracle/@aave/core-v3/contracts/interfaces/IAaveOracle.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/interfaces/IAaveOracle.sol
 
 /**
  * @title IAaveOracle
@@ -619,7 +627,7 @@ interface IAaveOracle is IPriceOracleGetter {
   function getFallbackOracle() external view returns (address);
 }
 
-// downloads/ARBITRUM/ORACLE/AaveOracle/@aave/core-v3/contracts/misc/AaveOracle.sol
+// downloads/ZKSYNC/ORACLE/AaveOracle/src/core/contracts/misc/AaveOracle.sol
 
 /**
  * @title AaveOracle
@@ -641,7 +649,7 @@ contract AaveOracle is IAaveOracle {
 
   /**
    * @dev Only asset listing or pool admin can call functions marked by this modifier.
-   **/
+   */
   modifier onlyAssetListingOrPoolAdmins() {
     _onlyAssetListingOrPoolAdmins();
     _;
```
