```diff
diff --git a/./downloads/GNOSIS/WETH_GATEWAY.sol b/./downloads/SONIC/WETH_GATEWAY.sol
index 07a0619..9378337 100644
--- a/./downloads/GNOSIS/WETH_GATEWAY.sol
+++ b/./downloads/SONIC/WETH_GATEWAY.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +24,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -75,8 +75,9 @@ library DataTypes {
     uint128 variableBorrowIndex;
     //the current variable borrow rate. Expressed in ray
     uint128 currentVariableBorrowRate;
-    // DEPRECATED on v3.2.0
-    uint128 __deprecatedStableBorrowRate;
+    /// @notice reused `__deprecatedStableBorrowRate` storage from pre 3.2
+    // the current accumulate deficit in underlying tokens
+    uint128 deficit;
     //timestamp of last update
     uint40 lastUpdateTimestamp;
     //the id of the reserve. Represents the position in the list of the active reserves
@@ -242,6 +243,11 @@ library DataTypes {
     uint8 userEModeCategory;
   }
 
+  struct ExecuteEliminateDeficitParams {
+    address asset;
+    uint256 amount;
+  }
+
   struct ExecuteSetUserEModeParams {
     uint256 reservesCount;
     address oracle;
@@ -348,7 +354,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -449,9 +455,13 @@ library Errors {
   string public constant INVALID_GRACE_PERIOD = '98'; // Grace period above a valid range
   string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
   string public constant NOT_BORROWABLE_IN_EMODE = '100'; // Asset not borrowable in eMode
+  string public constant CALLER_NOT_UMBRELLA = '101'; // The caller of the function is not the umbrella contract
+  string public constant RESERVE_NOT_IN_DEFICIT = '102'; // The reserve is not in deficit
+  string public constant MUST_NOT_LEAVE_DUST = '103'; // Below a certain threshold liquidators need to take the full position
+  string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -470,7 +480,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -546,7 +556,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -773,7 +783,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IScaledBalanceToken.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
@@ -845,7 +855,7 @@ interface IScaledBalanceToken {
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/interfaces/IWETH.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/interfaces/IWETH.sol
 
 interface IWETH {
   function deposit() external payable;
@@ -857,29 +867,7 @@ interface IWETH {
   function transferFrom(address src, address dst, uint256 wad) external returns (bool);
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/interfaces/IWrappedTokenGatewayV3.sol
-
-interface IWrappedTokenGatewayV3 {
-  function depositETH(address pool, address onBehalfOf, uint16 referralCode) external payable;
-
-  function withdrawETH(address pool, uint256 amount, address onBehalfOf) external;
-
-  function repayETH(address pool, uint256 amount, address onBehalfOf) external payable;
-
-  function borrowETH(address pool, uint256 amount, uint16 referralCode) external;
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
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -992,7 +980,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/openzeppelin/contracts/Ownable.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/openzeppelin/contracts/Ownable.sol
 
 /**
  * @dev Contract module which provides a basic access control mechanism, where
@@ -1058,7 +1046,7 @@ contract Ownable is Context {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IPool.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1241,6 +1229,14 @@ interface IPool {
     uint256 variableBorrowIndex
   );
 
+  /**
+   * @dev Emitted when the deficit of a reserve is covered.
+   * @param reserve The address of the underlying asset of the reserve
+   * @param caller The caller that triggered the DeficitCovered event
+   * @param amountCovered The amount of deficit covered
+   */
+  event DeficitCovered(address indexed reserve, address caller, uint256 amountCovered);
+
   /**
    * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
    * @param reserve The address of the reserve
@@ -1248,6 +1244,14 @@ interface IPool {
    */
   event MintedToTreasury(address indexed reserve, uint256 amountMinted);
 
+  /**
+   * @dev Emitted when deficit is realized on a liquidation.
+   * @param user The user address where the bad debt will be burned
+   * @param debtAsset The address of the underlying borrowed asset to be burned
+   * @param amountCreated The amount of deficit created
+   */
+  event DeficitCreated(address indexed user, address indexed debtAsset, uint256 amountCreated);
+
   /**
    * @notice Mints an `amount` of aTokens to the `onBehalfOf`
    * @param asset The address of the underlying asset to mint
@@ -1615,16 +1619,6 @@ interface IPool {
    */
   function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory);
 
-  /**
-   * @notice Returns the state and configuration of the reserve, including extra data included with Aave v3.1
-   * @dev DEPRECATED use independent getters instead (getReserveData, getLiquidationGracePeriod)
-   * @param asset The address of the underlying asset of the reserve
-   * @return The state and configuration data of the reserve with virtual accounting
-   */
-  function getReserveDataExtended(
-    address asset
-  ) external view returns (DataTypes.ReserveData memory);
-
   /**
    * @notice Returns the virtual underlying balance of the reserve
    * @param asset The address of the underlying asset of the reserve
@@ -1799,7 +1793,7 @@ interface IPool {
    * @param asset The address of the underlying asset
    * @return Timestamp when the liquidation grace period will end
    **/
-  function getLiquidationGracePeriod(address asset) external returns (uint40);
+  function getLiquidationGracePeriod(address asset) external view returns (uint40);
 
   /**
    * @notice Returns the total fee on flash loans
@@ -1853,6 +1847,37 @@ interface IPool {
    */
   function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
 
+  /**
+   * @notice It covers the deficit of a specified reserve by burning:
+   * - the equivalent aToken `amount` for assets with virtual accounting enabled
+   * - the equivalent `amount` of underlying for assets with virtual accounting disabled (e.g. GHO)
+   * @dev The deficit of a reserve can occur due to situations where borrowed assets are not repaid, leading to bad debt.
+   * @param asset The address of the underlying asset to cover the deficit.
+   * @param amount The amount to be covered, in aToken or underlying on non-virtual accounted assets
+   */
+  function eliminateReserveDeficit(address asset, uint256 amount) external;
+
+  /**
+   * @notice Returns the current deficit of a reserve.
+   * @param asset The address of the underlying asset of the reserve
+   * @return The current deficit of the reserve
+   */
+  function getReserveDeficit(address asset) external view returns (uint256);
+
+  /**
+   * @notice Returns the aToken address of a reserve.
+   * @param asset The address of the underlying asset of the reserve
+   * @return The address of the aToken
+   */
+  function getReserveAToken(address asset) external view returns (address);
+
+  /**
+   * @notice Returns the variableDebtToken address of a reserve.
+   * @param asset The address of the underlying asset of the reserve
+   * @return The address of the variableDebtToken
+   */
+  function getReserveVariableDebtToken(address asset) external view returns (address);
+
   /**
    * @notice Gets the address of the external FlashLoanLogic
    */
@@ -1889,7 +1914,7 @@ interface IPool {
   function getSupplyLogic() external view returns (address);
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -1897,26 +1922,26 @@ interface IPool {
  * @notice Implements the bitmap logic to handle the reserve configuration
  */
 library ReserveConfiguration {
-  uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
-  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
-  uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
-  uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
+  uint256 internal constant LTV_MASK =                       0x000000000000000000000000000000000000000000000000000000000000FFFF; // prettier-ignore
+  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0x00000000000000000000000000000000000000000000000000000000FFFF0000; // prettier-ignore
+  uint256 internal constant LIQUIDATION_BONUS_MASK =         0x0000000000000000000000000000000000000000000000000000FFFF00000000; // prettier-ignore
+  uint256 internal constant DECIMALS_MASK =                  0x00000000000000000000000000000000000000000000000000FF000000000000; // prettier-ignore
+  uint256 internal constant ACTIVE_MASK =                    0x0000000000000000000000000000000000000000000000000100000000000000; // prettier-ignore
+  uint256 internal constant FROZEN_MASK =                    0x0000000000000000000000000000000000000000000000000200000000000000; // prettier-ignore
+  uint256 internal constant BORROWING_MASK =                 0x0000000000000000000000000000000000000000000000000400000000000000; // prettier-ignore
   // @notice there is an unoccupied hole of 1 bit at position 59 from pre 3.2 stableBorrowRateEnabled
-  uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant FLASHLOAN_ENABLED_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  // @notice there is an unoccupied hole of 8 bits from 168 to 176 left from pre 3.2 eModeCategory
-  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant VIRTUAL_ACC_ACTIVE_MASK =        0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
+  uint256 internal constant PAUSED_MASK =                    0x0000000000000000000000000000000000000000000000001000000000000000; // prettier-ignore
+  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0x0000000000000000000000000000000000000000000000002000000000000000; // prettier-ignore
+  uint256 internal constant SILOED_BORROWING_MASK =          0x0000000000000000000000000000000000000000000000004000000000000000; // prettier-ignore
+  uint256 internal constant FLASHLOAN_ENABLED_MASK =         0x0000000000000000000000000000000000000000000000008000000000000000; // prettier-ignore
+  uint256 internal constant RESERVE_FACTOR_MASK =            0x00000000000000000000000000000000000000000000FFFF0000000000000000; // prettier-ignore
+  uint256 internal constant BORROW_CAP_MASK =                0x00000000000000000000000000000000000FFFFFFFFF00000000000000000000; // prettier-ignore
+  uint256 internal constant SUPPLY_CAP_MASK =                0x00000000000000000000000000FFFFFFFFF00000000000000000000000000000; // prettier-ignore
+  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0x0000000000000000000000FFFF00000000000000000000000000000000000000; // prettier-ignore
+  //@notice there is an unoccupied hole of 8 bits from 168 to 176 left from pre 3.2 eModeCategory
+  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0x00000000000FFFFFFFFF00000000000000000000000000000000000000000000; // prettier-ignore
+  uint256 internal constant DEBT_CEILING_MASK =              0x0FFFFFFFFFF00000000000000000000000000000000000000000000000000000; // prettier-ignore
+  uint256 internal constant VIRTUAL_ACC_ACTIVE_MASK =        0x1000000000000000000000000000000000000000000000000000000000000000; // prettier-ignore
 
   /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
   uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
@@ -1960,7 +1985,7 @@ library ReserveConfiguration {
   function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
     require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);
 
-    self.data = (self.data & LTV_MASK) | ltv;
+    self.data = (self.data & ~LTV_MASK) | ltv;
   }
 
   /**
@@ -1969,7 +1994,7 @@ library ReserveConfiguration {
    * @return The loan to value
    */
   function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
-    return self.data & ~LTV_MASK;
+    return self.data & LTV_MASK;
   }
 
   /**
@@ -1984,7 +2009,7 @@ library ReserveConfiguration {
     require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);
 
     self.data =
-      (self.data & LIQUIDATION_THRESHOLD_MASK) |
+      (self.data & ~LIQUIDATION_THRESHOLD_MASK) |
       (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
   }
 
@@ -1996,7 +2021,7 @@ library ReserveConfiguration {
   function getLiquidationThreshold(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
+    return (self.data & LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
   }
 
   /**
@@ -2011,7 +2036,7 @@ library ReserveConfiguration {
     require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);
 
     self.data =
-      (self.data & LIQUIDATION_BONUS_MASK) |
+      (self.data & ~LIQUIDATION_BONUS_MASK) |
       (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
   }
 
@@ -2023,7 +2048,7 @@ library ReserveConfiguration {
   function getLiquidationBonus(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
+    return (self.data & LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
   }
 
   /**
@@ -2037,7 +2062,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);
 
-    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
+    self.data = (self.data & ~DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
   }
 
   /**
@@ -2048,7 +2073,7 @@ library ReserveConfiguration {
   function getDecimals(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
+    return (self.data & DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
   }
 
   /**
@@ -2058,7 +2083,7 @@ library ReserveConfiguration {
    */
   function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
     self.data =
-      (self.data & ACTIVE_MASK) |
+      (self.data & ~ACTIVE_MASK) |
       (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
   }
 
@@ -2068,7 +2093,7 @@ library ReserveConfiguration {
    * @return The active state
    */
   function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~ACTIVE_MASK) != 0;
+    return (self.data & ACTIVE_MASK) != 0;
   }
 
   /**
@@ -2078,7 +2103,7 @@ library ReserveConfiguration {
    */
   function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
     self.data =
-      (self.data & FROZEN_MASK) |
+      (self.data & ~FROZEN_MASK) |
       (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
   }
 
@@ -2088,7 +2113,7 @@ library ReserveConfiguration {
    * @return The frozen state
    */
   function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~FROZEN_MASK) != 0;
+    return (self.data & FROZEN_MASK) != 0;
   }
 
   /**
@@ -2098,7 +2123,7 @@ library ReserveConfiguration {
    */
   function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
     self.data =
-      (self.data & PAUSED_MASK) |
+      (self.data & ~PAUSED_MASK) |
       (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
   }
 
@@ -2108,7 +2133,7 @@ library ReserveConfiguration {
    * @return The paused state
    */
   function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~PAUSED_MASK) != 0;
+    return (self.data & PAUSED_MASK) != 0;
   }
 
   /**
@@ -2125,7 +2150,7 @@ library ReserveConfiguration {
     bool borrowable
   ) internal pure {
     self.data =
-      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
+      (self.data & ~BORROWABLE_IN_ISOLATION_MASK) |
       (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
   }
 
@@ -2141,7 +2166,7 @@ library ReserveConfiguration {
   function getBorrowableInIsolation(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
+    return (self.data & BORROWABLE_IN_ISOLATION_MASK) != 0;
   }
 
   /**
@@ -2155,7 +2180,7 @@ library ReserveConfiguration {
     bool siloed
   ) internal pure {
     self.data =
-      (self.data & SILOED_BORROWING_MASK) |
+      (self.data & ~SILOED_BORROWING_MASK) |
       (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
   }
 
@@ -2168,7 +2193,7 @@ library ReserveConfiguration {
   function getSiloedBorrowing(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~SILOED_BORROWING_MASK) != 0;
+    return (self.data & SILOED_BORROWING_MASK) != 0;
   }
 
   /**
@@ -2181,7 +2206,7 @@ library ReserveConfiguration {
     bool enabled
   ) internal pure {
     self.data =
-      (self.data & BORROWING_MASK) |
+      (self.data & ~BORROWING_MASK) |
       (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
   }
 
@@ -2193,7 +2218,7 @@ library ReserveConfiguration {
   function getBorrowingEnabled(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~BORROWING_MASK) != 0;
+    return (self.data & BORROWING_MASK) != 0;
   }
 
   /**
@@ -2208,7 +2233,7 @@ library ReserveConfiguration {
     require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);
 
     self.data =
-      (self.data & RESERVE_FACTOR_MASK) |
+      (self.data & ~RESERVE_FACTOR_MASK) |
       (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
   }
 
@@ -2220,7 +2245,7 @@ library ReserveConfiguration {
   function getReserveFactor(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
+    return (self.data & RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
   }
 
   /**
@@ -2234,7 +2259,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);
 
-    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
+    self.data = (self.data & ~BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
   }
 
   /**
@@ -2245,7 +2270,7 @@ library ReserveConfiguration {
   function getBorrowCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
+    return (self.data & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2259,7 +2284,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);
 
-    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
+    self.data = (self.data & ~SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
   }
 
   /**
@@ -2270,7 +2295,7 @@ library ReserveConfiguration {
   function getSupplyCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
+    return (self.data & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2284,7 +2309,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);
 
-    self.data = (self.data & DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
+    self.data = (self.data & ~DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
   }
 
   /**
@@ -2295,7 +2320,7 @@ library ReserveConfiguration {
   function getDebtCeiling(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
+    return (self.data & DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
   }
 
   /**
@@ -2313,7 +2338,7 @@ library ReserveConfiguration {
     );
 
     self.data =
-      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
+      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) |
       (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
   }
 
@@ -2326,7 +2351,7 @@ library ReserveConfiguration {
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
     return
-      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
+      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
   }
 
   /**
@@ -2341,7 +2366,7 @@ library ReserveConfiguration {
     require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.INVALID_UNBACKED_MINT_CAP);
 
     self.data =
-      (self.data & UNBACKED_MINT_CAP_MASK) |
+      (self.data & ~UNBACKED_MINT_CAP_MASK) |
       (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
   }
 
@@ -2353,7 +2378,7 @@ library ReserveConfiguration {
   function getUnbackedMintCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
+    return (self.data & UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2366,7 +2391,7 @@ library ReserveConfiguration {
     bool flashLoanEnabled
   ) internal pure {
     self.data =
-      (self.data & FLASHLOAN_ENABLED_MASK) |
+      (self.data & ~FLASHLOAN_ENABLED_MASK) |
       (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
   }
 
@@ -2378,7 +2403,7 @@ library ReserveConfiguration {
   function getFlashLoanEnabled(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
+    return (self.data & FLASHLOAN_ENABLED_MASK) != 0;
   }
 
   /**
@@ -2391,21 +2416,24 @@ library ReserveConfiguration {
     bool active
   ) internal pure {
     self.data =
-      (self.data & VIRTUAL_ACC_ACTIVE_MASK) |
+      (self.data & ~VIRTUAL_ACC_ACTIVE_MASK) |
       (uint256(active ? 1 : 0) << VIRTUAL_ACC_START_BIT_POSITION);
   }
 
   /**
    * @notice Gets the virtual account active/not state of the reserve
    * @dev The state should be true for all normal assets and should be false
-   *  only in special cases (ex. GHO) where an asset is minted instead of supplied.
+   * Virtual accounting being disabled means that the asset:
+   * - is GHO
+   * - can never be supplied
+   * - the interest rate strategy is not influenced by the virtual balance
    * @param self The reserve configuration
    * @return The active state
    */
   function getIsVirtualAccActive(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~VIRTUAL_ACC_ACTIVE_MASK) != 0;
+    return (self.data & VIRTUAL_ACC_ACTIVE_MASK) != 0;
   }
 
   /**
@@ -2422,10 +2450,10 @@ library ReserveConfiguration {
     uint256 dataLocal = self.data;
 
     return (
-      (dataLocal & ~ACTIVE_MASK) != 0,
-      (dataLocal & ~FROZEN_MASK) != 0,
-      (dataLocal & ~BORROWING_MASK) != 0,
-      (dataLocal & ~PAUSED_MASK) != 0
+      (dataLocal & ACTIVE_MASK) != 0,
+      (dataLocal & FROZEN_MASK) != 0,
+      (dataLocal & BORROWING_MASK) != 0,
+      (dataLocal & PAUSED_MASK) != 0
     );
   }
 
@@ -2444,11 +2472,11 @@ library ReserveConfiguration {
     uint256 dataLocal = self.data;
 
     return (
-      dataLocal & ~LTV_MASK,
-      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
-      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
-      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
-      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
+      dataLocal & LTV_MASK,
+      (dataLocal & LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
+      (dataLocal & LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
+      (dataLocal & DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
+      (dataLocal & RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
     );
   }
 
@@ -2464,13 +2492,13 @@ library ReserveConfiguration {
     uint256 dataLocal = self.data;
 
     return (
-      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
-      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
+      (dataLocal & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
+      (dataLocal & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
     );
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
 
 /**
  * @title UserConfiguration library
@@ -2702,7 +2730,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IInitializableAToken.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -2755,7 +2783,33 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IAToken.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/interfaces/IWrappedTokenGatewayV3.sol
+
+interface IWrappedTokenGatewayV3 {
+  function WETH() external view returns (IWETH);
+
+  function POOL() external view returns (IPool);
+
+  function depositETH(address pool, address onBehalfOf, uint16 referralCode) external payable;
+
+  function withdrawETH(address pool, uint256 amount, address onBehalfOf) external;
+
+  function repayETH(address pool, uint256 amount, address onBehalfOf) external payable;
+
+  function borrowETH(address pool, uint256 amount, uint16 referralCode) external;
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
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IAToken.sol
 
 /**
  * @title IAToken
@@ -2889,7 +2943,7 @@ interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
   function rescueTokens(address token, address to, uint256 amount) external;
 }
 
-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/WrappedTokenGatewayV3.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/WrappedTokenGatewayV3.sol
 
 /**
  * @dev This contract is an upgrade of the WrappedTokenGatewayV3 contract, with immutable pool address.
@@ -2900,8 +2954,8 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
   using UserConfiguration for DataTypes.UserConfigurationMap;
   using GPv2SafeERC20 for IERC20;
 
-  IWETH internal immutable WETH;
-  IPool internal immutable POOL;
+  IWETH public immutable WETH;
+  IPool public immutable POOL;
 
   /**
    * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
@@ -2932,7 +2986,7 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
    * @param to address of the user who will receive native ETH
    */
   function withdrawETH(address, uint256 amount, address to) external override {
-    IAToken aWETH = IAToken(POOL.getReserveData(address(WETH)).aTokenAddress);
+    IAToken aWETH = IAToken(POOL.getReserveAToken(address(WETH)));
     uint256 userBalance = aWETH.balanceOf(msg.sender);
     uint256 amountToWithdraw = amount;
 
@@ -2952,8 +3006,9 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
    * @param onBehalfOf the address for which msg.sender is repaying
    */
   function repayETH(address, uint256 amount, address onBehalfOf) external payable override {
-    uint256 paybackAmount = IERC20((POOL.getReserveData(address(WETH))).variableDebtTokenAddress)
-      .balanceOf(onBehalfOf);
+    uint256 paybackAmount = IERC20(POOL.getReserveVariableDebtToken(address(WETH))).balanceOf(
+      onBehalfOf
+    );
 
     if (amount < paybackAmount) {
       paybackAmount = amount;
@@ -3006,7 +3061,7 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
     bytes32 permitR,
     bytes32 permitS
   ) external override {
-    IAToken aWETH = IAToken(POOL.getReserveData(address(WETH)).aTokenAddress);
+    IAToken aWETH = IAToken(POOL.getReserveAToken(address(WETH)));
     uint256 userBalance = aWETH.balanceOf(msg.sender);
     uint256 amountToWithdraw = amount;
 
@@ -3015,7 +3070,9 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
       amountToWithdraw = userBalance;
     }
     // permit `amount` rather than `amountToWithdraw` to make it easier for front-ends and integrators
-    aWETH.permit(msg.sender, address(this), amount, deadline, permitV, permitR, permitS);
+    try
+      aWETH.permit(msg.sender, address(this), amount, deadline, permitV, permitR, permitS)
+    {} catch {}
     aWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
     POOL.withdraw(address(WETH), amountToWithdraw, address(this));
     WETH.withdraw(amountToWithdraw);
```
