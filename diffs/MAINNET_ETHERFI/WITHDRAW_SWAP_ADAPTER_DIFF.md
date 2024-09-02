```diff
diff --git a/./downloads/MAINNET/WITHDRAW_SWAP_ADAPTER.sol b/./downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER.sol
index 78e6778..ee7e5e5 100644
--- a/./downloads/MAINNET/WITHDRAW_SWAP_ADAPTER.sol
+++ b/./downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: AGPL-3.0
-pragma solidity =0.8.10 ^0.8.0 ^0.8.10;
+pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -244,7 +244,7 @@ abstract contract Context {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -320,7 +320,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/SafeMath.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/dependencies/openzeppelin/contracts/SafeMath.sol
 
 /// @title Optimized overflow and underflow safe math operations
 /// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
@@ -375,7 +375,7 @@ library SafeMath {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -602,7 +602,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/interfaces/IPriceOracleGetter.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/interfaces/IPriceOracleGetter.sol
 
 /**
  * @title IPriceOracleGetter
@@ -632,7 +632,7 @@ interface IPriceOracleGetter {
   function getAssetPrice(address asset) external view returns (uint256);
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/protocol/libraries/math/PercentageMath.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/protocol/libraries/math/PercentageMath.sol
 
 /**
  * @title PercentageMath library
@@ -693,9 +693,46 @@ library PercentageMath {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/protocol/libraries/types/DataTypes.sol
 
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
@@ -713,6 +750,8 @@ library DataTypes {
     uint40 lastUpdateTimestamp;
     //the id of the reserve. Represents the position in the list of the active reserves
     uint16 id;
+    //timestamp until when liquidations are not allowed on the reserve, if set to past liquidations will be allowed
+    uint40 liquidationGracePeriodUntil;
     //aToken address
     address aTokenAddress;
     //stableDebtToken address
@@ -727,6 +766,8 @@ library DataTypes {
     uint128 unbacked;
     //the outstanding debt borrowed against this asset in isolation mode
     uint128 isolationModeTotalDebt;
+    //the amount of underlying accounted for by the protocol
+    uint128 virtualUnderlyingBalance;
   }
 
   struct ReserveConfigurationMap {
@@ -743,13 +784,14 @@ library DataTypes {
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
@@ -884,6 +926,7 @@ library DataTypes {
     uint256 maxStableRateBorrowSizePercent;
     uint256 reservesCount;
     address addressesProvider;
+    address pool;
     uint8 userEModeCategory;
     bool isAuthorizedFlashBorrower;
   }
@@ -948,7 +991,8 @@ library DataTypes {
     uint256 averageStableBorrowRate;
     uint256 reserveFactor;
     address reserve;
-    address aToken;
+    bool usingVirtualBalance;
+    uint256 virtualUnderlyingBalance;
   }
 
   struct InitReserveParams {
@@ -962,19 +1006,21 @@ library DataTypes {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/periphery-v3/contracts/adapters/paraswap/interfaces/IParaSwapAugustus.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/periphery/contracts/adapters/paraswap/interfaces/IParaSwapAugustus.sol
 
 interface IParaSwapAugustus {
   function getTokenTransferProxy() external view returns (address);
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/periphery-v3/contracts/adapters/paraswap/interfaces/IParaSwapAugustusRegistry.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/periphery/contracts/adapters/paraswap/interfaces/IParaSwapAugustusRegistry.sol
 
 interface IParaSwapAugustusRegistry {
   function isValidAugustus(address augustus) external view returns (bool);
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/periphery-v3/contracts/dependencies/openzeppelin/ReentrancyGuard.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/periphery/contracts/dependencies/openzeppelin/ReentrancyGuard.sol
+
+// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
 
 /**
  * @dev Contract module that helps prevent reentrant calls to a function.
@@ -1017,7 +1063,7 @@ abstract contract ReentrancyGuard {
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * Calling a `nonReentrant` function from another `nonReentrant`
    * function is not supported. It is possible to prevent this from happening
-   * by making the `nonReentrant` function external, and make it call a
+   * by making the `nonReentrant` function external, and making it call a
    * `private` function that does the actual work.
    */
   modifier nonReentrant() {
@@ -1033,9 +1079,16 @@ abstract contract ReentrancyGuard {
     // https://eips.ethereum.org/EIPS/eip-2200)
     _status = _NOT_ENTERED;
   }
+
+  /**
+   * @dev As we use the guard with the proxy we need to init it with the empty value
+   */
+  function _initGuard() internal {
+    _status = _NOT_ENTERED;
+  }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -1148,7 +1201,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1158,7 +1211,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/dependencies/openzeppelin/contracts/Ownable.sol
 
 /**
  * @dev Contract module which provides a basic access control mechanism, where
@@ -1224,7 +1277,7 @@ contract Ownable is Context {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/interfaces/IERC20WithPermit.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/interfaces/IERC20WithPermit.sol
 
 /**
  * @title IERC20WithPermit
@@ -1255,7 +1308,7 @@ interface IERC20WithPermit is IERC20 {
   ) external;
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol
 
 // OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
 
@@ -1339,7 +1392,7 @@ library SafeERC20 {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/interfaces/IPool.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1717,6 +1770,14 @@ interface IPool {
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
@@ -1861,6 +1922,22 @@ interface IPool {
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
@@ -1916,7 +1993,23 @@ interface IPool {
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
@@ -1944,6 +2037,13 @@ interface IPool {
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
@@ -2014,6 +2114,22 @@ interface IPool {
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
@@ -2071,9 +2187,44 @@ interface IPool {
    *   0 if the action is executed directly by the user, without any middle-man
    */
   function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
+
+  /**
+   * @notice Gets the address of the external FlashLoanLogic
+   */
+  function getFlashLoanLogic() external returns (address);
+
+  /**
+   * @notice Gets the address of the external BorrowLogic
+   */
+  function getBorrowLogic() external returns (address);
+
+  /**
+   * @notice Gets the address of the external BridgeLogic
+   */
+  function getBridgeLogic() external returns (address);
+
+  /**
+   * @notice Gets the address of the external EModeLogic
+   */
+  function getEModeLogic() external returns (address);
+
+  /**
+   * @notice Gets the address of the external LiquidationLogic
+   */
+  function getLiquidationLogic() external returns (address);
+
+  /**
+   * @notice Gets the address of the external PoolLogic
+   */
+  function getPoolLogic() external returns (address);
+
+  /**
+   * @notice Gets the address of the external SupplyLogic
+   */
+  function getSupplyLogic() external returns (address);
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol
 
 /**
  * @title IFlashLoanSimpleReceiver
@@ -2106,7 +2257,7 @@ interface IFlashLoanSimpleReceiver {
   function POOL() external view returns (IPool);
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol
 
 /**
  * @title FlashLoanSimpleReceiverBase
@@ -2123,7 +2274,7 @@ abstract contract FlashLoanSimpleReceiverBase is IFlashLoanSimpleReceiver {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/periphery-v3/contracts/adapters/paraswap/BaseParaSwapAdapter.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/periphery/contracts/adapters/paraswap/BaseParaSwapAdapter.sol
 
 /**
  * @title BaseParaSwapAdapter
@@ -2192,7 +2343,9 @@ abstract contract BaseParaSwapAdapter is FlashLoanSimpleReceiverBase, Ownable {
    * @dev Get the aToken associated to the asset
    * @return address of the aToken
    */
-  function _getReserveData(address asset) internal view returns (DataTypes.ReserveData memory) {
+  function _getReserveData(
+    address asset
+  ) internal view returns (DataTypes.ReserveDataLegacy memory) {
     return POOL.getReserveData(asset);
   }
 
@@ -2253,7 +2406,7 @@ abstract contract BaseParaSwapAdapter is FlashLoanSimpleReceiverBase, Ownable {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/periphery-v3/contracts/adapters/paraswap/BaseParaSwapSellAdapter.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/periphery/contracts/adapters/paraswap/BaseParaSwapSellAdapter.sol
 
 /**
  * @title BaseParaSwapSellAdapter
@@ -2354,7 +2507,7 @@ abstract contract BaseParaSwapSellAdapter is BaseParaSwapAdapter {
   }
 }
 
-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/periphery-v3/contracts/adapters/paraswap/ParaSwapWithdrawSwapAdapter.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/periphery/contracts/adapters/paraswap/ParaSwapWithdrawSwapAdapter.sol
 
 contract ParaSwapWithdrawSwapAdapter is BaseParaSwapSellAdapter, ReentrancyGuard {
   using SafeERC20 for IERC20Detailed;
```
