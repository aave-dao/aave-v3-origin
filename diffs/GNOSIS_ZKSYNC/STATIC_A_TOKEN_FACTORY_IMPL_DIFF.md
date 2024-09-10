```diff
diff --git a/./downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL.sol b/./downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL.sol
index 112d529..64b19b2 100644
--- a/./downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL.sol
+++ b/./downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL.sol
@@ -1,103 +1,7 @@
-// SPDX-License-Identifier: MIT
-pragma solidity >=0.6.0 >=0.8.0 ^0.8.0 ^0.8.1 ^0.8.10 ^0.8.2 ^0.8.20;
+// SPDX-License-Identifier: BUSL-1.1
+pragma solidity >=0.8.0 ^0.8.0 ^0.8.1 ^0.8.10 ^0.8.2;
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/dependencies/chainlink/AggregatorInterface.sol
-
-// Chainlink Contracts v0.8
-
-interface AggregatorInterface {
-  function latestAnswer() external view returns (int256);
-
-  function latestTimestamp() external view returns (uint256);
-
-  function latestRound() external view returns (uint256);
-
-  function getAnswer(uint256 roundId) external view returns (int256);
-
-  function getTimestamp(uint256 roundId) external view returns (uint256);
-
-  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
-
-  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
-
-/**
- * @dev Interface of the ERC20 standard as defined in the EIP.
- */
-interface IERC20 {
-  /**
-   * @dev Returns the amount of tokens in existence.
-   */
-  function totalSupply() external view returns (uint256);
-
-  /**
-   * @dev Returns the amount of tokens owned by `account`.
-   */
-  function balanceOf(address account) external view returns (uint256);
-
-  /**
-   * @dev Moves `amount` tokens from the caller's account to `recipient`.
-   *
-   * Returns a boolean value indicating whether the operation succeeded.
-   *
-   * Emits a {Transfer} event.
-   */
-  function transfer(address recipient, uint256 amount) external returns (bool);
-
-  /**
-   * @dev Returns the remaining number of tokens that `spender` will be
-   * allowed to spend on behalf of `owner` through {transferFrom}. This is
-   * zero by default.
-   *
-   * This value changes when {approve} or {transferFrom} are called.
-   */
-  function allowance(address owner, address spender) external view returns (uint256);
-
-  /**
-   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
-   *
-   * Returns a boolean value indicating whether the operation succeeded.
-   *
-   * IMPORTANT: Beware that changing an allowance with this method brings the risk
-   * that someone may use both the old and the new allowance by unfortunate
-   * transaction ordering. One possible solution to mitigate this race
-   * condition is to first reduce the spender's allowance to 0 and set the
-   * desired value afterwards:
-   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
-   *
-   * Emits an {Approval} event.
-   */
-  function approve(address spender, uint256 amount) external returns (bool);
-
-  /**
-   * @dev Moves `amount` tokens from `sender` to `recipient` using the
-   * allowance mechanism. `amount` is then deducted from the caller's
-   * allowance.
-   *
-   * Returns a boolean value indicating whether the operation succeeded.
-   *
-   * Emits a {Transfer} event.
-   */
-  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
-
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
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/core/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -116,7 +20,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -343,109 +247,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IPriceOracleGetter.sol
-
-/**
- * @title IPriceOracleGetter
- * @author Aave
- * @notice Interface for the Aave price oracle.
- */
-interface IPriceOracleGetter {
-  /**
-   * @notice Returns the base currency address
-   * @dev Address 0x0 is reserved for USD as base currency.
-   * @return Returns the base currency address.
-   */
-  function BASE_CURRENCY() external view returns (address);
-
-  /**
-   * @notice Returns the base currency unit
-   * @dev 1 ether for ETH, 1e8 for USD.
-   * @return Returns the base currency unit.
-   */
-  function BASE_CURRENCY_UNIT() external view returns (uint256);
-
-  /**
-   * @notice Returns the asset price in the base currency
-   * @param asset The address of the asset
-   * @return The price of the asset
-   */
-  function getAssetPrice(address asset) external view returns (uint256);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IScaledBalanceToken.sol
-
-/**
- * @title IScaledBalanceToken
- * @author Aave
- * @notice Defines the basic interface for a scaled-balance token.
- */
-interface IScaledBalanceToken {
-  /**
-   * @dev Emitted after the mint action
-   * @param caller The address performing the mint
-   * @param onBehalfOf The address of the user that will receive the minted tokens
-   * @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
-   * @param balanceIncrease The increase in scaled-up balance since the last action of 'onBehalfOf'
-   * @param index The next liquidity index of the reserve
-   */
-  event Mint(
-    address indexed caller,
-    address indexed onBehalfOf,
-    uint256 value,
-    uint256 balanceIncrease,
-    uint256 index
-  );
-
-  /**
-   * @dev Emitted after the burn action
-   * @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
-   * @param from The address from which the tokens will be burned
-   * @param target The address that will receive the underlying, if any
-   * @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
-   * @param balanceIncrease The increase in scaled-up balance since the last action of 'from'
-   * @param index The next liquidity index of the reserve
-   */
-  event Burn(
-    address indexed from,
-    address indexed target,
-    uint256 value,
-    uint256 balanceIncrease,
-    uint256 index
-  );
-
-  /**
-   * @notice Returns the scaled balance of the user.
-   * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
-   * at the moment of the update
-   * @param user The user whose balance is calculated
-   * @return The scaled balance of the user
-   */
-  function scaledBalanceOf(address user) external view returns (uint256);
-
-  /**
-   * @notice Returns the scaled balance of the user and the scaled total supply.
-   * @param user The address of the user
-   * @return The scaled balance of the user
-   * @return The scaled total supply
-   */
-  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);
-
-  /**
-   * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
-   * @return The scaled total supply
-   */
-  function scaledTotalSupply() external view returns (uint256);
-
-  /**
-   * @notice Returns last index interest was accrued to the user's balance
-   * @param user The address of the user
-   * @return The last index interest was accrued to the user's balance, expressed in ray
-   */
-  function getPreviousIndex(address user) external view returns (uint256);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -543,9 +345,17 @@ library Errors {
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
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/core/contracts/protocol/libraries/math/WadRayMath.sol
 
 /**
  * @title WadRayMath library
@@ -671,50 +481,46 @@ library WadRayMath {
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
-
-library ConfiguratorInputTypes {
-  struct InitReserveInput {
-    address aTokenImpl;
-    address stableDebtTokenImpl;
-    address variableDebtTokenImpl;
-    uint8 underlyingAssetDecimals;
-    address interestRateStrategyAddress;
-    address underlyingAsset;
-    address treasury;
-    address incentivesController;
-    string aTokenName;
-    string aTokenSymbol;
-    string variableDebtTokenName;
-    string variableDebtTokenSymbol;
-    string stableDebtTokenName;
-    string stableDebtTokenSymbol;
-    bytes params;
-  }
-
-  struct UpdateATokenInput {
-    address asset;
-    address treasury;
-    address incentivesController;
-    string name;
-    string symbol;
-    address implementation;
-    bytes params;
-  }
-
-  struct UpdateDebtTokenInput {
-    address asset;
-    address incentivesController;
-    string name;
-    string symbol;
-    address implementation;
-    bytes params;
-  }
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/core/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
+  /**
+   * This exists specifically to maintain the `getReserveData()` interface, since the new, internal
+   * `ReserveData` struct includes the reserve's `virtualUnderlyingBalance`.
+   */
+  struct ReserveDataLegacy {
+    //stores the reserve configuration
+    ReserveConfigurationMap configuration;
+    //the liquidity index. Expressed in ray
+    uint128 liquidityIndex;
+    //the current supply rate. Expressed in ray
+    uint128 currentLiquidityRate;
+    //variable borrow index. Expressed in ray
+    uint128 variableBorrowIndex;
+    //the current variable borrow rate. Expressed in ray
+    uint128 currentVariableBorrowRate;
+    //the current stable borrow rate. Expressed in ray
+    uint128 currentStableBorrowRate;
+    //timestamp of last update
+    uint40 lastUpdateTimestamp;
+    //the id of the reserve. Represents the position in the list of the active reserves
+    uint16 id;
+    //aToken address
+    address aTokenAddress;
+    //stableDebtToken address
+    address stableDebtTokenAddress;
+    //variableDebtToken address
+    address variableDebtTokenAddress;
+    //address of the interest rate strategy
+    address interestRateStrategyAddress;
+    //the current treasury balance, scaled
+    uint128 accruedToTreasury;
+    //the outstanding unbacked aTokens minted through the bridging feature
+    uint128 unbacked;
+    //the outstanding debt borrowed against this asset in isolation mode
+    uint128 isolationModeTotalDebt;
+  }
+
   struct ReserveData {
     //stores the reserve configuration
     ReserveConfigurationMap configuration;
@@ -732,6 +538,8 @@ library DataTypes {
     uint40 lastUpdateTimestamp;
     //the id of the reserve. Represents the position in the list of the active reserves
     uint16 id;
+    //timestamp until when liquidations are not allowed on the reserve, if set to past liquidations will be allowed
+    uint40 liquidationGracePeriodUntil;
     //aToken address
     address aTokenAddress;
     //stableDebtToken address
@@ -746,6 +554,8 @@ library DataTypes {
     uint128 unbacked;
     //the outstanding debt borrowed against this asset in isolation mode
     uint128 isolationModeTotalDebt;
+    //the amount of underlying accounted for by the protocol
+    uint128 virtualUnderlyingBalance;
   }
 
   struct ReserveConfigurationMap {
@@ -762,13 +572,14 @@ library DataTypes {
     //bit 62: siloed borrowing enabled
     //bit 63: flashloaning enabled
     //bit 64-79: reserve factor
-    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
-    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
-    //bit 152-167 liquidation protocol fee
-    //bit 168-175 eMode category
-    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
-    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
-    //bit 252-255 unused
+    //bit 80-115: borrow cap in whole tokens, borrowCap == 0 => no cap
+    //bit 116-151: supply cap in whole tokens, supplyCap == 0 => no cap
+    //bit 152-167: liquidation protocol fee
+    //bit 168-175: eMode category
+    //bit 176-211: unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
+    //bit 212-251: debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
+    //bit 252: virtual accounting is enabled for the reserve
+    //bit 253-255 unused
 
     uint256 data;
   }
@@ -903,6 +714,7 @@ library DataTypes {
     uint256 maxStableRateBorrowSizePercent;
     uint256 reservesCount;
     address addressesProvider;
+    address pool;
     uint8 userEModeCategory;
     bool isAuthorizedFlashBorrower;
   }
@@ -967,7 +779,8 @@ library DataTypes {
     uint256 averageStableBorrowRate;
     uint256 reserveFactor;
     address reserve;
-    address aToken;
+    bool usingVirtualBalance;
+    uint256 virtualUnderlyingBalance;
   }
 
   struct InitReserveParams {
@@ -981,7 +794,759 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/Address.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/dependencies/openzeppelin/ECDSA.sol
+
+// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)
+
+/**
+ * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
+ *
+ * These functions can be used to verify that a message was signed by the holder
+ * of the private keys of a given address.
+ */
+library ECDSA {
+  enum RecoverError {
+    NoError,
+    InvalidSignature,
+    InvalidSignatureLength,
+    InvalidSignatureS
+  }
+
+  /**
+   * @dev The signature derives the `address(0)`.
+   */
+  error ECDSAInvalidSignature();
+
+  /**
+   * @dev The signature has an invalid length.
+   */
+  error ECDSAInvalidSignatureLength(uint256 length);
+
+  /**
+   * @dev The signature has an S value that is in the upper half order.
+   */
+  error ECDSAInvalidSignatureS(bytes32 s);
+
+  /**
+   * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
+   * return address(0) without also returning an error description. Errors are documented using an enum (error type)
+   * and a bytes32 providing additional information about the error.
+   *
+   * If no error is returned, then the address can be used for verification purposes.
+   *
+   * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
+   * this function rejects them by requiring the `s` value to be in the lower
+   * half order, and the `v` value to be either 27 or 28.
+   *
+   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
+   * verification to be secure: it is possible to craft signatures that
+   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
+   * this is by receiving a hash of the original message (which may otherwise
+   * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
+   *
+   * Documentation for signature generation:
+   * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
+   * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
+   */
+  function tryRecover(
+    bytes32 hash,
+    bytes memory signature
+  ) internal pure returns (address, RecoverError, bytes32) {
+    if (signature.length == 65) {
+      bytes32 r;
+      bytes32 s;
+      uint8 v;
+      // ecrecover takes the signature parameters, and the only way to get them
+      // currently is to use assembly.
+      /// @solidity memory-safe-assembly
+      assembly {
+        r := mload(add(signature, 0x20))
+        s := mload(add(signature, 0x40))
+        v := byte(0, mload(add(signature, 0x60)))
+      }
+      return tryRecover(hash, v, r, s);
+    } else {
+      return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
+    }
+  }
+
+  /**
+   * @dev Returns the address that signed a hashed message (`hash`) with
+   * `signature`. This address can then be used for verification purposes.
+   *
+   * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
+   * this function rejects them by requiring the `s` value to be in the lower
+   * half order, and the `v` value to be either 27 or 28.
+   *
+   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
+   * verification to be secure: it is possible to craft signatures that
+   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
+   * this is by receiving a hash of the original message (which may otherwise
+   * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
+   */
+  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
+    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
+    _throwError(error, errorArg);
+    return recovered;
+  }
+
+  /**
+   * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
+   *
+   * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
+   */
+  function tryRecover(
+    bytes32 hash,
+    bytes32 r,
+    bytes32 vs
+  ) internal pure returns (address, RecoverError, bytes32) {
+    unchecked {
+      bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
+      // We do not check for an overflow here since the shift operation results in 0 or 1.
+      uint8 v = uint8((uint256(vs) >> 255) + 27);
+      return tryRecover(hash, v, r, s);
+    }
+  }
+
+  /**
+   * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
+   */
+  function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
+    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
+    _throwError(error, errorArg);
+    return recovered;
+  }
+
+  /**
+   * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
+   * `r` and `s` signature fields separately.
+   */
+  function tryRecover(
+    bytes32 hash,
+    uint8 v,
+    bytes32 r,
+    bytes32 s
+  ) internal pure returns (address, RecoverError, bytes32) {
+    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
+    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
+    // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
+    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
+    //
+    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
+    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
+    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
+    // these malleable signatures as well.
+    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
+      return (address(0), RecoverError.InvalidSignatureS, s);
+    }
+
+    // If the signature is valid (and not malleable), return the signer address
+    address signer = ecrecover(hash, v, r, s);
+    if (signer == address(0)) {
+      return (address(0), RecoverError.InvalidSignature, bytes32(0));
+    }
+
+    return (signer, RecoverError.NoError, bytes32(0));
+  }
+
+  /**
+   * @dev Overload of {ECDSA-recover} that receives the `v`,
+   * `r` and `s` signature fields separately.
+   */
+  function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
+    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
+    _throwError(error, errorArg);
+    return recovered;
+  }
+
+  /**
+   * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
+   */
+  function _throwError(RecoverError error, bytes32 errorArg) private pure {
+    if (error == RecoverError.NoError) {
+      return; // no error: do nothing
+    } else if (error == RecoverError.InvalidSignature) {
+      revert ECDSAInvalidSignature();
+    } else if (error == RecoverError.InvalidSignatureLength) {
+      revert ECDSAInvalidSignatureLength(uint256(errorArg));
+    } else if (error == RecoverError.InvalidSignatureS) {
+      revert ECDSAInvalidSignatureS(errorArg);
+    }
+  }
+}
+
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/libraries/RayMathExplicitRounding.sol
+
+enum Rounding {
+  UP,
+  DOWN
+}
+
+/**
+ * Simplified version of RayMath that instead of half-up rounding does explicit rounding in a specified direction.
+ * This is needed to have a 4626 complient implementation, that always predictable rounds in favor of the vault / static a token.
+ */
+library RayMathExplicitRounding {
+  uint256 internal constant RAY = 1e27;
+  uint256 internal constant WAD_RAY_RATIO = 1e9;
+
+  function rayMulRoundDown(uint256 a, uint256 b) internal pure returns (uint256) {
+    if (a == 0 || b == 0) {
+      return 0;
+    }
+    return (a * b) / RAY;
+  }
+
+  function rayMulRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
+    if (a == 0 || b == 0) {
+      return 0;
+    }
+    return ((a * b) + RAY - 1) / RAY;
+  }
+
+  function rayDivRoundDown(uint256 a, uint256 b) internal pure returns (uint256) {
+    return (a * RAY) / b;
+  }
+
+  function rayDivRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
+    return ((a * RAY) + b - 1) / b;
+  }
+
+  function rayToWadRoundDown(uint256 a) internal pure returns (uint256) {
+    return a / WAD_RAY_RATIO;
+  }
+}
+
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
+
+interface IEACAggregatorProxy {
+  function decimals() external view returns (uint8);
+
+  function latestAnswer() external view returns (int256);
+
+  function latestTimestamp() external view returns (uint256);
+
+  function latestRound() external view returns (uint256);
+
+  function getAnswer(uint256 roundId) external view returns (int256);
+
+  function getTimestamp(uint256 roundId) external view returns (uint256);
+
+  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
+  event NewRound(uint256 indexed roundId, address indexed startedBy);
+}
+
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
+
+/**
+ * @title IRewardsDistributor
+ * @author Aave
+ * @notice Defines the basic interface for a Rewards Distributor.
+ */
+interface IRewardsDistributor {
+  /**
+   * @dev Emitted when the configuration of the rewards of an asset is updated.
+   * @param asset The address of the incentivized asset
+   * @param reward The address of the reward token
+   * @param oldEmission The old emissions per second value of the reward distribution
+   * @param newEmission The new emissions per second value of the reward distribution
+   * @param oldDistributionEnd The old end timestamp of the reward distribution
+   * @param newDistributionEnd The new end timestamp of the reward distribution
+   * @param assetIndex The index of the asset distribution
+   */
+  event AssetConfigUpdated(
+    address indexed asset,
+    address indexed reward,
+    uint256 oldEmission,
+    uint256 newEmission,
+    uint256 oldDistributionEnd,
+    uint256 newDistributionEnd,
+    uint256 assetIndex
+  );
+
+  /**
+   * @dev Emitted when rewards of an asset are accrued on behalf of a user.
+   * @param asset The address of the incentivized asset
+   * @param reward The address of the reward token
+   * @param user The address of the user that rewards are accrued on behalf of
+   * @param assetIndex The index of the asset distribution
+   * @param userIndex The index of the asset distribution on behalf of the user
+   * @param rewardsAccrued The amount of rewards accrued
+   */
+  event Accrued(
+    address indexed asset,
+    address indexed reward,
+    address indexed user,
+    uint256 assetIndex,
+    uint256 userIndex,
+    uint256 rewardsAccrued
+  );
+
+  /**
+   * @dev Sets the end date for the distribution
+   * @param asset The asset to incentivize
+   * @param reward The reward token that incentives the asset
+   * @param newDistributionEnd The end date of the incentivization, in unix time format
+   **/
+  function setDistributionEnd(address asset, address reward, uint32 newDistributionEnd) external;
+
+  /**
+   * @dev Sets the emission per second of a set of reward distributions
+   * @param asset The asset is being incentivized
+   * @param rewards List of reward addresses are being distributed
+   * @param newEmissionsPerSecond List of new reward emissions per second
+   */
+  function setEmissionPerSecond(
+    address asset,
+    address[] calldata rewards,
+    uint88[] calldata newEmissionsPerSecond
+  ) external;
+
+  /**
+   * @dev Gets the end date for the distribution
+   * @param asset The incentivized asset
+   * @param reward The reward token of the incentivized asset
+   * @return The timestamp with the end of the distribution, in unix time format
+   **/
+  function getDistributionEnd(address asset, address reward) external view returns (uint256);
+
+  /**
+   * @dev Returns the index of a user on a reward distribution
+   * @param user Address of the user
+   * @param asset The incentivized asset
+   * @param reward The reward token of the incentivized asset
+   * @return The current user asset index, not including new distributions
+   **/
+  function getUserAssetIndex(
+    address user,
+    address asset,
+    address reward
+  ) external view returns (uint256);
+
+  /**
+   * @dev Returns the configuration of the distribution reward for a certain asset
+   * @param asset The incentivized asset
+   * @param reward The reward token of the incentivized asset
+   * @return The index of the asset distribution
+   * @return The emission per second of the reward distribution
+   * @return The timestamp of the last update of the index
+   * @return The timestamp of the distribution end
+   **/
+  function getRewardsData(
+    address asset,
+    address reward
+  ) external view returns (uint256, uint256, uint256, uint256);
+
+  /**
+   * @dev Calculates the next value of an specific distribution index, with validations.
+   * @param asset The incentivized asset
+   * @param reward The reward token of the incentivized asset
+   * @return The old index of the asset distribution
+   * @return The new index of the asset distribution
+   **/
+  function getAssetIndex(address asset, address reward) external view returns (uint256, uint256);
+
+  /**
+   * @dev Returns the list of available reward token addresses of an incentivized asset
+   * @param asset The incentivized asset
+   * @return List of rewards addresses of the input asset
+   **/
+  function getRewardsByAsset(address asset) external view returns (address[] memory);
+
+  /**
+   * @dev Returns the list of available reward addresses
+   * @return List of rewards supported in this contract
+   **/
+  function getRewardsList() external view returns (address[] memory);
+
+  /**
+   * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
+   * @param user The address of the user
+   * @param reward The address of the reward token
+   * @return Unclaimed rewards, not including new distributions
+   **/
+  function getUserAccruedRewards(address user, address reward) external view returns (uint256);
+
+  /**
+   * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
+   * @param assets List of incentivized assets to check eligible distributions
+   * @param user The address of the user
+   * @param reward The address of the reward token
+   * @return The rewards amount
+   **/
+  function getUserRewards(
+    address[] calldata assets,
+    address user,
+    address reward
+  ) external view returns (uint256);
+
+  /**
+   * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
+   * @param assets List of incentivized assets to check eligible distributions
+   * @param user The address of the user
+   * @return The list of reward addresses
+   * @return The list of unclaimed amount of rewards
+   **/
+  function getAllUserRewards(
+    address[] calldata assets,
+    address user
+  ) external view returns (address[] memory, uint256[] memory);
+
+  /**
+   * @dev Returns the decimals of an asset to calculate the distribution delta
+   * @param asset The address to retrieve decimals
+   * @return The decimals of an underlying asset
+   */
+  function getAssetDecimals(address asset) external view returns (uint8);
+
+  /**
+   * @dev Returns the address of the emission manager
+   * @return The address of the EmissionManager
+   */
+  function EMISSION_MANAGER() external view returns (address);
+
+  /**
+   * @dev Returns the address of the emission manager.
+   * Deprecated: This getter is maintained for compatibility purposes. Use the `EMISSION_MANAGER()` function instead.
+   * @return The address of the EmissionManager
+   */
+  function getEmissionManager() external view returns (address);
+}
+
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
+
+interface ITransferStrategyBase {
+  event EmergencyWithdrawal(
+    address indexed caller,
+    address indexed token,
+    address indexed to,
+    uint256 amount
+  );
+
+  /**
+   * @dev Perform custom transfer logic via delegate call from source contract to a TransferStrategy implementation
+   * @param to Account to transfer rewards
+   * @param reward Address of the reward token
+   * @param amount Amount to transfer to the "to" address parameter
+   * @return Returns true bool if transfer logic succeeds
+   */
+  function performTransfer(address to, address reward, uint256 amount) external returns (bool);
+
+  /**
+   * @return Returns the address of the Incentives Controller
+   */
+  function getIncentivesController() external view returns (address);
+
+  /**
+   * @return Returns the address of the Rewards admin
+   */
+  function getRewardsAdmin() external view returns (address);
+
+  /**
+   * @dev Perform an emergency token withdrawal only callable by the Rewards admin
+   * @param token Address of the token to withdraw funds from this contract
+   * @param to Address of the recipient of the withdrawal
+   * @param amount Amount of the withdrawal
+   */
+  function emergencyWithdrawal(address token, address to, uint256 amount) external;
+}
+
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/StaticATokenErrors.sol
+
+library StaticATokenErrors {
+  string public constant INVALID_OWNER = '1';
+  string public constant INVALID_EXPIRATION = '2';
+  string public constant INVALID_SIGNATURE = '3';
+  string public constant INVALID_DEPOSITOR = '4';
+  string public constant INVALID_RECIPIENT = '5';
+  string public constant INVALID_CLAIMER = '6';
+  string public constant ONLY_ONE_AMOUNT_FORMAT_ALLOWED = '7';
+  string public constant INVALID_ZERO_AMOUNT = '8';
+  string public constant REWARD_NOT_INITIALIZED = '9';
+}
+
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/interfaces/IAToken.sol
+
+interface IAToken {
+  function POOL() external view returns (address);
+
+  function getIncentivesController() external view returns (address);
+
+  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
+
+  /**
+   * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
+   * @return The scaled total supply
+   */
+  function scaledTotalSupply() external view returns (uint256);
+}
+
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/interfaces/IERC4626.sol
+
+// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)
+
+/**
+ * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
+ * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
+ *
+ * _Available since v4.7._
+ */
+interface IERC4626 {
+  event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
+
+  event Withdraw(
+    address indexed sender,
+    address indexed receiver,
+    address indexed owner,
+    uint256 assets,
+    uint256 shares
+  );
+
+  /**
+   * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
+   *
+   * - MUST be an ERC-20 token contract.
+   * - MUST NOT revert.
+   */
+  function asset() external view returns (address assetTokenAddress);
+
+  /**
+   * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
+   *
+   * - SHOULD include any compounding that occurs from yield.
+   * - MUST be inclusive of any fees that are charged against assets in the Vault.
+   * - MUST NOT revert.
+   */
+  function totalAssets() external view returns (uint256 totalManagedAssets);
+
+  /**
+   * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
+   * scenario where all the conditions are met.
+   *
+   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
+   * - MUST NOT show any variations depending on the caller.
+   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
+   * - MUST NOT revert.
+   *
+   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
+   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
+   * from.
+   */
+  function convertToShares(uint256 assets) external view returns (uint256 shares);
+
+  /**
+   * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
+   * scenario where all the conditions are met.
+   *
+   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
+   * - MUST NOT show any variations depending on the caller.
+   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
+   * - MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
+   *
+   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
+   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
+   * from.
+   */
+  function convertToAssets(uint256 shares) external view returns (uint256 assets);
+
+  /**
+   * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
+   * through a deposit call.
+   * While deposit of aToken is not affected by aave pool configrations, deposit of the aTokenUnderlying will need to deposit to aave
+   * so it is affected by current aave pool configuration.
+   * Reference: https://github.com/aave/aave-v3-core/blob/29ff9b9f89af7cd8255231bc5faf26c3ce0fb7ce/contracts/protocol/libraries/logic/ValidationLogic.sol#L57
+   * - MUST return a limited value if receiver is subject to some deposit limit.
+   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
+   * - MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
+   */
+  function maxDeposit(address receiver) external view returns (uint256 maxAssets);
+
+  /**
+   * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
+   * current on-chain conditions.
+   *
+   * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
+   *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
+   *   in the same transaction.
+   * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
+   *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
+   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
+   * - MUST NOT revert.
+   *
+   * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
+   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
+   */
+  function previewDeposit(uint256 assets) external view returns (uint256 shares);
+
+  /**
+   * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
+   *
+   * - MUST emit the Deposit event.
+   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
+   *   deposit execution, and are accounted for during deposit.
+   * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
+   *   approving enough underlying tokens to the Vault contract, etc).
+   *
+   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
+   */
+  function deposit(uint256 assets, address receiver) external returns (uint256 shares);
+
+  /**
+   * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
+   * - MUST return a limited value if receiver is subject to some mint limit.
+   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
+   * - MUST NOT revert.
+   */
+  function maxMint(address receiver) external view returns (uint256 maxShares);
+
+  /**
+   * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
+   * current on-chain conditions.
+   *
+   * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
+   *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
+   *   same transaction.
+   * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
+   *   would be accepted, regardless if the user has enough tokens approved, etc.
+   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
+   * - MUST NOT revert.
+   *
+   * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
+   * share price or some other type of condition, meaning the depositor will lose assets by minting.
+   */
+  function previewMint(uint256 shares) external view returns (uint256 assets);
+
+  /**
+   * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
+   *
+   * - MUST emit the Deposit event.
+   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
+   *   execution, and are accounted for during mint.
+   * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
+   *   approving enough underlying tokens to the Vault contract, etc).
+   *
+   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
+   */
+  function mint(uint256 shares, address receiver) external returns (uint256 assets);
+
+  /**
+   * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
+   * Vault, through a withdraw call.
+   *
+   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
+   * - MUST NOT revert.
+   */
+  function maxWithdraw(address owner) external view returns (uint256 maxAssets);
+
+  /**
+   * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
+   * given current on-chain conditions.
+   *
+   * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
+   *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
+   *   called
+   *   in the same transaction.
+   * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
+   *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
+   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
+   * - MUST NOT revert.
+   *
+   * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
+   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
+   */
+  function previewWithdraw(uint256 assets) external view returns (uint256 shares);
+
+  /**
+   * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
+   *
+   * - MUST emit the Withdraw event.
+   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
+   *   withdraw execution, and are accounted for during withdraw.
+   * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
+   *   not having enough shares, etc).
+   *
+   * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
+   * Those methods should be performed separately.
+   */
+  function withdraw(
+    uint256 assets,
+    address receiver,
+    address owner
+  ) external returns (uint256 shares);
+
+  /**
+   * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
+   * through a redeem call to the aToken underlying.
+   * While redeem of aToken is not affected by aave pool configrations, redeeming of the aTokenUnderlying will need to redeem from aave
+   * so it is affected by current aave pool configuration.
+   * Reference: https://github.com/aave/aave-v3-core/blob/29ff9b9f89af7cd8255231bc5faf26c3ce0fb7ce/contracts/protocol/libraries/logic/ValidationLogic.sol#L87
+   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
+   * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
+   * - MUST NOT revert.
+   */
+  function maxRedeem(address owner) external view returns (uint256 maxShares);
+
+  /**
+   * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
+   * given current on-chain conditions.
+   *
+   * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
+   *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
+   *   same transaction.
+   * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
+   *   redemption would be accepted, regardless if the user has enough shares, etc.
+   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
+   * - MUST NOT revert.
+   *
+   * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
+   * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
+   */
+  function previewRedeem(uint256 shares) external view returns (uint256 assets);
+
+  /**
+   * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
+   *
+   * - MUST emit the Withdraw event.
+   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
+   *   redeem execution, and are accounted for during redeem.
+   * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
+   *   not having enough shares, etc).
+   *
+   * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
+   * Those methods should be performed separately.
+   */
+  function redeem(
+    uint256 shares,
+    address receiver,
+    address owner
+  ) external returns (uint256 assets);
+}
+
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/interfaces/IStaticATokenFactory.sol
+
+interface IStaticATokenFactory {
+  /**
+   * @notice Creates new staticATokens
+   * @param underlyings the addresses of the underlyings to create.
+   * @return address[] addresses of the new staticATokens.
+   */
+  function createStaticATokens(address[] memory underlyings) external returns (address[] memory);
+
+  /**
+   * @notice Returns all tokens deployed via this registry.
+   * @return address[] list of tokens
+   */
+  function getStaticATokens() external view returns (address[] memory);
+
+  /**
+   * @notice Returns the staticAToken for a given underlying.
+   * @param underlying the address of the underlying.
+   * @return address the staticAToken address.
+   */
+  function getStaticAToken(address underlying) external view returns (address);
+}
+
+// lib/solidity-utils/src/contracts/oz-common/Address.sol
 
 // OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
 // From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a
@@ -1229,32 +1794,7 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/Context.sol
-
-// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
-// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a
-
-/**
- * @dev Provides information about the current execution context, including the
- * sender of the transaction and its data. While these are generally available
- * via msg.sender and msg.data, they should not be accessed in such a direct
- * manner, since when dealing with meta-transactions the account sending and
- * paying for execution may not be the actual sender (as far as an application
- * is concerned).
- *
- * This contract is only required for intermediate, library-like contracts.
- */
-abstract contract Context {
-  function _msgSender() internal view virtual returns (address) {
-    return msg.sender;
-  }
-
-  function _msgData() internal view virtual returns (bytes calldata) {
-    return msg.data;
-  }
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/SafeCast.sol
+// lib/solidity-utils/src/contracts/oz-common/SafeCast.sol
 
 // OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
 // This file was procedurally generated from scripts/generate/templates/SafeCast.js.
@@ -2390,7 +2930,7 @@ library SafeCast {
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20.sol
+// lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20.sol
 
 // OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
 // From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/a035b235b4f2c9af4ba88edc4447f02e37f8d124
@@ -2469,7 +3009,7 @@ interface IERC20 {
   function transferFrom(address from, address to, uint256 amount) external returns (bool);
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20Permit.sol
+// lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20Permit.sol
 
 // OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)
 // Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/commit/00cbf5a236564c3b7aacdad1f378cae22d890ca6
@@ -2530,7 +3070,7 @@ interface IERC20Permit {
   function DOMAIN_SEPARATOR() external view returns (bytes32);
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol
+// lib/solidity-utils/src/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol
 
 interface ITransparentProxyFactory {
   event ProxyCreated(address proxy, address indexed logic, address indexed proxyAdmin);
@@ -2622,1637 +3162,7 @@ interface ITransparentProxyFactory {
   function predictCreateDeterministicProxyAdmin(bytes32 salt) external view returns (address);
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-v3-periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
-
-interface IEACAggregatorProxy {
-  function decimals() external view returns (uint8);
-
-  function latestAnswer() external view returns (int256);
-
-  function latestTimestamp() external view returns (uint256);
-
-  function latestRound() external view returns (uint256);
-
-  function getAnswer(uint256 roundId) external view returns (int256);
-
-  function getTimestamp(uint256 roundId) external view returns (uint256);
-
-  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
-  event NewRound(uint256 indexed roundId, address indexed startedBy);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-v3-periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
-
-/**
- * @title IRewardsDistributor
- * @author Aave
- * @notice Defines the basic interface for a Rewards Distributor.
- */
-interface IRewardsDistributor {
-  /**
-   * @dev Emitted when the configuration of the rewards of an asset is updated.
-   * @param asset The address of the incentivized asset
-   * @param reward The address of the reward token
-   * @param oldEmission The old emissions per second value of the reward distribution
-   * @param newEmission The new emissions per second value of the reward distribution
-   * @param oldDistributionEnd The old end timestamp of the reward distribution
-   * @param newDistributionEnd The new end timestamp of the reward distribution
-   * @param assetIndex The index of the asset distribution
-   */
-  event AssetConfigUpdated(
-    address indexed asset,
-    address indexed reward,
-    uint256 oldEmission,
-    uint256 newEmission,
-    uint256 oldDistributionEnd,
-    uint256 newDistributionEnd,
-    uint256 assetIndex
-  );
-
-  /**
-   * @dev Emitted when rewards of an asset are accrued on behalf of a user.
-   * @param asset The address of the incentivized asset
-   * @param reward The address of the reward token
-   * @param user The address of the user that rewards are accrued on behalf of
-   * @param assetIndex The index of the asset distribution
-   * @param userIndex The index of the asset distribution on behalf of the user
-   * @param rewardsAccrued The amount of rewards accrued
-   */
-  event Accrued(
-    address indexed asset,
-    address indexed reward,
-    address indexed user,
-    uint256 assetIndex,
-    uint256 userIndex,
-    uint256 rewardsAccrued
-  );
-
-  /**
-   * @dev Sets the end date for the distribution
-   * @param asset The asset to incentivize
-   * @param reward The reward token that incentives the asset
-   * @param newDistributionEnd The end date of the incentivization, in unix time format
-   **/
-  function setDistributionEnd(address asset, address reward, uint32 newDistributionEnd) external;
-
-  /**
-   * @dev Sets the emission per second of a set of reward distributions
-   * @param asset The asset is being incentivized
-   * @param rewards List of reward addresses are being distributed
-   * @param newEmissionsPerSecond List of new reward emissions per second
-   */
-  function setEmissionPerSecond(
-    address asset,
-    address[] calldata rewards,
-    uint88[] calldata newEmissionsPerSecond
-  ) external;
-
-  /**
-   * @dev Gets the end date for the distribution
-   * @param asset The incentivized asset
-   * @param reward The reward token of the incentivized asset
-   * @return The timestamp with the end of the distribution, in unix time format
-   **/
-  function getDistributionEnd(address asset, address reward) external view returns (uint256);
-
-  /**
-   * @dev Returns the index of a user on a reward distribution
-   * @param user Address of the user
-   * @param asset The incentivized asset
-   * @param reward The reward token of the incentivized asset
-   * @return The current user asset index, not including new distributions
-   **/
-  function getUserAssetIndex(
-    address user,
-    address asset,
-    address reward
-  ) external view returns (uint256);
-
-  /**
-   * @dev Returns the configuration of the distribution reward for a certain asset
-   * @param asset The incentivized asset
-   * @param reward The reward token of the incentivized asset
-   * @return The index of the asset distribution
-   * @return The emission per second of the reward distribution
-   * @return The timestamp of the last update of the index
-   * @return The timestamp of the distribution end
-   **/
-  function getRewardsData(
-    address asset,
-    address reward
-  ) external view returns (uint256, uint256, uint256, uint256);
-
-  /**
-   * @dev Calculates the next value of an specific distribution index, with validations.
-   * @param asset The incentivized asset
-   * @param reward The reward token of the incentivized asset
-   * @return The old index of the asset distribution
-   * @return The new index of the asset distribution
-   **/
-  function getAssetIndex(address asset, address reward) external view returns (uint256, uint256);
-
-  /**
-   * @dev Returns the list of available reward token addresses of an incentivized asset
-   * @param asset The incentivized asset
-   * @return List of rewards addresses of the input asset
-   **/
-  function getRewardsByAsset(address asset) external view returns (address[] memory);
-
-  /**
-   * @dev Returns the list of available reward addresses
-   * @return List of rewards supported in this contract
-   **/
-  function getRewardsList() external view returns (address[] memory);
-
-  /**
-   * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
-   * @param user The address of the user
-   * @param reward The address of the reward token
-   * @return Unclaimed rewards, not including new distributions
-   **/
-  function getUserAccruedRewards(address user, address reward) external view returns (uint256);
-
-  /**
-   * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
-   * @param assets List of incentivized assets to check eligible distributions
-   * @param user The address of the user
-   * @param reward The address of the reward token
-   * @return The rewards amount
-   **/
-  function getUserRewards(
-    address[] calldata assets,
-    address user,
-    address reward
-  ) external view returns (uint256);
-
-  /**
-   * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
-   * @param assets List of incentivized assets to check eligible distributions
-   * @param user The address of the user
-   * @return The list of reward addresses
-   * @return The list of unclaimed amount of rewards
-   **/
-  function getAllUserRewards(
-    address[] calldata assets,
-    address user
-  ) external view returns (address[] memory, uint256[] memory);
-
-  /**
-   * @dev Returns the decimals of an asset to calculate the distribution delta
-   * @param asset The address to retrieve decimals
-   * @return The decimals of an underlying asset
-   */
-  function getAssetDecimals(address asset) external view returns (uint8);
-
-  /**
-   * @dev Returns the address of the emission manager
-   * @return The address of the EmissionManager
-   */
-  function EMISSION_MANAGER() external view returns (address);
-
-  /**
-   * @dev Returns the address of the emission manager.
-   * Deprecated: This getter is maintained for compatibility purposes. Use the `EMISSION_MANAGER()` function instead.
-   * @return The address of the EmissionManager
-   */
-  function getEmissionManager() external view returns (address);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-v3-periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
-
-interface ITransferStrategyBase {
-  event EmergencyWithdrawal(
-    address indexed caller,
-    address indexed token,
-    address indexed to,
-    uint256 amount
-  );
-
-  /**
-   * @dev Perform custom transfer logic via delegate call from source contract to a TransferStrategy implementation
-   * @param to Account to transfer rewards
-   * @param reward Address of the reward token
-   * @param amount Amount to transfer to the "to" address parameter
-   * @return Returns true bool if transfer logic succeeds
-   */
-  function performTransfer(address to, address reward, uint256 amount) external returns (bool);
-
-  /**
-   * @return Returns the address of the Incentives Controller
-   */
-  function getIncentivesController() external view returns (address);
-
-  /**
-   * @return Returns the address of the Rewards admin
-   */
-  function getRewardsAdmin() external view returns (address);
-
-  /**
-   * @dev Perform an emergency token withdrawal only callable by the Rewards admin
-   * @param token Address of the token to withdraw funds from this contract
-   * @param to Address of the recipient of the withdrawal
-   * @param amount Amount of the withdrawal
-   */
-  function emergencyWithdrawal(address token, address to, uint256 amount) external;
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/ECDSA.sol
-
-// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)
-
-/**
- * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
- *
- * These functions can be used to verify that a message was signed by the holder
- * of the private keys of a given address.
- */
-library ECDSA {
-  enum RecoverError {
-    NoError,
-    InvalidSignature,
-    InvalidSignatureLength,
-    InvalidSignatureS
-  }
-
-  /**
-   * @dev The signature derives the `address(0)`.
-   */
-  error ECDSAInvalidSignature();
-
-  /**
-   * @dev The signature has an invalid length.
-   */
-  error ECDSAInvalidSignatureLength(uint256 length);
-
-  /**
-   * @dev The signature has an S value that is in the upper half order.
-   */
-  error ECDSAInvalidSignatureS(bytes32 s);
-
-  /**
-   * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
-   * return address(0) without also returning an error description. Errors are documented using an enum (error type)
-   * and a bytes32 providing additional information about the error.
-   *
-   * If no error is returned, then the address can be used for verification purposes.
-   *
-   * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
-   * this function rejects them by requiring the `s` value to be in the lower
-   * half order, and the `v` value to be either 27 or 28.
-   *
-   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
-   * verification to be secure: it is possible to craft signatures that
-   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
-   * this is by receiving a hash of the original message (which may otherwise
-   * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
-   *
-   * Documentation for signature generation:
-   * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
-   * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
-   */
-  function tryRecover(
-    bytes32 hash,
-    bytes memory signature
-  ) internal pure returns (address, RecoverError, bytes32) {
-    if (signature.length == 65) {
-      bytes32 r;
-      bytes32 s;
-      uint8 v;
-      // ecrecover takes the signature parameters, and the only way to get them
-      // currently is to use assembly.
-      /// @solidity memory-safe-assembly
-      assembly {
-        r := mload(add(signature, 0x20))
-        s := mload(add(signature, 0x40))
-        v := byte(0, mload(add(signature, 0x60)))
-      }
-      return tryRecover(hash, v, r, s);
-    } else {
-      return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
-    }
-  }
-
-  /**
-   * @dev Returns the address that signed a hashed message (`hash`) with
-   * `signature`. This address can then be used for verification purposes.
-   *
-   * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
-   * this function rejects them by requiring the `s` value to be in the lower
-   * half order, and the `v` value to be either 27 or 28.
-   *
-   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
-   * verification to be secure: it is possible to craft signatures that
-   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
-   * this is by receiving a hash of the original message (which may otherwise
-   * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
-   */
-  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
-    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
-    _throwError(error, errorArg);
-    return recovered;
-  }
-
-  /**
-   * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
-   *
-   * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
-   */
-  function tryRecover(
-    bytes32 hash,
-    bytes32 r,
-    bytes32 vs
-  ) internal pure returns (address, RecoverError, bytes32) {
-    unchecked {
-      bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
-      // We do not check for an overflow here since the shift operation results in 0 or 1.
-      uint8 v = uint8((uint256(vs) >> 255) + 27);
-      return tryRecover(hash, v, r, s);
-    }
-  }
-
-  /**
-   * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
-   */
-  function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
-    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
-    _throwError(error, errorArg);
-    return recovered;
-  }
-
-  /**
-   * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
-   * `r` and `s` signature fields separately.
-   */
-  function tryRecover(
-    bytes32 hash,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) internal pure returns (address, RecoverError, bytes32) {
-    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
-    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
-    // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
-    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
-    //
-    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
-    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
-    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
-    // these malleable signatures as well.
-    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
-      return (address(0), RecoverError.InvalidSignatureS, s);
-    }
-
-    // If the signature is valid (and not malleable), return the signer address
-    address signer = ecrecover(hash, v, r, s);
-    if (signer == address(0)) {
-      return (address(0), RecoverError.InvalidSignature, bytes32(0));
-    }
-
-    return (signer, RecoverError.NoError, bytes32(0));
-  }
-
-  /**
-   * @dev Overload of {ECDSA-recover} that receives the `v`,
-   * `r` and `s` signature fields separately.
-   */
-  function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
-    (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
-    _throwError(error, errorArg);
-    return recovered;
-  }
-
-  /**
-   * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
-   */
-  function _throwError(RecoverError error, bytes32 errorArg) private pure {
-    if (error == RecoverError.NoError) {
-      return; // no error: do nothing
-    } else if (error == RecoverError.InvalidSignature) {
-      revert ECDSAInvalidSignature();
-    } else if (error == RecoverError.InvalidSignatureLength) {
-      revert ECDSAInvalidSignatureLength(uint256(errorArg));
-    } else if (error == RecoverError.InvalidSignatureS) {
-      revert ECDSAInvalidSignatureS(errorArg);
-    }
-  }
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/RayMathExplicitRounding.sol
-
-enum Rounding {
-  UP,
-  DOWN
-}
-
-/**
- * Simplified version of RayMath that instead of half-up rounding does explicit rounding in a specified direction.
- * This is needed to have a 4626 complient implementation, that always predictable rounds in favor of the vault / static a token.
- */
-library RayMathExplicitRounding {
-  uint256 internal constant RAY = 1e27;
-  uint256 internal constant WAD_RAY_RATIO = 1e9;
-
-  function rayMulRoundDown(uint256 a, uint256 b) internal pure returns (uint256) {
-    if (a == 0 || b == 0) {
-      return 0;
-    }
-    return (a * b) / RAY;
-  }
-
-  function rayMulRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
-    if (a == 0 || b == 0) {
-      return 0;
-    }
-    return ((a * b) + RAY - 1) / RAY;
-  }
-
-  function rayDivRoundDown(uint256 a, uint256 b) internal pure returns (uint256) {
-    return (a * RAY) / b;
-  }
-
-  function rayDivRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
-    return ((a * RAY) + b - 1) / b;
-  }
-
-  function rayToWadRoundDown(uint256 a) internal pure returns (uint256) {
-    return a / WAD_RAY_RATIO;
-  }
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/StaticATokenErrors.sol
-
-library StaticATokenErrors {
-  string public constant INVALID_OWNER = '1';
-  string public constant INVALID_EXPIRATION = '2';
-  string public constant INVALID_SIGNATURE = '3';
-  string public constant INVALID_DEPOSITOR = '4';
-  string public constant INVALID_RECIPIENT = '5';
-  string public constant INVALID_CLAIMER = '6';
-  string public constant ONLY_ONE_AMOUNT_FORMAT_ALLOWED = '7';
-  string public constant INVALID_ZERO_AMOUNT = '8';
-  string public constant REWARD_NOT_INITIALIZED = '9';
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/interfaces/IERC4626.sol
-
-// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)
-
-/**
- * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
- * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
- *
- * _Available since v4.7._
- */
-interface IERC4626 {
-  event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
-
-  event Withdraw(
-    address indexed sender,
-    address indexed receiver,
-    address indexed owner,
-    uint256 assets,
-    uint256 shares
-  );
-
-  /**
-   * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
-   *
-   * - MUST be an ERC-20 token contract.
-   * - MUST NOT revert.
-   */
-  function asset() external view returns (address assetTokenAddress);
-
-  /**
-   * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
-   *
-   * - SHOULD include any compounding that occurs from yield.
-   * - MUST be inclusive of any fees that are charged against assets in the Vault.
-   * - MUST NOT revert.
-   */
-  function totalAssets() external view returns (uint256 totalManagedAssets);
-
-  /**
-   * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
-   * scenario where all the conditions are met.
-   *
-   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
-   * - MUST NOT show any variations depending on the caller.
-   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
-   * - MUST NOT revert.
-   *
-   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
-   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
-   * from.
-   */
-  function convertToShares(uint256 assets) external view returns (uint256 shares);
-
-  /**
-   * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
-   * scenario where all the conditions are met.
-   *
-   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
-   * - MUST NOT show any variations depending on the caller.
-   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
-   * - MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
-   *
-   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
-   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
-   * from.
-   */
-  function convertToAssets(uint256 shares) external view returns (uint256 assets);
-
-  /**
-   * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
-   * through a deposit call.
-   * While deposit of aToken is not affected by aave pool configrations, deposit of the aTokenUnderlying will need to deposit to aave
-   * so it is affected by current aave pool configuration.
-   * Reference: https://github.com/aave/aave-v3-core/blob/29ff9b9f89af7cd8255231bc5faf26c3ce0fb7ce/contracts/protocol/libraries/logic/ValidationLogic.sol#L57
-   * - MUST return a limited value if receiver is subject to some deposit limit.
-   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
-   * - MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
-   */
-  function maxDeposit(address receiver) external view returns (uint256 maxAssets);
-
-  /**
-   * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
-   * current on-chain conditions.
-   *
-   * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
-   *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
-   *   in the same transaction.
-   * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
-   *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
-   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
-   * - MUST NOT revert.
-   *
-   * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
-   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
-   */
-  function previewDeposit(uint256 assets) external view returns (uint256 shares);
-
-  /**
-   * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
-   *
-   * - MUST emit the Deposit event.
-   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
-   *   deposit execution, and are accounted for during deposit.
-   * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
-   *   approving enough underlying tokens to the Vault contract, etc).
-   *
-   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
-   */
-  function deposit(uint256 assets, address receiver) external returns (uint256 shares);
-
-  /**
-   * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
-   * - MUST return a limited value if receiver is subject to some mint limit.
-   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
-   * - MUST NOT revert.
-   */
-  function maxMint(address receiver) external view returns (uint256 maxShares);
-
-  /**
-   * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
-   * current on-chain conditions.
-   *
-   * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
-   *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
-   *   same transaction.
-   * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
-   *   would be accepted, regardless if the user has enough tokens approved, etc.
-   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
-   * - MUST NOT revert.
-   *
-   * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
-   * share price or some other type of condition, meaning the depositor will lose assets by minting.
-   */
-  function previewMint(uint256 shares) external view returns (uint256 assets);
-
-  /**
-   * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
-   *
-   * - MUST emit the Deposit event.
-   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
-   *   execution, and are accounted for during mint.
-   * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
-   *   approving enough underlying tokens to the Vault contract, etc).
-   *
-   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
-   */
-  function mint(uint256 shares, address receiver) external returns (uint256 assets);
-
-  /**
-   * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
-   * Vault, through a withdraw call.
-   *
-   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
-   * - MUST NOT revert.
-   */
-  function maxWithdraw(address owner) external view returns (uint256 maxAssets);
-
-  /**
-   * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
-   * given current on-chain conditions.
-   *
-   * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
-   *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
-   *   called
-   *   in the same transaction.
-   * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
-   *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
-   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
-   * - MUST NOT revert.
-   *
-   * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
-   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
-   */
-  function previewWithdraw(uint256 assets) external view returns (uint256 shares);
-
-  /**
-   * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
-   *
-   * - MUST emit the Withdraw event.
-   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
-   *   withdraw execution, and are accounted for during withdraw.
-   * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
-   *   not having enough shares, etc).
-   *
-   * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
-   * Those methods should be performed separately.
-   */
-  function withdraw(
-    uint256 assets,
-    address receiver,
-    address owner
-  ) external returns (uint256 shares);
-
-  /**
-   * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
-   * through a redeem call to the aToken underlying.
-   * While redeem of aToken is not affected by aave pool configrations, redeeming of the aTokenUnderlying will need to redeem from aave
-   * so it is affected by current aave pool configuration.
-   * Reference: https://github.com/aave/aave-v3-core/blob/29ff9b9f89af7cd8255231bc5faf26c3ce0fb7ce/contracts/protocol/libraries/logic/ValidationLogic.sol#L87
-   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
-   * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
-   * - MUST NOT revert.
-   */
-  function maxRedeem(address owner) external view returns (uint256 maxShares);
-
-  /**
-   * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
-   * given current on-chain conditions.
-   *
-   * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
-   *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
-   *   same transaction.
-   * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
-   *   redemption would be accepted, regardless if the user has enough shares, etc.
-   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
-   * - MUST NOT revert.
-   *
-   * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
-   * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
-   */
-  function previewRedeem(uint256 shares) external view returns (uint256 assets);
-
-  /**
-   * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
-   *
-   * - MUST emit the Withdraw event.
-   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
-   *   redeem execution, and are accounted for during redeem.
-   * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
-   *   not having enough shares, etc).
-   *
-   * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
-   * Those methods should be performed separately.
-   */
-  function redeem(
-    uint256 shares,
-    address receiver,
-    address owner
-  ) external returns (uint256 assets);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IACLManager.sol
-
-/**
- * @title IACLManager
- * @author Aave
- * @notice Defines the basic interface for the ACL Manager
- */
-interface IACLManager {
-  /**
-   * @notice Returns the contract address of the PoolAddressesProvider
-   * @return The address of the PoolAddressesProvider
-   */
-  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);
-
-  /**
-   * @notice Returns the identifier of the PoolAdmin role
-   * @return The id of the PoolAdmin role
-   */
-  function POOL_ADMIN_ROLE() external view returns (bytes32);
-
-  /**
-   * @notice Returns the identifier of the EmergencyAdmin role
-   * @return The id of the EmergencyAdmin role
-   */
-  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);
-
-  /**
-   * @notice Returns the identifier of the RiskAdmin role
-   * @return The id of the RiskAdmin role
-   */
-  function RISK_ADMIN_ROLE() external view returns (bytes32);
-
-  /**
-   * @notice Returns the identifier of the FlashBorrower role
-   * @return The id of the FlashBorrower role
-   */
-  function FLASH_BORROWER_ROLE() external view returns (bytes32);
-
-  /**
-   * @notice Returns the identifier of the Bridge role
-   * @return The id of the Bridge role
-   */
-  function BRIDGE_ROLE() external view returns (bytes32);
-
-  /**
-   * @notice Returns the identifier of the AssetListingAdmin role
-   * @return The id of the AssetListingAdmin role
-   */
-  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);
-
-  /**
-   * @notice Set the role as admin of a specific role.
-   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
-   * @param role The role to be managed by the admin role
-   * @param adminRole The admin role
-   */
-  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
-
-  /**
-   * @notice Adds a new admin as PoolAdmin
-   * @param admin The address of the new admin
-   */
-  function addPoolAdmin(address admin) external;
-
-  /**
-   * @notice Removes an admin as PoolAdmin
-   * @param admin The address of the admin to remove
-   */
-  function removePoolAdmin(address admin) external;
-
-  /**
-   * @notice Returns true if the address is PoolAdmin, false otherwise
-   * @param admin The address to check
-   * @return True if the given address is PoolAdmin, false otherwise
-   */
-  function isPoolAdmin(address admin) external view returns (bool);
-
-  /**
-   * @notice Adds a new admin as EmergencyAdmin
-   * @param admin The address of the new admin
-   */
-  function addEmergencyAdmin(address admin) external;
-
-  /**
-   * @notice Removes an admin as EmergencyAdmin
-   * @param admin The address of the admin to remove
-   */
-  function removeEmergencyAdmin(address admin) external;
-
-  /**
-   * @notice Returns true if the address is EmergencyAdmin, false otherwise
-   * @param admin The address to check
-   * @return True if the given address is EmergencyAdmin, false otherwise
-   */
-  function isEmergencyAdmin(address admin) external view returns (bool);
-
-  /**
-   * @notice Adds a new admin as RiskAdmin
-   * @param admin The address of the new admin
-   */
-  function addRiskAdmin(address admin) external;
-
-  /**
-   * @notice Removes an admin as RiskAdmin
-   * @param admin The address of the admin to remove
-   */
-  function removeRiskAdmin(address admin) external;
-
-  /**
-   * @notice Returns true if the address is RiskAdmin, false otherwise
-   * @param admin The address to check
-   * @return True if the given address is RiskAdmin, false otherwise
-   */
-  function isRiskAdmin(address admin) external view returns (bool);
-
-  /**
-   * @notice Adds a new address as FlashBorrower
-   * @param borrower The address of the new FlashBorrower
-   */
-  function addFlashBorrower(address borrower) external;
-
-  /**
-   * @notice Removes an address as FlashBorrower
-   * @param borrower The address of the FlashBorrower to remove
-   */
-  function removeFlashBorrower(address borrower) external;
-
-  /**
-   * @notice Returns true if the address is FlashBorrower, false otherwise
-   * @param borrower The address to check
-   * @return True if the given address is FlashBorrower, false otherwise
-   */
-  function isFlashBorrower(address borrower) external view returns (bool);
-
-  /**
-   * @notice Adds a new address as Bridge
-   * @param bridge The address of the new Bridge
-   */
-  function addBridge(address bridge) external;
-
-  /**
-   * @notice Removes an address as Bridge
-   * @param bridge The address of the bridge to remove
-   */
-  function removeBridge(address bridge) external;
-
-  /**
-   * @notice Returns true if the address is Bridge, false otherwise
-   * @param bridge The address to check
-   * @return True if the given address is Bridge, false otherwise
-   */
-  function isBridge(address bridge) external view returns (bool);
-
-  /**
-   * @notice Adds a new admin as AssetListingAdmin
-   * @param admin The address of the new admin
-   */
-  function addAssetListingAdmin(address admin) external;
-
-  /**
-   * @notice Removes an admin as AssetListingAdmin
-   * @param admin The address of the admin to remove
-   */
-  function removeAssetListingAdmin(address admin) external;
-
-  /**
-   * @notice Returns true if the address is AssetListingAdmin, false otherwise
-   * @param admin The address to check
-   * @return True if the given address is AssetListingAdmin, false otherwise
-   */
-  function isAssetListingAdmin(address admin) external view returns (bool);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IPoolConfigurator.sol
-
-/**
- * @title IPoolConfigurator
- * @author Aave
- * @notice Defines the basic interface for a Pool configurator.
- */
-interface IPoolConfigurator {
-  /**
-   * @dev Emitted when a reserve is initialized.
-   * @param asset The address of the underlying asset of the reserve
-   * @param aToken The address of the associated aToken contract
-   * @param stableDebtToken The address of the associated stable rate debt token
-   * @param variableDebtToken The address of the associated variable rate debt token
-   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
-   */
-  event ReserveInitialized(
-    address indexed asset,
-    address indexed aToken,
-    address stableDebtToken,
-    address variableDebtToken,
-    address interestRateStrategyAddress
-  );
-
-  /**
-   * @dev Emitted when borrowing is enabled or disabled on a reserve.
-   * @param asset The address of the underlying asset of the reserve
-   * @param enabled True if borrowing is enabled, false otherwise
-   */
-  event ReserveBorrowing(address indexed asset, bool enabled);
-
-  /**
-   * @dev Emitted when flashloans are enabled or disabled on a reserve.
-   * @param asset The address of the underlying asset of the reserve
-   * @param enabled True if flashloans are enabled, false otherwise
-   */
-  event ReserveFlashLoaning(address indexed asset, bool enabled);
-
-  /**
-   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
-   * @param asset The address of the underlying asset of the reserve
-   * @param ltv The loan to value of the asset when used as collateral
-   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
-   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
-   */
-  event CollateralConfigurationChanged(
-    address indexed asset,
-    uint256 ltv,
-    uint256 liquidationThreshold,
-    uint256 liquidationBonus
-  );
-
-  /**
-   * @dev Emitted when stable rate borrowing is enabled or disabled on a reserve
-   * @param asset The address of the underlying asset of the reserve
-   * @param enabled True if stable rate borrowing is enabled, false otherwise
-   */
-  event ReserveStableRateBorrowing(address indexed asset, bool enabled);
-
-  /**
-   * @dev Emitted when a reserve is activated or deactivated
-   * @param asset The address of the underlying asset of the reserve
-   * @param active True if reserve is active, false otherwise
-   */
-  event ReserveActive(address indexed asset, bool active);
-
-  /**
-   * @dev Emitted when a reserve is frozen or unfrozen
-   * @param asset The address of the underlying asset of the reserve
-   * @param frozen True if reserve is frozen, false otherwise
-   */
-  event ReserveFrozen(address indexed asset, bool frozen);
-
-  /**
-   * @dev Emitted when a reserve is paused or unpaused
-   * @param asset The address of the underlying asset of the reserve
-   * @param paused True if reserve is paused, false otherwise
-   */
-  event ReservePaused(address indexed asset, bool paused);
-
-  /**
-   * @dev Emitted when a reserve is dropped.
-   * @param asset The address of the underlying asset of the reserve
-   */
-  event ReserveDropped(address indexed asset);
-
-  /**
-   * @dev Emitted when a reserve factor is updated.
-   * @param asset The address of the underlying asset of the reserve
-   * @param oldReserveFactor The old reserve factor, expressed in bps
-   * @param newReserveFactor The new reserve factor, expressed in bps
-   */
-  event ReserveFactorChanged(
-    address indexed asset,
-    uint256 oldReserveFactor,
-    uint256 newReserveFactor
-  );
-
-  /**
-   * @dev Emitted when the borrow cap of a reserve is updated.
-   * @param asset The address of the underlying asset of the reserve
-   * @param oldBorrowCap The old borrow cap
-   * @param newBorrowCap The new borrow cap
-   */
-  event BorrowCapChanged(address indexed asset, uint256 oldBorrowCap, uint256 newBorrowCap);
-
-  /**
-   * @dev Emitted when the supply cap of a reserve is updated.
-   * @param asset The address of the underlying asset of the reserve
-   * @param oldSupplyCap The old supply cap
-   * @param newSupplyCap The new supply cap
-   */
-  event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);
-
-  /**
-   * @dev Emitted when the liquidation protocol fee of a reserve is updated.
-   * @param asset The address of the underlying asset of the reserve
-   * @param oldFee The old liquidation protocol fee, expressed in bps
-   * @param newFee The new liquidation protocol fee, expressed in bps
-   */
-  event LiquidationProtocolFeeChanged(address indexed asset, uint256 oldFee, uint256 newFee);
-
-  /**
-   * @dev Emitted when the unbacked mint cap of a reserve is updated.
-   * @param asset The address of the underlying asset of the reserve
-   * @param oldUnbackedMintCap The old unbacked mint cap
-   * @param newUnbackedMintCap The new unbacked mint cap
-   */
-  event UnbackedMintCapChanged(
-    address indexed asset,
-    uint256 oldUnbackedMintCap,
-    uint256 newUnbackedMintCap
-  );
-
-  /**
-   * @dev Emitted when the category of an asset in eMode is changed.
-   * @param asset The address of the underlying asset of the reserve
-   * @param oldCategoryId The old eMode asset category
-   * @param newCategoryId The new eMode asset category
-   */
-  event EModeAssetCategoryChanged(address indexed asset, uint8 oldCategoryId, uint8 newCategoryId);
-
-  /**
-   * @dev Emitted when a new eMode category is added.
-   * @param categoryId The new eMode category id
-   * @param ltv The ltv for the asset category in eMode
-   * @param liquidationThreshold The liquidationThreshold for the asset category in eMode
-   * @param liquidationBonus The liquidationBonus for the asset category in eMode
-   * @param oracle The optional address of the price oracle specific for this category
-   * @param label A human readable identifier for the category
-   */
-  event EModeCategoryAdded(
-    uint8 indexed categoryId,
-    uint256 ltv,
-    uint256 liquidationThreshold,
-    uint256 liquidationBonus,
-    address oracle,
-    string label
-  );
-
-  /**
-   * @dev Emitted when a reserve interest strategy contract is updated.
-   * @param asset The address of the underlying asset of the reserve
-   * @param oldStrategy The address of the old interest strategy contract
-   * @param newStrategy The address of the new interest strategy contract
-   */
-  event ReserveInterestRateStrategyChanged(
-    address indexed asset,
-    address oldStrategy,
-    address newStrategy
-  );
-
-  /**
-   * @dev Emitted when an aToken implementation is upgraded.
-   * @param asset The address of the underlying asset of the reserve
-   * @param proxy The aToken proxy address
-   * @param implementation The new aToken implementation
-   */
-  event ATokenUpgraded(
-    address indexed asset,
-    address indexed proxy,
-    address indexed implementation
-  );
-
-  /**
-   * @dev Emitted when the implementation of a stable debt token is upgraded.
-   * @param asset The address of the underlying asset of the reserve
-   * @param proxy The stable debt token proxy address
-   * @param implementation The new aToken implementation
-   */
-  event StableDebtTokenUpgraded(
-    address indexed asset,
-    address indexed proxy,
-    address indexed implementation
-  );
-
-  /**
-   * @dev Emitted when the implementation of a variable debt token is upgraded.
-   * @param asset The address of the underlying asset of the reserve
-   * @param proxy The variable debt token proxy address
-   * @param implementation The new aToken implementation
-   */
-  event VariableDebtTokenUpgraded(
-    address indexed asset,
-    address indexed proxy,
-    address indexed implementation
-  );
-
-  /**
-   * @dev Emitted when the debt ceiling of an asset is set.
-   * @param asset The address of the underlying asset of the reserve
-   * @param oldDebtCeiling The old debt ceiling
-   * @param newDebtCeiling The new debt ceiling
-   */
-  event DebtCeilingChanged(address indexed asset, uint256 oldDebtCeiling, uint256 newDebtCeiling);
-
-  /**
-   * @dev Emitted when the the siloed borrowing state for an asset is changed.
-   * @param asset The address of the underlying asset of the reserve
-   * @param oldState The old siloed borrowing state
-   * @param newState The new siloed borrowing state
-   */
-  event SiloedBorrowingChanged(address indexed asset, bool oldState, bool newState);
-
-  /**
-   * @dev Emitted when the bridge protocol fee is updated.
-   * @param oldBridgeProtocolFee The old protocol fee, expressed in bps
-   * @param newBridgeProtocolFee The new protocol fee, expressed in bps
-   */
-  event BridgeProtocolFeeUpdated(uint256 oldBridgeProtocolFee, uint256 newBridgeProtocolFee);
-
-  /**
-   * @dev Emitted when the total premium on flashloans is updated.
-   * @param oldFlashloanPremiumTotal The old premium, expressed in bps
-   * @param newFlashloanPremiumTotal The new premium, expressed in bps
-   */
-  event FlashloanPremiumTotalUpdated(
-    uint128 oldFlashloanPremiumTotal,
-    uint128 newFlashloanPremiumTotal
-  );
-
-  /**
-   * @dev Emitted when the part of the premium that goes to protocol is updated.
-   * @param oldFlashloanPremiumToProtocol The old premium, expressed in bps
-   * @param newFlashloanPremiumToProtocol The new premium, expressed in bps
-   */
-  event FlashloanPremiumToProtocolUpdated(
-    uint128 oldFlashloanPremiumToProtocol,
-    uint128 newFlashloanPremiumToProtocol
-  );
-
-  /**
-   * @dev Emitted when the reserve is set as borrowable/non borrowable in isolation mode.
-   * @param asset The address of the underlying asset of the reserve
-   * @param borrowable True if the reserve is borrowable in isolation, false otherwise
-   */
-  event BorrowableInIsolationChanged(address asset, bool borrowable);
-
-  /**
-   * @notice Initializes multiple reserves.
-   * @param input The array of initialization parameters
-   */
-  function initReserves(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;
-
-  /**
-   * @dev Updates the aToken implementation for the reserve.
-   * @param input The aToken update parameters
-   */
-  function updateAToken(ConfiguratorInputTypes.UpdateATokenInput calldata input) external;
-
-  /**
-   * @notice Updates the stable debt token implementation for the reserve.
-   * @param input The stableDebtToken update parameters
-   */
-  function updateStableDebtToken(
-    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
-  ) external;
-
-  /**
-   * @notice Updates the variable debt token implementation for the asset.
-   * @param input The variableDebtToken update parameters
-   */
-  function updateVariableDebtToken(
-    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
-  ) external;
-
-  /**
-   * @notice Configures borrowing on a reserve.
-   * @dev Can only be disabled (set to false) if stable borrowing is disabled
-   * @param asset The address of the underlying asset of the reserve
-   * @param enabled True if borrowing needs to be enabled, false otherwise
-   */
-  function setReserveBorrowing(address asset, bool enabled) external;
-
-  /**
-   * @notice Configures the reserve collateralization parameters.
-   * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
-   * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
-   * @param asset The address of the underlying asset of the reserve
-   * @param ltv The loan to value of the asset when used as collateral
-   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
-   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
-   */
-  function configureReserveAsCollateral(
-    address asset,
-    uint256 ltv,
-    uint256 liquidationThreshold,
-    uint256 liquidationBonus
-  ) external;
-
-  /**
-   * @notice Enable or disable stable rate borrowing on a reserve.
-   * @dev Can only be enabled (set to true) if borrowing is enabled
-   * @param asset The address of the underlying asset of the reserve
-   * @param enabled True if stable rate borrowing needs to be enabled, false otherwise
-   */
-  function setReserveStableRateBorrowing(address asset, bool enabled) external;
-
-  /**
-   * @notice Enable or disable flashloans on a reserve
-   * @param asset The address of the underlying asset of the reserve
-   * @param enabled True if flashloans need to be enabled, false otherwise
-   */
-  function setReserveFlashLoaning(address asset, bool enabled) external;
-
-  /**
-   * @notice Activate or deactivate a reserve
-   * @param asset The address of the underlying asset of the reserve
-   * @param active True if the reserve needs to be active, false otherwise
-   */
-  function setReserveActive(address asset, bool active) external;
-
-  /**
-   * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
-   * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
-   * @param asset The address of the underlying asset of the reserve
-   * @param freeze True if the reserve needs to be frozen, false otherwise
-   */
-  function setReserveFreeze(address asset, bool freeze) external;
-
-  /**
-   * @notice Sets the borrowable in isolation flag for the reserve.
-   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the
-   * borrowed amount will be accumulated in the isolated collateral's total debt exposure
-   * @dev Only assets of the same family (e.g. USD stablecoins) should be borrowable in isolation mode to keep
-   * consistency in the debt ceiling calculations
-   * @param asset The address of the underlying asset of the reserve
-   * @param borrowable True if the asset should be borrowable in isolation, false otherwise
-   */
-  function setBorrowableInIsolation(address asset, bool borrowable) external;
-
-  /**
-   * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
-   * swap interest rate, liquidate, atoken transfers).
-   * @param asset The address of the underlying asset of the reserve
-   * @param paused True if pausing the reserve, false if unpausing
-   */
-  function setReservePause(address asset, bool paused) external;
-
-  /**
-   * @notice Updates the reserve factor of a reserve.
-   * @param asset The address of the underlying asset of the reserve
-   * @param newReserveFactor The new reserve factor of the reserve
-   */
-  function setReserveFactor(address asset, uint256 newReserveFactor) external;
-
-  /**
-   * @notice Sets the interest rate strategy of a reserve.
-   * @param asset The address of the underlying asset of the reserve
-   * @param newRateStrategyAddress The address of the new interest strategy contract
-   */
-  function setReserveInterestRateStrategyAddress(
-    address asset,
-    address newRateStrategyAddress
-  ) external;
-
-  /**
-   * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
-   * are suspended.
-   * @param paused True if protocol needs to be paused, false otherwise
-   */
-  function setPoolPause(bool paused) external;
-
-  /**
-   * @notice Updates the borrow cap of a reserve.
-   * @param asset The address of the underlying asset of the reserve
-   * @param newBorrowCap The new borrow cap of the reserve
-   */
-  function setBorrowCap(address asset, uint256 newBorrowCap) external;
-
-  /**
-   * @notice Updates the supply cap of a reserve.
-   * @param asset The address of the underlying asset of the reserve
-   * @param newSupplyCap The new supply cap of the reserve
-   */
-  function setSupplyCap(address asset, uint256 newSupplyCap) external;
-
-  /**
-   * @notice Updates the liquidation protocol fee of reserve.
-   * @param asset The address of the underlying asset of the reserve
-   * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
-   */
-  function setLiquidationProtocolFee(address asset, uint256 newFee) external;
-
-  /**
-   * @notice Updates the unbacked mint cap of reserve.
-   * @param asset The address of the underlying asset of the reserve
-   * @param newUnbackedMintCap The new unbacked mint cap of the reserve
-   */
-  function setUnbackedMintCap(address asset, uint256 newUnbackedMintCap) external;
-
-  /**
-   * @notice Assign an efficiency mode (eMode) category to asset.
-   * @param asset The address of the underlying asset of the reserve
-   * @param newCategoryId The new category id of the asset
-   */
-  function setAssetEModeCategory(address asset, uint8 newCategoryId) external;
-
-  /**
-   * @notice Adds a new efficiency mode (eMode) category.
-   * @dev If zero is provided as oracle address, the default asset oracles will be used to compute the overall debt and
-   * overcollateralization of the users using this category.
-   * @dev The new ltv and liquidation threshold must be greater than the base
-   * ltvs and liquidation thresholds of all assets within the eMode category
-   * @param categoryId The id of the category to be configured
-   * @param ltv The ltv associated with the category
-   * @param liquidationThreshold The liquidation threshold associated with the category
-   * @param liquidationBonus The liquidation bonus associated with the category
-   * @param oracle The oracle associated with the category
-   * @param label A label identifying the category
-   */
-  function setEModeCategory(
-    uint8 categoryId,
-    uint16 ltv,
-    uint16 liquidationThreshold,
-    uint16 liquidationBonus,
-    address oracle,
-    string calldata label
-  ) external;
-
-  /**
-   * @notice Drops a reserve entirely.
-   * @param asset The address of the reserve to drop
-   */
-  function dropReserve(address asset) external;
-
-  /**
-   * @notice Updates the bridge fee collected by the protocol reserves.
-   * @param newBridgeProtocolFee The part of the fee sent to the protocol treasury, expressed in bps
-   */
-  function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external;
-
-  /**
-   * @notice Updates the total flash loan premium.
-   * Total flash loan premium consists of two parts:
-   * - A part is sent to aToken holders as extra balance
-   * - A part is collected by the protocol reserves
-   * @dev Expressed in bps
-   * @dev The premium is calculated on the total amount borrowed
-   * @param newFlashloanPremiumTotal The total flashloan premium
-   */
-  function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal) external;
-
-  /**
-   * @notice Updates the flash loan premium collected by protocol reserves
-   * @dev Expressed in bps
-   * @dev The premium to protocol is calculated on the total flashloan premium
-   * @param newFlashloanPremiumToProtocol The part of the flashloan premium sent to the protocol treasury
-   */
-  function updateFlashloanPremiumToProtocol(uint128 newFlashloanPremiumToProtocol) external;
-
-  /**
-   * @notice Sets the debt ceiling for an asset.
-   * @param newDebtCeiling The new debt ceiling
-   */
-  function setDebtCeiling(address asset, uint256 newDebtCeiling) external;
-
-  /**
-   * @notice Sets siloed borrowing for an asset
-   * @param siloed The new siloed borrowing state
-   */
-  function setSiloedBorrowing(address asset, bool siloed) external;
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol
-
-/**
- * @title IPoolDataProvider
- * @author Aave
- * @notice Defines the basic interface of a PoolDataProvider
- */
-interface IPoolDataProvider {
-  struct TokenData {
-    string symbol;
-    address tokenAddress;
-  }
-
-  /**
-   * @notice Returns the address for the PoolAddressesProvider contract.
-   * @return The address for the PoolAddressesProvider contract
-   */
-  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);
-
-  /**
-   * @notice Returns the list of the existing reserves in the pool.
-   * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
-   * @return The list of reserves, pairs of symbols and addresses
-   */
-  function getAllReservesTokens() external view returns (TokenData[] memory);
-
-  /**
-   * @notice Returns the list of the existing ATokens in the pool.
-   * @return The list of ATokens, pairs of symbols and addresses
-   */
-  function getAllATokens() external view returns (TokenData[] memory);
-
-  /**
-   * @notice Returns the configuration data of the reserve
-   * @dev Not returning borrow and supply caps for compatibility, nor pause flag
-   * @param asset The address of the underlying asset of the reserve
-   * @return decimals The number of decimals of the reserve
-   * @return ltv The ltv of the reserve
-   * @return liquidationThreshold The liquidationThreshold of the reserve
-   * @return liquidationBonus The liquidationBonus of the reserve
-   * @return reserveFactor The reserveFactor of the reserve
-   * @return usageAsCollateralEnabled True if the usage as collateral is enabled, false otherwise
-   * @return borrowingEnabled True if borrowing is enabled, false otherwise
-   * @return stableBorrowRateEnabled True if stable rate borrowing is enabled, false otherwise
-   * @return isActive True if it is active, false otherwise
-   * @return isFrozen True if it is frozen, false otherwise
-   */
-  function getReserveConfigurationData(
-    address asset
-  )
-    external
-    view
-    returns (
-      uint256 decimals,
-      uint256 ltv,
-      uint256 liquidationThreshold,
-      uint256 liquidationBonus,
-      uint256 reserveFactor,
-      bool usageAsCollateralEnabled,
-      bool borrowingEnabled,
-      bool stableBorrowRateEnabled,
-      bool isActive,
-      bool isFrozen
-    );
-
-  /**
-   * @notice Returns the efficiency mode category of the reserve
-   * @param asset The address of the underlying asset of the reserve
-   * @return The eMode id of the reserve
-   */
-  function getReserveEModeCategory(address asset) external view returns (uint256);
-
-  /**
-   * @notice Returns the caps parameters of the reserve
-   * @param asset The address of the underlying asset of the reserve
-   * @return borrowCap The borrow cap of the reserve
-   * @return supplyCap The supply cap of the reserve
-   */
-  function getReserveCaps(
-    address asset
-  ) external view returns (uint256 borrowCap, uint256 supplyCap);
-
-  /**
-   * @notice Returns if the pool is paused
-   * @param asset The address of the underlying asset of the reserve
-   * @return isPaused True if the pool is paused, false otherwise
-   */
-  function getPaused(address asset) external view returns (bool isPaused);
-
-  /**
-   * @notice Returns the siloed borrowing flag
-   * @param asset The address of the underlying asset of the reserve
-   * @return True if the asset is siloed for borrowing
-   */
-  function getSiloedBorrowing(address asset) external view returns (bool);
-
-  /**
-   * @notice Returns the protocol fee on the liquidation bonus
-   * @param asset The address of the underlying asset of the reserve
-   * @return The protocol fee on liquidation
-   */
-  function getLiquidationProtocolFee(address asset) external view returns (uint256);
-
-  /**
-   * @notice Returns the unbacked mint cap of the reserve
-   * @param asset The address of the underlying asset of the reserve
-   * @return The unbacked mint cap of the reserve
-   */
-  function getUnbackedMintCap(address asset) external view returns (uint256);
-
-  /**
-   * @notice Returns the debt ceiling of the reserve
-   * @param asset The address of the underlying asset of the reserve
-   * @return The debt ceiling of the reserve
-   */
-  function getDebtCeiling(address asset) external view returns (uint256);
-
-  /**
-   * @notice Returns the debt ceiling decimals
-   * @return The debt ceiling decimals
-   */
-  function getDebtCeilingDecimals() external pure returns (uint256);
-
-  /**
-   * @notice Returns the reserve data
-   * @param asset The address of the underlying asset of the reserve
-   * @return unbacked The amount of unbacked tokens
-   * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
-   * @return totalAToken The total supply of the aToken
-   * @return totalStableDebt The total stable debt of the reserve
-   * @return totalVariableDebt The total variable debt of the reserve
-   * @return liquidityRate The liquidity rate of the reserve
-   * @return variableBorrowRate The variable borrow rate of the reserve
-   * @return stableBorrowRate The stable borrow rate of the reserve
-   * @return averageStableBorrowRate The average stable borrow rate of the reserve
-   * @return liquidityIndex The liquidity index of the reserve
-   * @return variableBorrowIndex The variable borrow index of the reserve
-   * @return lastUpdateTimestamp The timestamp of the last update of the reserve
-   */
-  function getReserveData(
-    address asset
-  )
-    external
-    view
-    returns (
-      uint256 unbacked,
-      uint256 accruedToTreasuryScaled,
-      uint256 totalAToken,
-      uint256 totalStableDebt,
-      uint256 totalVariableDebt,
-      uint256 liquidityRate,
-      uint256 variableBorrowRate,
-      uint256 stableBorrowRate,
-      uint256 averageStableBorrowRate,
-      uint256 liquidityIndex,
-      uint256 variableBorrowIndex,
-      uint40 lastUpdateTimestamp
-    );
-
-  /**
-   * @notice Returns the total supply of aTokens for a given asset
-   * @param asset The address of the underlying asset of the reserve
-   * @return The total supply of the aToken
-   */
-  function getATokenTotalSupply(address asset) external view returns (uint256);
-
-  /**
-   * @notice Returns the total debt for a given asset
-   * @param asset The address of the underlying asset of the reserve
-   * @return The total debt for asset
-   */
-  function getTotalDebt(address asset) external view returns (uint256);
-
-  /**
-   * @notice Returns the user data in a reserve
-   * @param asset The address of the underlying asset of the reserve
-   * @param user The address of the user
-   * @return currentATokenBalance The current AToken balance of the user
-   * @return currentStableDebt The current stable debt of the user
-   * @return currentVariableDebt The current variable debt of the user
-   * @return principalStableDebt The principal stable debt of the user
-   * @return scaledVariableDebt The scaled variable debt of the user
-   * @return stableBorrowRate The stable borrow rate of the user
-   * @return liquidityRate The liquidity rate of the reserve
-   * @return stableRateLastUpdated The timestamp of the last update of the user stable rate
-   * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
-   *         otherwise
-   */
-  function getUserReserveData(
-    address asset,
-    address user
-  )
-    external
-    view
-    returns (
-      uint256 currentATokenBalance,
-      uint256 currentStableDebt,
-      uint256 currentVariableDebt,
-      uint256 principalStableDebt,
-      uint256 scaledVariableDebt,
-      uint256 stableBorrowRate,
-      uint256 liquidityRate,
-      uint40 stableRateLastUpdated,
-      bool usageAsCollateralEnabled
-    );
-
-  /**
-   * @notice Returns the token addresses of the reserve
-   * @param asset The address of the underlying asset of the reserve
-   * @return aTokenAddress The AToken address of the reserve
-   * @return stableDebtTokenAddress The StableDebtToken address of the reserve
-   * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
-   */
-  function getReserveTokensAddresses(
-    address asset
-  )
-    external
-    view
-    returns (
-      address aTokenAddress,
-      address stableDebtTokenAddress,
-      address variableDebtTokenAddress
-    );
-
-  /**
-   * @notice Returns the address of the Interest Rate strategy
-   * @param asset The address of the underlying asset of the reserve
-   * @return irStrategyAddress The address of the Interest Rate strategy
-   */
-  function getInterestRateStrategyAddress(
-    address asset
-  ) external view returns (address irStrategyAddress);
-
-  /**
-   * @notice Returns whether the reserve has FlashLoans enabled or disabled
-   * @param asset The address of the underlying asset of the reserve
-   * @return True if FlashLoans are enabled, false otherwise
-   */
-  function getFlashLoanEnabled(address asset) external view returns (bool);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IReserveInterestRateStrategy.sol
-
-/**
- * @title IReserveInterestRateStrategy
- * @author Aave
- * @notice Interface for the calculation of the interest rates
- */
-interface IReserveInterestRateStrategy {
-  /**
-   * @notice Calculates the interest rates depending on the reserve's state and configurations
-   * @param params The parameters needed to calculate interest rates
-   * @return liquidityRate The liquidity rate expressed in rays
-   * @return stableBorrowRate The stable borrow rate expressed in rays
-   * @return variableBorrowRate The variable borrow rate expressed in rays
-   */
-  function calculateInterestRates(
-    DataTypes.CalculateInterestRatesParams memory params
-  ) external view returns (uint256, uint256, uint256);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/protocol/libraries/math/MathUtils.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/core/contracts/protocol/libraries/math/MathUtils.sol
 
 /**
  * @title MathUtils library
@@ -4349,89 +3259,212 @@ library MathUtils {
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/Ownable.sol
-
-// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
-// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a
-
-/**
- * @dev Contract module which provides a basic access control mechanism, where
- * there is an account (an owner) that can be granted exclusive access to
- * specific functions.
- *
- * By default, the owner account will be the one that deploys the contract. This
- * can later be changed with {transferOwnership}.
- *
- * This module is used through inheritance. It will make available the modifier
- * `onlyOwner`, which can be applied to your functions to restrict their use to
- * the owner.
- */
-abstract contract Ownable is Context {
-  address private _owner;
-
-  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/dependencies/solmate/ERC20.sol
 
-  /**
-   * @dev Initializes the contract setting the deployer as the initial owner.
-   */
-  constructor() {
-    _transferOwnership(_msgSender());
+/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
+/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
+/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
+/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
+abstract contract ERC20 {
+  bytes32 public constant PERMIT_TYPEHASH =
+    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
+
+  /* //////////////////////////////////////////////////////////////
+                        EVENTS
+  ////////////////////////////////////////////////////////////// */
+
+  event Transfer(address indexed from, address indexed to, uint256 amount);
+
+  event Approval(address indexed owner, address indexed spender, uint256 amount);
+
+  /* //////////////////////////////////////////////////////////////
+                        METADATA STORAGE
+  ////////////////////////////////////////////////////////////// */
+
+  string public name;
+
+  string public symbol;
+
+  uint8 public decimals;
+
+  /* //////////////////////////////////////////////////////////////
+                        ERC20 STORAGE
+  ////////////////////////////////////////////////////////////// */
+
+  uint256 public totalSupply;
+
+  mapping(address => uint256) public balanceOf;
+
+  mapping(address => mapping(address => uint256)) public allowance;
+
+  /* //////////////////////////////////////////////////////////////
+                        EIP-2612 STORAGE
+  ////////////////////////////////////////////////////////////// */
+
+  mapping(address => uint256) public nonces;
+
+  /* //////////////////////////////////////////////////////////////
+                        CONSTRUCTOR
+  ////////////////////////////////////////////////////////////// */
+
+  constructor(string memory _name, string memory _symbol, uint8 _decimals) {
+    name = _name;
+    symbol = _symbol;
+    decimals = _decimals;
   }
 
-  /**
-   * @dev Throws if called by any account other than the owner.
-   */
-  modifier onlyOwner() {
-    _checkOwner();
-    _;
+  /* //////////////////////////////////////////////////////////////
+                        ERC20 LOGIC
+  ////////////////////////////////////////////////////////////// */
+
+  function approve(address spender, uint256 amount) public virtual returns (bool) {
+    allowance[msg.sender][spender] = amount;
+
+    emit Approval(msg.sender, spender, amount);
+
+    return true;
   }
 
-  /**
-   * @dev Returns the address of the current owner.
-   */
-  function owner() public view virtual returns (address) {
-    return _owner;
+  function transfer(address to, uint256 amount) public virtual returns (bool) {
+    _beforeTokenTransfer(msg.sender, to, amount);
+    balanceOf[msg.sender] -= amount;
+
+    // Cannot overflow because the sum of all user
+    // balances can't exceed the max uint256 value.
+    unchecked {
+      balanceOf[to] += amount;
+    }
+
+    emit Transfer(msg.sender, to, amount);
+
+    return true;
   }
 
-  /**
-   * @dev Throws if the sender is not the owner.
-   */
-  function _checkOwner() internal view virtual {
-    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
+  function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
+    _beforeTokenTransfer(from, to, amount);
+    uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
+
+    if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
+
+    balanceOf[from] -= amount;
+
+    // Cannot overflow because the sum of all user
+    // balances can't exceed the max uint256 value.
+    unchecked {
+      balanceOf[to] += amount;
+    }
+
+    emit Transfer(from, to, amount);
+
+    return true;
   }
 
-  /**
-   * @dev Leaves the contract without owner. It will not be possible to call
-   * `onlyOwner` functions anymore. Can only be called by the current owner.
-   *
-   * NOTE: Renouncing ownership will leave the contract without an owner,
-   * thereby removing any functionality that is only available to the owner.
-   */
-  function renounceOwnership() public virtual onlyOwner {
-    _transferOwnership(address(0));
+  /* //////////////////////////////////////////////////////////////
+                          EIP-2612 LOGIC
+  ////////////////////////////////////////////////////////////// */
+
+  function permit(
+    address owner,
+    address spender,
+    uint256 value,
+    uint256 deadline,
+    uint8 v,
+    bytes32 r,
+    bytes32 s
+  ) public virtual {
+    require(deadline >= block.timestamp, 'PERMIT_DEADLINE_EXPIRED');
+
+    // Unchecked because the only math done is incrementing
+    // the owner's nonce which cannot realistically overflow.
+    unchecked {
+      address signer = ECDSA.recover(
+        keccak256(
+          abi.encodePacked(
+            '\x19\x01',
+            DOMAIN_SEPARATOR(),
+            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
+          )
+        ),
+        v,
+        r,
+        s
+      );
+
+      require(signer == owner, 'INVALID_SIGNER');
+
+      allowance[signer][spender] = value;
+    }
+
+    emit Approval(owner, spender, value);
   }
 
-  /**
-   * @dev Transfers ownership of the contract to a new account (`newOwner`).
-   * Can only be called by the current owner.
-   */
-  function transferOwnership(address newOwner) public virtual onlyOwner {
-    require(newOwner != address(0), 'Ownable: new owner is the zero address');
-    _transferOwnership(newOwner);
+  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
+    return computeDomainSeparator();
+  }
+
+  function computeDomainSeparator() internal view virtual returns (bytes32) {
+    return
+      keccak256(
+        abi.encode(
+          keccak256(
+            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
+          ),
+          keccak256(bytes(name)),
+          keccak256('1'),
+          block.chainid,
+          address(this)
+        )
+      );
+  }
+
+  /* //////////////////////////////////////////////////////////////
+                            INTERNAL MINT/BURN LOGIC
+  ////////////////////////////////////////////////////////////// */
+
+  function _mint(address to, uint256 amount) internal virtual {
+    _beforeTokenTransfer(address(0), to, amount);
+    totalSupply += amount;
+
+    // Cannot overflow because the sum of all user
+    // balances can't exceed the max uint256 value.
+    unchecked {
+      balanceOf[to] += amount;
+    }
+
+    emit Transfer(address(0), to, amount);
+  }
+
+  function _burn(address from, uint256 amount) internal virtual {
+    _beforeTokenTransfer(from, address(0), amount);
+    balanceOf[from] -= amount;
+
+    // Cannot underflow because a user's balance
+    // will never be larger than the total supply.
+    unchecked {
+      totalSupply -= amount;
+    }
+
+    emit Transfer(from, address(0), amount);
   }
 
   /**
-   * @dev Transfers ownership of the contract to a new account (`newOwner`).
-   * Internal function without access restriction.
+   * @dev Hook that is called before any transfer of tokens. This includes
+   * minting and burning.
+   *
+   * Calling conditions:
+   *
+   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
+   * will be to transferred to `to`.
+   * - when `from` is zero, `amount` tokens will be minted for `to`.
+   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
+   * - `from` and `to` are never both zero.
+   *
+   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    */
-  function _transferOwnership(address newOwner) internal virtual {
-    address oldOwner = _owner;
-    _owner = newOwner;
-    emit OwnershipTransferred(oldOwner, newOwner);
-  }
+  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20Metadata.sol
+// lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20Metadata.sol
 
 // OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
 // From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/6bd6b76d1156e20e45d1016f355d154141c7e5b9
@@ -4458,7 +3491,7 @@ interface IERC20Metadata is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/transparent-proxy/Initializable.sol
+// lib/solidity-utils/src/contracts/transparent-proxy/Initializable.sol
 
 /**
  * @dev OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)
@@ -4612,296 +3645,7 @@ abstract contract Initializable {
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/ERC20.sol
-
-/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
-/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
-/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
-/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
-abstract contract ERC20 {
-  bytes32 public constant PERMIT_TYPEHASH =
-    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
-
-  /* //////////////////////////////////////////////////////////////
-                        EVENTS
-  ////////////////////////////////////////////////////////////// */
-
-  event Transfer(address indexed from, address indexed to, uint256 amount);
-
-  event Approval(address indexed owner, address indexed spender, uint256 amount);
-
-  /* //////////////////////////////////////////////////////////////
-                        METADATA STORAGE
-  ////////////////////////////////////////////////////////////// */
-
-  string public name;
-
-  string public symbol;
-
-  uint8 public decimals;
-
-  /* //////////////////////////////////////////////////////////////
-                        ERC20 STORAGE
-  ////////////////////////////////////////////////////////////// */
-
-  uint256 public totalSupply;
-
-  mapping(address => uint256) public balanceOf;
-
-  mapping(address => mapping(address => uint256)) public allowance;
-
-  /* //////////////////////////////////////////////////////////////
-                        EIP-2612 STORAGE
-  ////////////////////////////////////////////////////////////// */
-
-  mapping(address => uint256) public nonces;
-
-  /* //////////////////////////////////////////////////////////////
-                        CONSTRUCTOR
-  ////////////////////////////////////////////////////////////// */
-
-  constructor(string memory _name, string memory _symbol, uint8 _decimals) {
-    name = _name;
-    symbol = _symbol;
-    decimals = _decimals;
-  }
-
-  /* //////////////////////////////////////////////////////////////
-                        ERC20 LOGIC
-  ////////////////////////////////////////////////////////////// */
-
-  function approve(address spender, uint256 amount) public virtual returns (bool) {
-    allowance[msg.sender][spender] = amount;
-
-    emit Approval(msg.sender, spender, amount);
-
-    return true;
-  }
-
-  function transfer(address to, uint256 amount) public virtual returns (bool) {
-    _beforeTokenTransfer(msg.sender, to, amount);
-    balanceOf[msg.sender] -= amount;
-
-    // Cannot overflow because the sum of all user
-    // balances can't exceed the max uint256 value.
-    unchecked {
-      balanceOf[to] += amount;
-    }
-
-    emit Transfer(msg.sender, to, amount);
-
-    return true;
-  }
-
-  function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
-    _beforeTokenTransfer(from, to, amount);
-    uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
-
-    if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
-
-    balanceOf[from] -= amount;
-
-    // Cannot overflow because the sum of all user
-    // balances can't exceed the max uint256 value.
-    unchecked {
-      balanceOf[to] += amount;
-    }
-
-    emit Transfer(from, to, amount);
-
-    return true;
-  }
-
-  /* //////////////////////////////////////////////////////////////
-                          EIP-2612 LOGIC
-  ////////////////////////////////////////////////////////////// */
-
-  function permit(
-    address owner,
-    address spender,
-    uint256 value,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) public virtual {
-    require(deadline >= block.timestamp, 'PERMIT_DEADLINE_EXPIRED');
-
-    // Unchecked because the only math done is incrementing
-    // the owner's nonce which cannot realistically overflow.
-    unchecked {
-      address signer = ECDSA.recover(
-        keccak256(
-          abi.encodePacked(
-            '\x19\x01',
-            DOMAIN_SEPARATOR(),
-            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
-          )
-        ),
-        v,
-        r,
-        s
-      );
-
-      require(signer == owner, 'INVALID_SIGNER');
-
-      allowance[signer][spender] = value;
-    }
-
-    emit Approval(owner, spender, value);
-  }
-
-  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
-    return computeDomainSeparator();
-  }
-
-  function computeDomainSeparator() internal view virtual returns (bytes32) {
-    return
-      keccak256(
-        abi.encode(
-          keccak256(
-            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
-          ),
-          keccak256(bytes(name)),
-          keccak256('1'),
-          block.chainid,
-          address(this)
-        )
-      );
-  }
-
-  /* //////////////////////////////////////////////////////////////
-                            INTERNAL MINT/BURN LOGIC
-  ////////////////////////////////////////////////////////////// */
-
-  function _mint(address to, uint256 amount) internal virtual {
-    _beforeTokenTransfer(address(0), to, amount);
-    totalSupply += amount;
-
-    // Cannot overflow because the sum of all user
-    // balances can't exceed the max uint256 value.
-    unchecked {
-      balanceOf[to] += amount;
-    }
-
-    emit Transfer(address(0), to, amount);
-  }
-
-  function _burn(address from, uint256 amount) internal virtual {
-    _beforeTokenTransfer(from, address(0), amount);
-    balanceOf[from] -= amount;
-
-    // Cannot underflow because a user's balance
-    // will never be larger than the total supply.
-    unchecked {
-      totalSupply -= amount;
-    }
-
-    emit Transfer(from, address(0), amount);
-  }
-
-  /**
-   * @dev Hook that is called before any transfer of tokens. This includes
-   * minting and burning.
-   *
-   * Calling conditions:
-   *
-   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
-   * will be to transferred to `to`.
-   * - when `from` is zero, `amount` tokens will be minted for `to`.
-   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
-   * - `from` and `to` are never both zero.
-   *
-   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
-   */
-  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/interfaces/IAToken.sol
-
-interface IAToken {
-  function POOL() external view returns (address);
-
-  function getIncentivesController() external view returns (address);
-
-  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
-
-  /**
-   * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
-   * @return The scaled total supply
-   */
-  function scaledTotalSupply() external view returns (uint256);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IAaveOracle.sol
-
-/**
- * @title IAaveOracle
- * @author Aave
- * @notice Defines the basic interface for the Aave Oracle
- */
-interface IAaveOracle is IPriceOracleGetter {
-  /**
-   * @dev Emitted after the base currency is set
-   * @param baseCurrency The base currency of used for price quotes
-   * @param baseCurrencyUnit The unit of the base currency
-   */
-  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);
-
-  /**
-   * @dev Emitted after the price source of an asset is updated
-   * @param asset The address of the asset
-   * @param source The price source of the asset
-   */
-  event AssetSourceUpdated(address indexed asset, address indexed source);
-
-  /**
-   * @dev Emitted after the address of fallback oracle is updated
-   * @param fallbackOracle The address of the fallback oracle
-   */
-  event FallbackOracleUpdated(address indexed fallbackOracle);
-
-  /**
-   * @notice Returns the PoolAddressesProvider
-   * @return The address of the PoolAddressesProvider contract
-   */
-  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);
-
-  /**
-   * @notice Sets or replaces price sources of assets
-   * @param assets The addresses of the assets
-   * @param sources The addresses of the price sources
-   */
-  function setAssetSources(address[] calldata assets, address[] calldata sources) external;
-
-  /**
-   * @notice Sets the fallback oracle
-   * @param fallbackOracle The address of the fallback oracle
-   */
-  function setFallbackOracle(address fallbackOracle) external;
-
-  /**
-   * @notice Returns a list of prices from a list of assets addresses
-   * @param assets The list of assets addresses
-   * @return The prices of the given assets
-   */
-  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
-
-  /**
-   * @notice Returns the address of the source for an asset address
-   * @param asset The address of the asset
-   * @return The address of the source
-   */
-  function getSourceOfAsset(address asset) external view returns (address);
-
-  /**
-   * @notice Returns the address of the fallback oracle
-   * @return The address of the fallback oracle
-   */
-  function getFallbackOracle() external view returns (address);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IPool.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -5279,6 +4023,14 @@ interface IPool {
    */
   function swapBorrowRateMode(address asset, uint256 interestRateMode) external;
 
+  /**
+   * @notice Permissionless method which allows anyone to swap a users stable debt to variable debt
+   * @dev Introduced in favor of stable rate deprecation
+   * @param asset The address of the underlying asset borrowed
+   * @param user The address of the user whose debt will be swapped from stable to variable
+   */
+  function swapToVariable(address asset, address user) external;
+
   /**
    * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
    * - Users can be rebalanced if the following conditions are satisfied:
@@ -5423,6 +4175,22 @@ interface IPool {
     address rateStrategyAddress
   ) external;
 
+  /**
+   * @notice Accumulates interest to all indexes of the reserve
+   * @dev Only callable by the PoolConfigurator contract
+   * @dev To be used when required by the configurator, for example when updating interest rates strategy data
+   * @param asset The address of the underlying asset of the reserve
+   */
+  function syncIndexesState(address asset) external;
+
+  /**
+   * @notice Updates interest rates on the reserve data
+   * @dev Only callable by the PoolConfigurator contract
+   * @dev To be used when required by the configurator, for example when updating interest rates strategy data
+   * @param asset The address of the underlying asset of the reserve
+   */
+  function syncRatesState(address asset) external;
+
   /**
    * @notice Sets the configuration bitmap of the reserve as a whole
    * @dev Only callable by the PoolConfigurator contract
@@ -5478,7 +4246,23 @@ interface IPool {
    * @param asset The address of the underlying asset of the reserve
    * @return The state and configuration data of the reserve
    */
-  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
+  function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory);
+
+  /**
+   * @notice Returns the state and configuration of the reserve, including extra data included with Aave v3.1
+   * @param asset The address of the underlying asset of the reserve
+   * @return The state and configuration data of the reserve with virtual accounting
+   */
+  function getReserveDataExtended(
+    address asset
+  ) external view returns (DataTypes.ReserveData memory);
+
+  /**
+   * @notice Returns the virtual underlying balance of the reserve
+   * @param asset The address of the underlying asset of the reserve
+   * @return The reserve virtual underlying balance
+   */
+  function getVirtualUnderlyingBalance(address asset) external view returns (uint128);
 
   /**
    * @notice Validates and finalizes an aToken transfer
@@ -5506,6 +4290,13 @@ interface IPool {
    */
   function getReservesList() external view returns (address[] memory);
 
+  /**
+   * @notice Returns the number of initialized reserves
+   * @dev It includes dropped reserves
+   * @return The count
+   */
+  function getReservesCount() external view returns (uint256);
+
   /**
    * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
    * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
@@ -5576,6 +4367,22 @@ interface IPool {
    */
   function resetIsolationModeTotalDebt(address asset) external;
 
+  /**
+   * @notice Sets the liquidation grace period of the given asset
+   * @dev To enable a liquidation grace period, a timestamp in the future should be set,
+   *      To disable a liquidation grace period, any timestamp in the past works, like 0
+   * @param asset The address of the underlying asset to set the liquidationGracePeriod
+   * @param until Timestamp when the liquidation grace period will end
+   **/
+  function setLiquidationGracePeriod(address asset, uint40 until) external;
+
+  /**
+   * @notice Returns the liquidation grace period of the given asset
+   * @param asset The address of the underlying asset
+   * @return Timestamp when the liquidation grace period will end
+   **/
+  function getLiquidationGracePeriod(address asset) external returns (uint40);
+
   /**
    * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
    * @return The percentage of available liquidity to borrow, expressed in bps
@@ -5633,9 +4440,44 @@ interface IPool {
    *   0 if the action is executed directly by the user, without any middle-man
    */
   function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
+
+  /**
+   * @notice Gets the address of the external FlashLoanLogic
+   */
+  function getFlashLoanLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external BorrowLogic
+   */
+  function getBorrowLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external BridgeLogic
+   */
+  function getBridgeLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external EModeLogic
+   */
+  function getEModeLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external LiquidationLogic
+   */
+  function getLiquidationLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external PoolLogic
+   */
+  function getPoolLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external SupplyLogic
+   */
+  function getSupplyLogic() external view returns (address);
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -5662,6 +4504,7 @@ library ReserveConfiguration {
   uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
   uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
   uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
+  uint256 internal constant VIRTUAL_ACC_ACTIVE_MASK =        0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
 
   /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
   uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
@@ -5682,6 +4525,7 @@ library ReserveConfiguration {
   uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
   uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
   uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;
+  uint256 internal constant VIRTUAL_ACC_START_BIT_POSITION = 252;
 
   uint256 internal constant MAX_VALID_LTV = 65535;
   uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
@@ -6177,6 +5021,33 @@ library ReserveConfiguration {
     return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
   }
 
+  /**
+   * @notice Sets the virtual account active/not state of the reserve
+   * @param self The reserve configuration
+   * @param active The active state
+   */
+  function setVirtualAccActive(
+    DataTypes.ReserveConfigurationMap memory self,
+    bool active
+  ) internal pure {
+    self.data =
+      (self.data & VIRTUAL_ACC_ACTIVE_MASK) |
+      (uint256(active ? 1 : 0) << VIRTUAL_ACC_START_BIT_POSITION);
+  }
+
+  /**
+   * @notice Gets the virtual account active/not state of the reserve
+   * @dev The state should be true for all normal assets and should be false
+   *  only in special cases (ex. GHO) where an asset is minted instead of supplied.
+   * @param self The reserve configuration
+   * @return The active state
+   */
+  function getIsVirtualAccActive(
+    DataTypes.ReserveConfigurationMap memory self
+  ) internal pure returns (bool) {
+    return (self.data & ~VIRTUAL_ACC_ACTIVE_MASK) != 0;
+  }
+
   /**
    * @notice Gets the configuration flags of the reserve
    * @param self The reserve configuration
@@ -6243,11 +5114,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20WithPermit.sol
-
-interface IERC20WithPermit is IERC20, IERC20Permit {}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-v3-periphery/contracts/rewards/libraries/RewardsDataTypes.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
 
 library RewardsDataTypes {
   struct RewardsConfigInput {
@@ -6298,101 +5165,11 @@ library RewardsDataTypes {
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol
+// lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20WithPermit.sol
 
-/**
- * @title IDefaultInterestRateStrategy
- * @author Aave
- * @notice Defines the basic interface of the DefaultReserveInterestRateStrategy
- */
-interface IDefaultInterestRateStrategy is IReserveInterestRateStrategy {
-  /**
-   * @notice Returns the usage ratio at which the pool aims to obtain most competitive borrow rates.
-   * @return The optimal usage ratio, expressed in ray.
-   */
-  function OPTIMAL_USAGE_RATIO() external view returns (uint256);
+interface IERC20WithPermit is IERC20, IERC20Permit {}
 
-  /**
-   * @notice Returns the optimal stable to total debt ratio of the reserve.
-   * @return The optimal stable to total debt ratio, expressed in ray.
-   */
-  function OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);
-
-  /**
-   * @notice Returns the excess usage ratio above the optimal.
-   * @dev It's always equal to 1-optimal usage ratio (added as constant for gas optimizations)
-   * @return The max excess usage ratio, expressed in ray.
-   */
-  function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);
-
-  /**
-   * @notice Returns the excess stable debt ratio above the optimal.
-   * @dev It's always equal to 1-optimal stable to total debt ratio (added as constant for gas optimizations)
-   * @return The max excess stable to total debt ratio, expressed in ray.
-   */
-  function MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);
-
-  /**
-   * @notice Returns the address of the PoolAddressesProvider
-   * @return The address of the PoolAddressesProvider contract
-   */
-  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);
-
-  /**
-   * @notice Returns the variable rate slope below optimal usage ratio
-   * @dev It's the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
-   * @return The variable rate slope, expressed in ray
-   */
-  function getVariableRateSlope1() external view returns (uint256);
-
-  /**
-   * @notice Returns the variable rate slope above optimal usage ratio
-   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
-   * @return The variable rate slope, expressed in ray
-   */
-  function getVariableRateSlope2() external view returns (uint256);
-
-  /**
-   * @notice Returns the stable rate slope below optimal usage ratio
-   * @dev It's the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
-   * @return The stable rate slope, expressed in ray
-   */
-  function getStableRateSlope1() external view returns (uint256);
-
-  /**
-   * @notice Returns the stable rate slope above optimal usage ratio
-   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
-   * @return The stable rate slope, expressed in ray
-   */
-  function getStableRateSlope2() external view returns (uint256);
-
-  /**
-   * @notice Returns the stable rate excess offset
-   * @dev It's an additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
-   * @return The stable rate excess offset, expressed in ray
-   */
-  function getStableRateExcessOffset() external view returns (uint256);
-
-  /**
-   * @notice Returns the base stable borrow rate
-   * @return The base stable borrow rate, expressed in ray
-   */
-  function getBaseStableBorrowRate() external view returns (uint256);
-
-  /**
-   * @notice Returns the base variable borrow rate
-   * @return The base variable borrow rate, expressed in ray
-   */
-  function getBaseVariableBorrowRate() external view returns (uint256);
-
-  /**
-   * @notice Returns the maximum variable borrow rate
-   * @return The maximum variable borrow rate, expressed in ray
-   */
-  function getMaxVariableBorrowRate() external view returns (uint256);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/SafeERC20.sol
+// lib/solidity-utils/src/contracts/oz-common/SafeERC20.sol
 
 // OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)
 // Modified From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/00cbf5a236564c3b7aacdad1f378cae22d890ca6
@@ -6540,60 +5317,7 @@ library SafeERC20 {
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IInitializableAToken.sol
-
-/**
- * @title IInitializableAToken
- * @author Aave
- * @notice Interface for the initialize function on AToken
- */
-interface IInitializableAToken {
-  /**
-   * @dev Emitted when an aToken is initialized
-   * @param underlyingAsset The address of the underlying asset
-   * @param pool The address of the associated pool
-   * @param treasury The address of the treasury
-   * @param incentivesController The address of the incentives controller for this aToken
-   * @param aTokenDecimals The decimals of the underlying
-   * @param aTokenName The name of the aToken
-   * @param aTokenSymbol The symbol of the aToken
-   * @param params A set of encoded parameters for additional initialization
-   */
-  event Initialized(
-    address indexed underlyingAsset,
-    address indexed pool,
-    address treasury,
-    address incentivesController,
-    uint8 aTokenDecimals,
-    string aTokenName,
-    string aTokenSymbol,
-    bytes params
-  );
-
-  /**
-   * @notice Initializes the aToken
-   * @param pool The pool contract that is initializing this contract
-   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
-   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
-   * @param incentivesController The smart contract managing potential incentives distribution
-   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
-   * @param aTokenName The name of the aToken
-   * @param aTokenSymbol The symbol of the aToken
-   * @param params A set of encoded parameters for additional initialization
-   */
-  function initialize(
-    IPool pool,
-    address treasury,
-    address underlyingAsset,
-    IAaveIncentivesController incentivesController,
-    uint8 aTokenDecimals,
-    string calldata aTokenName,
-    string calldata aTokenSymbol,
-    bytes calldata params
-  ) external;
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-v3-periphery/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
 
 /**
  * @title IRewardsController
@@ -6791,7 +5515,7 @@ interface IRewardsController is IRewardsDistributor {
   ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/interfaces/IInitializableStaticATokenLM.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/interfaces/IInitializableStaticATokenLM.sol
 
 /**
  * @title IInitializableStaticATokenLM
@@ -6820,7 +5544,7 @@ interface IInitializableStaticATokenLM {
   ) external;
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/interfaces/IStaticATokenLM.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/interfaces/IStaticATokenLM.sol
 
 interface IStaticATokenLM is IInitializableStaticATokenLM {
   struct SignatureParams {
@@ -7031,181 +5755,7 @@ interface IStaticATokenLM is IInitializableStaticATokenLM {
   function isRegisteredRewardToken(address reward) external view returns (bool);
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IAToken.sol
-
-/**
- * @title IAToken
- * @author Aave
- * @notice Defines the basic interface for an AToken.
- */
-interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
-  /**
-   * @dev Emitted during the transfer action
-   * @param from The user whose tokens are being transferred
-   * @param to The recipient
-   * @param value The scaled amount being transferred
-   * @param index The next liquidity index of the reserve
-   */
-  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);
-
-  /**
-   * @notice Mints `amount` aTokens to `user`
-   * @param caller The address performing the mint
-   * @param onBehalfOf The address of the user that will receive the minted aTokens
-   * @param amount The amount of tokens getting minted
-   * @param index The next liquidity index of the reserve
-   * @return `true` if the the previous balance of the user was 0
-   */
-  function mint(
-    address caller,
-    address onBehalfOf,
-    uint256 amount,
-    uint256 index
-  ) external returns (bool);
-
-  /**
-   * @notice Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
-   * @dev In some instances, the mint event could be emitted from a burn transaction
-   * if the amount to burn is less than the interest that the user accrued
-   * @param from The address from which the aTokens will be burned
-   * @param receiverOfUnderlying The address that will receive the underlying
-   * @param amount The amount being burned
-   * @param index The next liquidity index of the reserve
-   */
-  function burn(address from, address receiverOfUnderlying, uint256 amount, uint256 index) external;
-
-  /**
-   * @notice Mints aTokens to the reserve treasury
-   * @param amount The amount of tokens getting minted
-   * @param index The next liquidity index of the reserve
-   */
-  function mintToTreasury(uint256 amount, uint256 index) external;
-
-  /**
-   * @notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
-   * @param from The address getting liquidated, current owner of the aTokens
-   * @param to The recipient
-   * @param value The amount of tokens getting transferred
-   */
-  function transferOnLiquidation(address from, address to, uint256 value) external;
-
-  /**
-   * @notice Transfers the underlying asset to `target`.
-   * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
-   * @param target The recipient of the underlying
-   * @param amount The amount getting transferred
-   */
-  function transferUnderlyingTo(address target, uint256 amount) external;
-
-  /**
-   * @notice Handles the underlying received by the aToken after the transfer has been completed.
-   * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
-   * transfer is concluded. However in the future there may be aTokens that allow for example to stake the underlying
-   * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
-   * @param user The user executing the repayment
-   * @param onBehalfOf The address of the user who will get his debt reduced/removed
-   * @param amount The amount getting repaid
-   */
-  function handleRepayment(address user, address onBehalfOf, uint256 amount) external;
-
-  /**
-   * @notice Allow passing a signed message to approve spending
-   * @dev implements the permit function as for
-   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
-   * @param owner The owner of the funds
-   * @param spender The spender
-   * @param value The amount
-   * @param deadline The deadline timestamp, type(uint256).max for max deadline
-   * @param v Signature param
-   * @param s Signature param
-   * @param r Signature param
-   */
-  function permit(
-    address owner,
-    address spender,
-    uint256 value,
-    uint256 deadline,
-    uint8 v,
-    bytes32 r,
-    bytes32 s
-  ) external;
-
-  /**
-   * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
-   * @return The address of the underlying asset
-   */
-  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
-
-  /**
-   * @notice Returns the address of the Aave treasury, receiving the fees on this aToken.
-   * @return Address of the Aave treasury
-   */
-  function RESERVE_TREASURY_ADDRESS() external view returns (address);
-
-  /**
-   * @notice Get the domain separator for the token
-   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
-   * @return The domain separator of the token at current chain
-   */
-  function DOMAIN_SEPARATOR() external view returns (bytes32);
-
-  /**
-   * @notice Returns the nonce for owner.
-   * @param owner The address of the owner
-   * @return The nonce of the owner
-   */
-  function nonces(address owner) external view returns (uint256);
-
-  /**
-   * @notice Rescue and transfer tokens locked in this contract
-   * @param token The address of the token
-   * @param to The address of the recipient
-   * @param amount The amount of token to transfer
-   */
-  function rescueTokens(address token, address to, uint256 amount) external;
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/lib/aave-helpers/lib/aave-address-book/src/AaveV3.sol
-
-interface IACLManager is IACLManager {
-  function hasRole(bytes32 role, address account) external view returns (bool);
-
-  function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);
-
-  function renounceRole(bytes32 role, address account) external;
-
-  function getRoleAdmin(bytes32 role) external view returns (bytes32);
-
-  function grantRole(bytes32 role, address account) external;
-
-  function revokeRole(bytes32 role, address account) external;
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/interfaces/IStaticATokenFactory.sol
-
-interface IStaticATokenFactory {
-  /**
-   * @notice Creates new staticATokens
-   * @param underlyings the addresses of the underlyings to create.
-   * @return address[] addresses of the new staticATokens.
-   */
-  function createStaticATokens(address[] memory underlyings) external returns (address[] memory);
-
-  /**
-   * @notice Returns all tokens deployed via this registry.
-   * @return address[] list of tokens
-   */
-  function getStaticATokens() external view returns (address[] memory);
-
-  /**
-   * @notice Returns the staticAToken for a given underlying.
-   * @param underlying the address of the underlying.
-   * @return address the staticAToken address.
-   */
-  function getStaticAToken(address underlying) external view returns (address);
-}
-
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/StaticATokenLM.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/StaticATokenLM.sol
 
 /**
  * @title StaticATokenLM
@@ -7540,7 +6090,7 @@ contract StaticATokenLM is
   ///@inheritdoc IERC4626
   function maxRedeem(address owner) public view virtual returns (uint256) {
     address cachedATokenUnderlying = _aTokenUnderlying;
-    DataTypes.ReserveData memory reserveData = POOL.getReserveData(cachedATokenUnderlying);
+    DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(cachedATokenUnderlying);
 
     // if paused or inactive users cannot withdraw underlying
     if (
@@ -7564,7 +6114,7 @@ contract StaticATokenLM is
 
   ///@inheritdoc IERC4626
   function maxDeposit(address) public view virtual returns (uint256) {
-    DataTypes.ReserveData memory reserveData = POOL.getReserveData(_aTokenUnderlying);
+    DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(_aTokenUnderlying);
 
     // if inactive, paused or frozen users cannot deposit underlying
     if (
@@ -7880,7 +6430,7 @@ contract StaticATokenLM is
    * @return The normalized income, expressed in ray
    */
   function _getNormalizedIncome(
-    DataTypes.ReserveData memory reserve
+    DataTypes.ReserveDataLegacy memory reserve
   ) internal view returns (uint256) {
     uint40 timestamp = reserve.lastUpdateTimestamp;
 
@@ -7897,7 +6447,7 @@ contract StaticATokenLM is
   }
 }
 
-// downloads/GNOSIS/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/StaticATokenFactory.sol
+// downloads/ZKSYNC/STATIC_A_TOKEN_FACTORY_IMPL/StaticATokenFactory/src/periphery/contracts/static-a-token/StaticATokenFactory.sol
 
 /**
  * @title StaticATokenFactory
@@ -7937,7 +6487,7 @@ contract StaticATokenFactory is Initializable, IStaticATokenFactory {
     for (uint256 i = 0; i < underlyings.length; i++) {
       address cachedStaticAToken = _underlyingToStaticAToken[underlyings[i]];
       if (cachedStaticAToken == address(0)) {
-        DataTypes.ReserveData memory reserveData = POOL.getReserveData(underlyings[i]);
+        DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(underlyings[i]);
         require(reserveData.aTokenAddress != address(0), 'UNDERLYING_NOT_LISTED');
         bytes memory symbol = abi.encodePacked(
           'stat',
```
