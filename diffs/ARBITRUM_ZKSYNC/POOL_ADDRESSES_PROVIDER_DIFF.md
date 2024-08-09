```diff
diff --git a/./downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER.sol b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER.sol
index 9478e36..7b370c5 100644
--- a/./downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER.sol
+++ b/./downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER.sol
@@ -1,7 +1,9 @@
 // SPDX-License-Identifier: BUSL-1.1
-pragma solidity =0.8.10;
+pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
+
+// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
 /**
  * @dev Collection of functions related to the address type
@@ -25,16 +27,15 @@ library Address {
    * ====
    */
   function isContract(address account) internal view returns (bool) {
-    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
-    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
-    // for accounts without code, i.e. `keccak256('')`
-    bytes32 codehash;
-    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
-    // solhint-disable-next-line no-inline-assembly
+    // This method relies on extcodesize, which returns 0 for contracts in
+    // construction, since the code is only stored at the end of the
+    // constructor execution.
+
+    uint256 size;
     assembly {
-      codehash := extcodehash(account)
+      size := extcodesize(account)
     }
-    return (codehash != accountHash && codehash != 0x0);
+    return size > 0;
   }
 
   /**
@@ -56,13 +57,171 @@ library Address {
   function sendValue(address payable recipient, uint256 amount) internal {
     require(address(this).balance >= amount, 'Address: insufficient balance');
 
-    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
     (bool success, ) = recipient.call{value: amount}('');
     require(success, 'Address: unable to send value, recipient may have reverted');
   }
+
+  /**
+   * @dev Performs a Solidity function call using a low level `call`. A
+   * plain `call` is an unsafe replacement for a function call: use this
+   * function instead.
+   *
+   * If `target` reverts with a revert reason, it is bubbled up by this
+   * function (like regular Solidity function calls).
+   *
+   * Returns the raw returned data. To convert to the expected return value,
+   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
+   *
+   * Requirements:
+   *
+   * - `target` must be a contract.
+   * - calling `target` with `data` must not revert.
+   *
+   * _Available since v3.1._
+   */
+  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
+    return functionCall(target, data, 'Address: low-level call failed');
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
+   * `errorMessage` as a fallback revert reason when `target` reverts.
+   *
+   * _Available since v3.1._
+   */
+  function functionCall(
+    address target,
+    bytes memory data,
+    string memory errorMessage
+  ) internal returns (bytes memory) {
+    return functionCallWithValue(target, data, 0, errorMessage);
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
+   * but also transferring `value` wei to `target`.
+   *
+   * Requirements:
+   *
+   * - the calling contract must have an ETH balance of at least `value`.
+   * - the called Solidity function must be `payable`.
+   *
+   * _Available since v3.1._
+   */
+  function functionCallWithValue(
+    address target,
+    bytes memory data,
+    uint256 value
+  ) internal returns (bytes memory) {
+    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
+   * with `errorMessage` as a fallback revert reason when `target` reverts.
+   *
+   * _Available since v3.1._
+   */
+  function functionCallWithValue(
+    address target,
+    bytes memory data,
+    uint256 value,
+    string memory errorMessage
+  ) internal returns (bytes memory) {
+    require(address(this).balance >= value, 'Address: insufficient balance for call');
+    require(isContract(target), 'Address: call to non-contract');
+
+    (bool success, bytes memory returndata) = target.call{value: value}(data);
+    return verifyCallResult(success, returndata, errorMessage);
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
+   * but performing a static call.
+   *
+   * _Available since v3.3._
+   */
+  function functionStaticCall(
+    address target,
+    bytes memory data
+  ) internal view returns (bytes memory) {
+    return functionStaticCall(target, data, 'Address: low-level static call failed');
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
+   * but performing a static call.
+   *
+   * _Available since v3.3._
+   */
+  function functionStaticCall(
+    address target,
+    bytes memory data,
+    string memory errorMessage
+  ) internal view returns (bytes memory) {
+    require(isContract(target), 'Address: static call to non-contract');
+
+    (bool success, bytes memory returndata) = target.staticcall(data);
+    return verifyCallResult(success, returndata, errorMessage);
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
+   * but performing a delegate call.
+   *
+   * _Available since v3.4._
+   */
+  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
+    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
+  }
+
+  /**
+   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
+   * but performing a delegate call.
+   *
+   * _Available since v3.4._
+   */
+  function functionDelegateCall(
+    address target,
+    bytes memory data,
+    string memory errorMessage
+  ) internal returns (bytes memory) {
+    require(isContract(target), 'Address: delegate call to non-contract');
+
+    (bool success, bytes memory returndata) = target.delegatecall(data);
+    return verifyCallResult(success, returndata, errorMessage);
+  }
+
+  /**
+   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
+   * revert reason using the provided one.
+   *
+   * _Available since v4.3._
+   */
+  function verifyCallResult(
+    bool success,
+    bytes memory returndata,
+    string memory errorMessage
+  ) internal pure returns (bytes memory) {
+    if (success) {
+      return returndata;
+    } else {
+      // Look for revert reason and bubble it up if present
+      if (returndata.length > 0) {
+        // The easiest way to bubble the revert reason is using memory via assembly
+
+        assembly {
+          let returndata_size := mload(returndata)
+          revert(add(32, returndata), returndata_size)
+        }
+      } else {
+        revert(errorMessage);
+      }
+    }
+  }
 }
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -85,7 +244,7 @@ abstract contract Context {
   }
 }
 
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
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
 
 /**
  * @dev Contract module which provides a basic access control mechanism, where
@@ -451,7 +618,7 @@ contract Ownable is Context {
   }
 }
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
 
 /**
  * @title BaseUpgradeabilityProxy
@@ -514,7 +681,7 @@ contract BaseUpgradeabilityProxy is Proxy {
   }
 }
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
 
 /**
  * @title InitializableUpgradeabilityProxy
@@ -541,7 +708,7 @@ contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
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
 
-// downloads/ARBITRUM/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/@aave/core-v3/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_ADDRESSES_PROVIDER/PoolAddressesProvider/src/core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title InitializableAdminUpgradeabilityProxy
@@ -649,7 +816,7 @@ contract InitializableImmutableAdminUpgradeabilityProxy is
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
