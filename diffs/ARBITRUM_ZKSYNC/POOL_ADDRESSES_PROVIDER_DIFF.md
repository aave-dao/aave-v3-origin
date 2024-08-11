```diff
diff --git a/./downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER.sol b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER.sol
index 9478e36..7b370c5 100644
--- a/./downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER.sol
+++ b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER.sol

-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol

 /**
  * @title Proxy
@@ -104,6 +263,14 @@ abstract contract Proxy {
     _fallback();
   }

+  /**
+   * @dev Fallback function that will run if call data is empty.
+   * IMPORTANT. receive() on implementation contracts will be unreachable
+   */
+  receive() external payable {
+    _fallback();
+  }
+
   /**
    * @return The Address of the implementation.
    */
@@ -158,13 +325,13 @@ abstract contract Proxy {
   }
 }

-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/interfaces/IPoolAddressesProvider.sol

 /**
  * @title IPoolAddressesProvider
  * @author Aave
  * @notice Defines the basic interface for a Pool Addresses Provider.
- **/
+ */
 interface IPoolAddressesProvider {
   /**
    * @dev Emitted when the market identifier is updated.
@@ -259,7 +426,7 @@ interface IPoolAddressesProvider {
   /**
    * @notice Returns the id of the Aave market to which this contract points to.
    * @return The market id
-   **/
+   */
   function getMarketId() external view returns (string memory);

   /**
@@ -301,27 +468,27 @@ interface IPoolAddressesProvider {
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
@@ -345,7 +512,7 @@ interface IPoolAddressesProvider {
   /**
    * @notice Updates the address of the ACL manager.
    * @param newAclManager The address of the new ACLManager
-   **/
+   */
   function setACLManager(address newAclManager) external;

   /**
@@ -369,7 +536,7 @@ interface IPoolAddressesProvider {
   /**
    * @notice Updates the address of the price oracle sentinel.
    * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
-   **/
+   */
   function setPriceOracleSentinel(address newPriceOracleSentinel) external;

   /**
@@ -381,11 +548,11 @@ interface IPoolAddressesProvider {
   /**
    * @notice Updates the address of the data provider.
    * @param newDataProvider The address of the new DataProvider
-   **/
+   */
   function setPoolDataProvider(address newDataProvider) external;
 }

-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol

 /**
  * @title BaseImmutableAdminUpgradeabilityProxy
@@ -558,10 +725,10 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {

   /**
    * @dev Constructor.
-   * @param admin The address of the admin
+   * @param admin_ The address of the admin
    */
-  constructor(address admin) {
-    _admin = admin;
+  constructor(address admin_) {
+    _admin = admin_;
   }

   modifier ifAdmin() {
@@ -624,7 +791,7 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }

-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/protocol/configuration/PoolAddressesProvider.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/configuration/PoolAddressesProvider.sol

 /**
  * @title PoolAddressesProvider
@@ -657,7 +824,7 @@ contract InitializableImmutableAdminUpgradeabilityProxy is
  * @notice Main registry of addresses part of or connected to the protocol, including permissioned roles
  * @dev Acts as factory of proxies and admin of those, so with right to change its implementations
  * @dev Owned by the Aave Governance
- **/
+ */
 contract PoolAddressesProvider is Ownable, IPoolAddressesProvider {
   // Identifier of the Aave Market
   string private _marketId;
@@ -809,7 +976,7 @@ contract PoolAddressesProvider is Ownable, IPoolAddressesProvider {
    *   calls the initialize() function via upgradeToAndCall() in the proxy
    * @param id The id of the proxy to be updated
    * @param newAddress The address of the new implementation
-   **/
+   */
   function _updateImpl(bytes32 id, address newAddress) internal {
     address proxyAddress = _addresses[id];
     InitializableImmutableAdminUpgradeabilityProxy proxy;
@@ -829,7 +996,7 @@ contract PoolAddressesProvider is Ownable, IPoolAddressesProvider {
   /**
    * @notice Updates the identifier of the Aave market.
    * @param newMarketId The new id of the market
-   **/
+   */
   function _setMarketId(string memory newMarketId) internal {
     string memory oldMarketId = _marketId;
     _marketId = newMarketId;
```
