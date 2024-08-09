```diff
diff --git a/./downloads/ARBITRUM/COLLECTOR_IMPL.sol b/./downloads/ZKSYNC/COLLECTOR_IMPL.sol
index 752e048..e453c1f 100644
--- a/./downloads/ARBITRUM/COLLECTOR_IMPL.sol
+++ b/./downloads/ZKSYNC/COLLECTOR_IMPL.sol
@@ -1,122 +1,9 @@
 // SPDX-License-Identifier: MIT
-pragma solidity >=0.6.0 ^0.8.0 ^0.8.1;
+pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/ARBITRUM/COLLECTOR_IMPL/Collector/src/libs/ReentrancyGuard.sol
+// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
 
-// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
-
-/**
- * @dev Contract module that helps prevent reentrant calls to a function.
- *
- * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
- * available, which can be applied to functions to make sure there are no nested
- * (reentrant) calls to them.
- *
- * Note that because there is a single `nonReentrant` guard, functions marked as
- * `nonReentrant` may not call one another. This can be worked around by making
- * those functions `private`, and then adding `external` `nonReentrant` entry
- * points to them.
- *
- * TIP: If you would like to learn more about reentrancy and alternative ways
- * to protect against it, check out our blog post
- * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
- */
-abstract contract ReentrancyGuard {
-  // Booleans are more expensive than uint256 or any type that takes up a full
-  // word because each write operation emits an extra SLOAD to first read the
-  // slot's contents, replace the bits taken up by the boolean, and then write
-  // back. This is the compiler's defense against contract upgrades and
-  // pointer aliasing, and it cannot be disabled.
-
-  // The values being non-zero value makes deployment a bit more expensive,
-  // but in exchange the refund on every call to nonReentrant will be lower in
-  // amount. Since refunds are capped to a percentage of the total
-  // transaction's gas, it is best to keep them low in cases like this one, to
-  // increase the likelihood of the full refund coming into effect.
-  uint256 private constant _NOT_ENTERED = 1;
-  uint256 private constant _ENTERED = 2;
-
-  uint256 private _status;
-
-  constructor() {
-    _status = _NOT_ENTERED;
-  }
-
-  /**
-   * @dev Prevents a contract from calling itself, directly or indirectly.
-   * Calling a `nonReentrant` function from another `nonReentrant`
-   * function is not supported. It is possible to prevent this from happening
-   * by making the `nonReentrant` function external, and making it call a
-   * `private` function that does the actual work.
-   */
-  modifier nonReentrant() {
-    // On the first call to nonReentrant, _notEntered will be true
-    require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');
-
-    // Any calls to nonReentrant after this point will fail
-    _status = _ENTERED;
-
-    _;
-
-    // By storing the original value once again, a refund is triggered (see
-    // https://eips.ethereum.org/EIPS/eip-2200)
-    _status = _NOT_ENTERED;
-  }
-
-  /**
-   * @dev As we use the guard with the proxy we need to init it with the empty value
-   */
-  function _initGuard() internal {
-    _status = _NOT_ENTERED;
-  }
-}
-
-// downloads/ARBITRUM/COLLECTOR_IMPL/Collector/src/libs/VersionedInitializable.sol
-
-/**
- * @title VersionedInitializable
- *
- * @dev Helper contract to support initializer functions. To use it, replace
- * the constructor with a function that has the `initializer` modifier.
- * WARNING: Unlike constructors, initializer functions must be manually
- * invoked. This applies both to deploying an Initializable contract, as well
- * as extending an Initializable contract via inheritance.
- * WARNING: When used with inheritance, manual care must be taken to not invoke
- * a parent initializer twice, or ensure that all initializers are idempotent,
- * because this is not dealt with automatically as with constructors.
- *
- * @author Aave, inspired by the OpenZeppelin Initializable contract
- */
-abstract contract VersionedInitializable {
-  /**
-   * @dev Indicates that the contract has been initialized.
-   */
-  uint256 internal lastInitializedRevision = 0;
-
-  /**
-   * @dev Modifier to use in the initializer function of a contract.
-   */
-  modifier initializer() {
-    uint256 revision = getRevision();
-    require(revision > lastInitializedRevision, 'Contract instance has already been initialized');
-
-    lastInitializedRevision = revision;
-
-    _;
-  }
-
-  /// @dev returns the revision number of the contract.
-  /// Needs to be defined in the inherited class as a constant.
-  function getRevision() internal pure virtual returns (uint256);
-
-  // Reserved storage space to allow for layout changes in the future.
-  uint256[50] private ______gap;
-}
-
-// lib/solidity-utils/src/contracts/oz-common/Address.sol
-
-// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
-// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a
+// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
 /**
  * @dev Collection of functions related to the address type
@@ -138,22 +25,17 @@ library Address {
    *  - an address where a contract will be created
    *  - an address where a contract lived, but was destroyed
    * ====
-   *
-   * [IMPORTANT]
-   * ====
-   * You shouldn't rely on `isContract` to protect against flash loan attacks!
-   *
-   * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
-   * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
-   * constructor.
-   * ====
    */
   function isContract(address account) internal view returns (bool) {
-    // This method relies on extcodesize/address.code.length, which returns 0
-    // for contracts in construction, since the code is only stored at the end
-    // of the constructor execution.
+    // This method relies on extcodesize, which returns 0 for contracts in
+    // construction, since the code is only stored at the end of the
+    // constructor execution.
 
-    return account.code.length > 0;
+    uint256 size;
+    assembly {
+      size := extcodesize(account)
+    }
+    return size > 0;
   }
 
   /**
@@ -198,7 +80,7 @@ library Address {
    * _Available since v3.1._
    */
   function functionCall(address target, bytes memory data) internal returns (bytes memory) {
-    return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
+    return functionCall(target, data, 'Address: low-level call failed');
   }
 
   /**
@@ -247,8 +129,10 @@ library Address {
     string memory errorMessage
   ) internal returns (bytes memory) {
     require(address(this).balance >= value, 'Address: insufficient balance for call');
+    require(isContract(target), 'Address: call to non-contract');
+
     (bool success, bytes memory returndata) = target.call{value: value}(data);
-    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
+    return verifyCallResult(success, returndata, errorMessage);
   }
 
   /**
@@ -275,8 +159,10 @@ library Address {
     bytes memory data,
     string memory errorMessage
   ) internal view returns (bytes memory) {
+    require(isContract(target), 'Address: static call to non-contract');
+
     (bool success, bytes memory returndata) = target.staticcall(data);
-    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
+    return verifyCallResult(success, returndata, errorMessage);
   }
 
   /**
@@ -300,37 +186,15 @@ library Address {
     bytes memory data,
     string memory errorMessage
   ) internal returns (bytes memory) {
+    require(isContract(target), 'Address: delegate call to non-contract');
+
     (bool success, bytes memory returndata) = target.delegatecall(data);
-    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
+    return verifyCallResult(success, returndata, errorMessage);
   }
 
   /**
-   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
-   * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
-   *
-   * _Available since v4.8._
-   */
-  function verifyCallResultFromTarget(
-    address target,
-    bool success,
-    bytes memory returndata,
-    string memory errorMessage
-  ) internal view returns (bytes memory) {
-    if (success) {
-      if (returndata.length == 0) {
-        // only check isContract if the call was successful and the return data is empty
-        // otherwise we already know that it was a contract
-        require(isContract(target), 'Address: call to non-contract');
-      }
-      return returndata;
-    } else {
-      _revert(returndata, errorMessage);
-    }
-  }
-
-  /**
-   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
-   * revert reason or using the provided one.
+   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
+   * revert reason using the provided one.
    *
    * _Available since v4.3._
    */
@@ -342,48 +206,27 @@ library Address {
     if (success) {
       return returndata;
     } else {
-      _revert(returndata, errorMessage);
-    }
-  }
+      // Look for revert reason and bubble it up if present
+      if (returndata.length > 0) {
+        // The easiest way to bubble the revert reason is using memory via assembly
 
-  function _revert(bytes memory returndata, string memory errorMessage) private pure {
-    // Look for revert reason and bubble it up if present
-    if (returndata.length > 0) {
-      // The easiest way to bubble the revert reason is using memory via assembly
-      /// @solidity memory-safe-assembly
-      assembly {
-        let returndata_size := mload(returndata)
-        revert(add(32, returndata), returndata_size)
+        assembly {
+          let returndata_size := mload(returndata)
+          revert(add(32, returndata), returndata_size)
+        }
+      } else {
+        revert(errorMessage);
       }
-    } else {
-      revert(errorMessage);
     }
   }
 }
 
-// lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20.sol
-
-// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
-// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/a035b235b4f2c9af4ba88edc4447f02e37f8d124
+// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
  */
 interface IERC20 {
-  /**
-   * @dev Emitted when `value` tokens are moved from one account (`from`) to
-   * another (`to`).
-   *
-   * Note that `value` may be zero.
-   */
-  event Transfer(address indexed from, address indexed to, uint256 value);
-
-  /**
-   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
-   * a call to {approve}. `value` is the new allowance.
-   */
-  event Approval(address indexed owner, address indexed spender, uint256 value);
-
   /**
    * @dev Returns the amount of tokens in existence.
    */
@@ -395,13 +238,13 @@ interface IERC20 {
   function balanceOf(address account) external view returns (uint256);
 
   /**
-   * @dev Moves `amount` tokens from the caller's account to `to`.
+   * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
-  function transfer(address to, uint256 amount) external returns (bool);
+  function transfer(address recipient, uint256 amount) external returns (bool);
 
   /**
    * @dev Returns the remaining number of tokens that `spender` will be
@@ -429,7 +272,7 @@ interface IERC20 {
   function approve(address spender, uint256 amount) external returns (bool);
 
   /**
-   * @dev Moves `amount` tokens from `from` to `to` using the
+   * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
@@ -437,71 +280,171 @@ interface IERC20 {
    *
    * Emits a {Transfer} event.
    */
-  function transferFrom(address from, address to, uint256 amount) external returns (bool);
-}
+  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
+
+  /**
+   * @dev Emitted when `value` tokens are moved from one account (`from`) to
+   * another (`to`).
+   *
+   * Note that `value` may be zero.
+   */
+  event Transfer(address indexed from, address indexed to, uint256 value);
 
-// lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20Permit.sol
+  /**
+   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
+   * a call to {approve}. `value` is the new allowance.
+   */
+  event Approval(address indexed owner, address indexed spender, uint256 value);
+}
 
-// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)
-// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/commit/00cbf5a236564c3b7aacdad1f378cae22d890ca6
+// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
 
 /**
- * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
- * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
- *
- * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
- * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
- * need to send a transaction, and thus is not required to hold Ether at all.
+ * @title VersionedInitializable
+ * @author Aave, inspired by the OpenZeppelin Initializable contract
+ * @notice Helper contract to implement initializer functions. To use it, replace
+ * the constructor with a function that has the `initializer` modifier.
+ * @dev WARNING: Unlike constructors, initializer functions must be manually
+ * invoked. This applies both to deploying an Initializable contract, as well
+ * as extending an Initializable contract via inheritance.
+ * WARNING: When used with inheritance, manual care must be taken to not invoke
+ * a parent initializer twice, or ensure that all initializers are idempotent,
+ * because this is not dealt with automatically as with constructors.
  */
-interface IERC20Permit {
+abstract contract VersionedInitializable {
   /**
-   * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
-   * given ``owner``'s signed approval.
-   *
-   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
-   * ordering also apply here.
-   *
-   * Emits an {Approval} event.
-   *
-   * Requirements:
-   *
-   * - `spender` cannot be the zero address.
-   * - `deadline` must be a timestamp in the future.
-   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
-   * over the EIP712-formatted function arguments.
-   * - the signature must use ``owner``'s current nonce (see {nonces}).
-   *
-   * For more information on the signature format, see the
-   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
-   * section].
+   * @dev Indicates that the contract has been initialized.
    */
-  function permit(
-    address owner,
-    address spender,
-    uint256 value,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) external;
+  uint256 private lastInitializedRevision = 0;
 
   /**
-   * @dev Returns the current nonce for `owner`. This value must be
-   * included whenever a signature is generated for {permit}.
-   *
-   * Every successful call to {permit} increases ``owner``'s nonce by one. This
-   * prevents a signature from being used multiple times.
+   * @dev Indicates that the contract is in the process of being initialized.
+   */
+  bool private initializing;
+
+  /**
+   * @dev Modifier to use in the initializer function of a contract.
+   */
+  modifier initializer() {
+    uint256 revision = getRevision();
+    require(
+      initializing || isConstructor() || revision > lastInitializedRevision,
+      'Contract instance has already been initialized'
+    );
+
+    bool isTopLevelCall = !initializing;
+    if (isTopLevelCall) {
+      initializing = true;
+      lastInitializedRevision = revision;
+    }
+
+    _;
+
+    if (isTopLevelCall) {
+      initializing = false;
+    }
+  }
+
+  /**
+   * @notice Returns the revision number of the contract
+   * @dev Needs to be defined in the inherited class as a constant.
+   * @return The revision number
+   */
+  function getRevision() internal pure virtual returns (uint256);
+
+  /**
+   * @notice Returns true if and only if the function is running in the constructor
+   * @return True if the function is running in the constructor
    */
-  function nonces(address owner) external view returns (uint256);
+  function isConstructor() private view returns (bool) {
+    // extcodesize checks the size of the code stored in an address, and
+    // address returns the current address. Since the code is still not
+    // deployed when running a constructor, any checks on its code size will
+    // yield zero, making it an effective way to detect if a contract is
+    // under construction or not.
+    uint256 cs;
+    //solium-disable-next-line
+    assembly {
+      cs := extcodesize(address())
+    }
+    return cs == 0;
+  }
+
+  // Reserved storage space to allow for layout changes in the future.
+  uint256[50] private ______gap;
+}
+
+// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/periphery/contracts/dependencies/openzeppelin/ReentrancyGuard.sol
+
+// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
+
+/**
+ * @dev Contract module that helps prevent reentrant calls to a function.
+ *
+ * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
+ * available, which can be applied to functions to make sure there are no nested
+ * (reentrant) calls to them.
+ *
+ * Note that because there is a single `nonReentrant` guard, functions marked as
+ * `nonReentrant` may not call one another. This can be worked around by making
+ * those functions `private`, and then adding `external` `nonReentrant` entry
+ * points to them.
+ *
+ * TIP: If you would like to learn more about reentrancy and alternative ways
+ * to protect against it, check out our blog post
+ * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
+ */
+abstract contract ReentrancyGuard {
+  // Booleans are more expensive than uint256 or any type that takes up a full
+  // word because each write operation emits an extra SLOAD to first read the
+  // slot's contents, replace the bits taken up by the boolean, and then write
+  // back. This is the compiler's defense against contract upgrades and
+  // pointer aliasing, and it cannot be disabled.
+
+  // The values being non-zero value makes deployment a bit more expensive,
+  // but in exchange the refund on every call to nonReentrant will be lower in
+  // amount. Since refunds are capped to a percentage of the total
+  // transaction's gas, it is best to keep them low in cases like this one, to
+  // increase the likelihood of the full refund coming into effect.
+  uint256 private constant _NOT_ENTERED = 1;
+  uint256 private constant _ENTERED = 2;
+
+  uint256 private _status;
+
+  constructor() {
+    _status = _NOT_ENTERED;
+  }
+
+  /**
+   * @dev Prevents a contract from calling itself, directly or indirectly.
+   * Calling a `nonReentrant` function from another `nonReentrant`
+   * function is not supported. It is possible to prevent this from happening
+   * by making the `nonReentrant` function external, and making it call a
+   * `private` function that does the actual work.
+   */
+  modifier nonReentrant() {
+    // On the first call to nonReentrant, _notEntered will be true
+    require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');
+
+    // Any calls to nonReentrant after this point will fail
+    _status = _ENTERED;
+
+    _;
+
+    // By storing the original value once again, a refund is triggered (see
+    // https://eips.ethereum.org/EIPS/eip-2200)
+    _status = _NOT_ENTERED;
+  }
 
   /**
-   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
+   * @dev As we use the guard with the proxy we need to init it with the empty value
    */
-  // solhint-disable-next-line func-name-mixedcase
-  function DOMAIN_SEPARATOR() external view returns (bytes32);
+  function _initGuard() internal {
+    _status = _NOT_ENTERED;
+  }
 }
 
-// downloads/ARBITRUM/COLLECTOR_IMPL/Collector/src/interfaces/ICollector.sol
+// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/periphery/contracts/treasury/ICollector.sol
 
 interface ICollector {
   struct Stream {
@@ -673,10 +616,9 @@ interface ICollector {
   function getNextStreamId() external view returns (uint256);
 }
 
-// lib/solidity-utils/src/contracts/oz-common/SafeERC20.sol
+// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/core/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol
 
-// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)
-// Modified From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/00cbf5a236564c3b7aacdad1f378cae22d890ca6
+// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
 
 /**
  * @title SafeERC20
@@ -690,96 +632,52 @@ interface ICollector {
 library SafeERC20 {
   using Address for address;
 
-  /**
-   * @dev An operation with an ERC20 token failed.
-   */
-  error SafeERC20FailedOperation(address token);
-
-  /**
-   * @dev Indicates a failed `decreaseAllowance` request.
-   */
-  error SafeERC20FailedDecreaseAllowance(
-    address spender,
-    uint256 currentAllowance,
-    uint256 requestedDecrease
-  );
-
-  /**
-   * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
-   * non-reverting calls are assumed to be successful.
-   */
   function safeTransfer(IERC20 token, address to, uint256 value) internal {
-    _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
+    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
   }
 
-  /**
-   * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
-   * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
-   */
   function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
-    _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
+    _callOptionalReturn(
+      token,
+      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
+    );
   }
 
   /**
-   * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
-   * non-reverting calls are assumed to be successful.
+   * @dev Deprecated. This function has issues similar to the ones found in
+   * {IERC20-approve}, and its usage is discouraged.
+   *
+   * Whenever possible, use {safeIncreaseAllowance} and
+   * {safeDecreaseAllowance} instead.
    */
+  function safeApprove(IERC20 token, address spender, uint256 value) internal {
+    // safeApprove should only be called when setting an initial allowance,
+    // or when resetting it to zero. To increase and decrease it, use
+    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
+    require(
+      (value == 0) || (token.allowance(address(this), spender) == 0),
+      'SafeERC20: approve from non-zero to non-zero allowance'
+    );
+    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
+  }
+
   function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
-    uint256 oldAllowance = token.allowance(address(this), spender);
-    forceApprove(token, spender, oldAllowance + value);
+    uint256 newAllowance = token.allowance(address(this), spender) + value;
+    _callOptionalReturn(
+      token,
+      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
+    );
   }
 
-  /**
-   * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no value,
-   * non-reverting calls are assumed to be successful.
-   */
-  function safeDecreaseAllowance(
-    IERC20 token,
-    address spender,
-    uint256 requestedDecrease
-  ) internal {
+  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
     unchecked {
-      uint256 currentAllowance = token.allowance(address(this), spender);
-      if (currentAllowance < requestedDecrease) {
-        revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
-      }
-      forceApprove(token, spender, currentAllowance - requestedDecrease);
-    }
-  }
-
-  /**
-   * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
-   * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
-   * to be set to zero before setting it to a non-zero value, such as USDT.
-   */
-  function forceApprove(IERC20 token, address spender, uint256 value) internal {
-    bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));
-
-    if (!_callOptionalReturnBool(token, approvalCall)) {
-      _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
-      _callOptionalReturn(token, approvalCall);
-    }
-  }
-
-  /**
-   * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
-   * Revert on invalid signature.
-   */
-  function safePermit(
-    IERC20Permit token,
-    address owner,
-    address spender,
-    uint256 value,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) internal {
-    uint256 nonceBefore = token.nonces(owner);
-    token.permit(owner, spender, value, deadline, v, r, s);
-    uint256 nonceAfter = token.nonces(owner);
-    if (nonceAfter != nonceBefore + 1) {
-      revert SafeERC20FailedOperation(address(token));
+      uint256 oldAllowance = token.allowance(address(this), spender);
+      require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
+      uint256 newAllowance = oldAllowance - value;
+      _callOptionalReturn(
+        token,
+        abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
+      );
     }
   }
 
@@ -791,37 +689,18 @@ library SafeERC20 {
    */
   function _callOptionalReturn(IERC20 token, bytes memory data) private {
     // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
-    // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
+    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
     // the target address contains contract code and also asserts for success in the low-level call.
 
-    bytes memory returndata = address(token).functionCall(data);
-    if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
-      revert SafeERC20FailedOperation(address(token));
+    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
+    if (returndata.length > 0) {
+      // Return data is optional
+      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
     }
   }
-
-  /**
-   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
-   * on the return value: the return value is optional (but if data is returned, it must not be false).
-   * @param token The token targeted by the call.
-   * @param data The call data (encoded using abi.encode or one of its variants).
-   *
-   * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
-   */
-  function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
-    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
-    // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
-    // and not revert is the subcall reverts.
-
-    (bool success, bytes memory returndata) = address(token).call(data);
-    return
-      success &&
-      (returndata.length == 0 || abi.decode(returndata, (bool))) &&
-      address(token).code.length > 0;
-  }
 }
 
-// downloads/ARBITRUM/COLLECTOR_IMPL/Collector/src/contracts/Collector.sol
+// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/periphery/contracts/treasury/Collector.sol
 
 /**
  * @title Collector
@@ -903,8 +782,6 @@ contract Collector is VersionedInitializable, ICollector, ReentrancyGuard {
       _nextStreamId = nextStreamId;
     }
 
-    // can be removed after first deployment
-    _initGuard();
     _setFundsAdmin(fundsAdmin);
   }
 
@@ -1021,9 +898,6 @@ contract Collector is VersionedInitializable, ICollector, ReentrancyGuard {
     }
   }
 
-  /// @dev needed in order to receive ETH from the Aave v1 ecosystem reserve
-  receive() external payable {}
-
   /// @inheritdoc ICollector
   function setFundsAdmin(address admin) external onlyFundsAdmin {
     _setFundsAdmin(admin);
```
