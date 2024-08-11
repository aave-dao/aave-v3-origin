```diff
diff --git a/./downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER_REGISTRY.sol b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY.sol
index b396e1f..84a6931 100644
--- a/./downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER_REGISTRY.sol
+++ b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER_REGISTRY.sol

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
