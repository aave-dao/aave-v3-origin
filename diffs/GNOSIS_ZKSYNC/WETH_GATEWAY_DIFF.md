```diff
diff --git a/./downloads/GNOSIS/WETH_GATEWAY.sol b/./downloads/ZKSYNC/WETH_GATEWAY.sol
index d3ffe34..c07f0ff 100644
--- a/./downloads/GNOSIS/WETH_GATEWAY.sol
+++ b/./downloads/ZKSYNC/WETH_GATEWAY.sol
@@ -1,7 +1,39 @@
-// SPDX-License-Identifier: AGPL-3.0
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/WETH_GATEWAY/WrappedTokenGatewayV3/src/periphery/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol
+
+interface IWrappedTokenGatewayV3 {
+  function depositETH(address pool, address onBehalfOf, uint16 referralCode) external payable;
+
+  function withdrawETH(address pool, uint256 amount, address onBehalfOf) external;
+
+  function repayETH(
+    address pool,
+    uint256 amount,
+    uint256 rateMode,
+    address onBehalfOf
+  ) external payable;
+
+  function borrowETH(
+    address pool,
+    uint256 amount,
+    uint256 interestRateMode,
+    uint16 referralCode
+  ) external;
+
+  function withdrawETHWithPermit(
+    address pool,
+    uint256 amount,
+    address to,
+    uint256 deadline,
+    uint8 permitV,
+    bytes32 permitR,
+    bytes32 permitS
+  ) external;
+}
+
+// src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +56,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -100,7 +132,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/interfaces/IAaveIncentivesController.sol
+// src/core/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -119,7 +151,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol
+// src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -346,7 +378,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/interfaces/IScaledBalanceToken.sol
+// src/core/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
@@ -418,7 +450,7 @@ interface IScaledBalanceToken {
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/misc/interfaces/IWETH.sol
+// src/core/contracts/misc/interfaces/IWETH.sol
 
 interface IWETH {
   function deposit() external payable;
@@ -430,7 +462,7 @@ interface IWETH {
   function transferFrom(address src, address dst, uint256 wad) external returns (bool);
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol
+// src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -528,11 +560,56 @@ library Errors {
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
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol
+// src/core/contracts/protocol/libraries/types/DataTypes.sol
 
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
@@ -550,6 +627,8 @@ library DataTypes {
     uint40 lastUpdateTimestamp;
     //the id of the reserve. Represents the position in the list of the active reserves
     uint16 id;
+    //timestamp until when liquidations are not allowed on the reserve, if set to past liquidations will be allowed
+    uint40 liquidationGracePeriodUntil;
     //aToken address
     address aTokenAddress;
     //stableDebtToken address
@@ -564,6 +643,8 @@ library DataTypes {
     uint128 unbacked;
     //the outstanding debt borrowed against this asset in isolation mode
     uint128 isolationModeTotalDebt;
+    //the amount of underlying accounted for by the protocol
+    uint128 virtualUnderlyingBalance;
   }
 
   struct ReserveConfigurationMap {
@@ -580,13 +661,14 @@ library DataTypes {
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
@@ -721,6 +803,7 @@ library DataTypes {
     uint256 maxStableRateBorrowSizePercent;
     uint256 reservesCount;
     address addressesProvider;
+    address pool;
     uint8 userEModeCategory;
     bool isAuthorizedFlashBorrower;
   }
@@ -785,7 +868,8 @@ library DataTypes {
     uint256 averageStableBorrowRate;
     uint256 reserveFactor;
     address reserve;
-    address aToken;
+    bool usingVirtualBalance;
+    uint256 virtualUnderlyingBalance;
   }
 
   struct InitReserveParams {
@@ -799,39 +883,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-periphery/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol
-
-interface IWrappedTokenGatewayV3 {
-  function depositETH(address pool, address onBehalfOf, uint16 referralCode) external payable;
-
-  function withdrawETH(address pool, uint256 amount, address onBehalfOf) external;
-
-  function repayETH(
-    address pool,
-    uint256 amount,
-    uint256 rateMode,
-    address onBehalfOf
-  ) external payable;
-
-  function borrowETH(
-    address pool,
-    uint256 amount,
-    uint256 interestRateMode,
-    uint16 referralCode
-  ) external;
-
-  function withdrawETHWithPermit(
-    address pool,
-    uint256 amount,
-    address to,
-    uint256 deadline,
-    uint8 permitV,
-    bytes32 permitR,
-    bytes32 permitS
-  ) external;
-}
-
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// src/core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -944,7 +996,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
+// src/core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
 
 /**
  * @dev Contract module which provides a basic access control mechanism, where
@@ -1010,7 +1062,33 @@ contract Ownable is Context {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/interfaces/IPool.sol
+// downloads/ZKSYNC/WETH_GATEWAY/WrappedTokenGatewayV3/src/periphery/contracts/libraries/DataTypesHelper.sol
+
+/**
+ * @title DataTypesHelper
+ * @author Aave
+ * @dev Helper library to track user current debt balance, used by WrappedTokenGatewayV3
+ */
+library DataTypesHelper {
+  /**
+   * @notice Fetches the user current stable and variable debt balances
+   * @param user The user address
+   * @param reserve The reserve data object
+   * @return The stable debt balance
+   * @return The variable debt balance
+   **/
+  function getUserCurrentDebt(
+    address user,
+    DataTypes.ReserveDataLegacy memory reserve
+  ) internal view returns (uint256, uint256) {
+    return (
+      IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
+      IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
+    );
+  }
+}
+
+// src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1388,6 +1466,14 @@ interface IPool {
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
@@ -1532,6 +1618,22 @@ interface IPool {
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
@@ -1587,7 +1689,23 @@ interface IPool {
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
@@ -1615,6 +1733,13 @@ interface IPool {
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
@@ -1685,6 +1810,22 @@ interface IPool {
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
@@ -1742,9 +1883,44 @@ interface IPool {
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
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -1771,6 +1947,7 @@ library ReserveConfiguration {
   uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
   uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
   uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
+  uint256 internal constant VIRTUAL_ACC_ACTIVE_MASK =        0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
 
   /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
   uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
@@ -1791,6 +1968,7 @@ library ReserveConfiguration {
   uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
   uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
   uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;
+  uint256 internal constant VIRTUAL_ACC_START_BIT_POSITION = 252;
 
   uint256 internal constant MAX_VALID_LTV = 65535;
   uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
@@ -2286,6 +2464,33 @@ library ReserveConfiguration {
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
@@ -2352,33 +2557,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-periphery/contracts/libraries/DataTypesHelper.sol
-
-/**
- * @title DataTypesHelper
- * @author Aave
- * @dev Helper library to track user current debt balance, used by WrappedTokenGatewayV3
- */
-library DataTypesHelper {
-  /**
-   * @notice Fetches the user current stable and variable debt balances
-   * @param user The user address
-   * @param reserve The reserve data object
-   * @return The stable debt balance
-   * @return The variable debt balance
-   **/
-  function getUserCurrentDebt(
-    address user,
-    DataTypes.ReserveData memory reserve
-  ) internal view returns (uint256, uint256) {
-    return (
-      IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
-      IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
-    );
-  }
-}
-
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/protocol/libraries/configuration/UserConfiguration.sol
+// src/core/contracts/protocol/libraries/configuration/UserConfiguration.sol
 
 /**
  * @title UserConfiguration library
@@ -2610,7 +2789,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/interfaces/IInitializableAToken.sol
+// src/core/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -2663,7 +2842,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-core/contracts/interfaces/IAToken.sol
+// src/core/contracts/interfaces/IAToken.sol
 
 /**
  * @title IAToken
@@ -2797,7 +2976,7 @@ interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
   function rescueTokens(address token, address to, uint256 amount) external;
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/WrappedTokenGatewayV3.sol
+// downloads/ZKSYNC/WETH_GATEWAY/WrappedTokenGatewayV3/src/periphery/contracts/misc/WrappedTokenGatewayV3.sol
 
 /**
  * @dev This contract is an upgrade of the WrappedTokenGatewayV3 contract, with immutable pool address.
@@ -2808,8 +2987,8 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
   using UserConfiguration for DataTypes.UserConfigurationMap;
   using GPv2SafeERC20 for IERC20;
 
-  IWETH public immutable WETH;
-  IPool public immutable POOL;
+  IWETH internal immutable WETH;
+  IPool internal immutable POOL;
 
   /**
    * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
```
