```diff
diff --git a/./downloads/LINEA/WALLET_BALANCE_PROVIDER.sol b/./downloads/MANTLE/WALLET_BALANCE_PROVIDER.sol
index d701f7f..da717ea 100644
--- a/./downloads/LINEA/WALLET_BALANCE_PROVIDER.sol
+++ b/./downloads/MANTLE/WALLET_BALANCE_PROVIDER.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/LINEA/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/MANTLE/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/LINEA/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/MANTLE/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -272,8 +272,9 @@ library DataTypes {
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
@@ -439,6 +440,11 @@ library DataTypes {
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
@@ -545,7 +551,7 @@ library DataTypes {
   }
 }
 
-// downloads/LINEA/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/MANTLE/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -646,9 +652,13 @@ library Errors {
   string public constant INVALID_GRACE_PERIOD = '98'; // Grace period above a valid range
   string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
   string public constant NOT_BORROWABLE_IN_EMODE = '100'; // Asset not borrowable in eMode
+  string public constant CALLER_NOT_UMBRELLA = '101'; // The caller of the function is not the umbrella contract
+  string public constant RESERVE_NOT_IN_DEFICIT = '102'; // The reserve is not in deficit
+  string public constant MUST_NOT_LEAVE_DUST = '103'; // Below a certain threshold liquidators need to take the full position
+  string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/LINEA/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/MANTLE/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -724,7 +734,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/LINEA/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/MANTLE/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -951,7 +961,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/LINEA/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// downloads/MANTLE/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -1064,7 +1074,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/LINEA/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/interfaces/IPool.sol
+// downloads/MANTLE/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1247,6 +1257,14 @@ interface IPool {
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
@@ -1254,6 +1272,14 @@ interface IPool {
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
@@ -1621,16 +1647,6 @@ interface IPool {
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
@@ -1805,7 +1821,7 @@ interface IPool {
    * @param asset The address of the underlying asset
    * @return Timestamp when the liquidation grace period will end
    **/
-  function getLiquidationGracePeriod(address asset) external returns (uint40);
+  function getLiquidationGracePeriod(address asset) external view returns (uint40);
 
   /**
    * @notice Returns the total fee on flash loans
@@ -1859,6 +1875,37 @@ interface IPool {
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
@@ -1895,7 +1942,7 @@ interface IPool {
   function getSupplyLogic() external view returns (address);
 }
 
-// downloads/LINEA/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/MANTLE/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -1903,26 +1950,26 @@ interface IPool {
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
@@ -1966,7 +2013,7 @@ library ReserveConfiguration {
   function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
     require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);
 
-    self.data = (self.data & LTV_MASK) | ltv;
+    self.data = (self.data & ~LTV_MASK) | ltv;
   }
 
   /**
@@ -1975,7 +2022,7 @@ library ReserveConfiguration {
    * @return The loan to value
    */
   function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
-    return self.data & ~LTV_MASK;
+    return self.data & LTV_MASK;
   }
 
   /**
@@ -1990,7 +2037,7 @@ library ReserveConfiguration {
     require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);
 
     self.data =
-      (self.data & LIQUIDATION_THRESHOLD_MASK) |
+      (self.data & ~LIQUIDATION_THRESHOLD_MASK) |
       (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
   }
 
@@ -2002,7 +2049,7 @@ library ReserveConfiguration {
   function getLiquidationThreshold(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
+    return (self.data & LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
   }
 
   /**
@@ -2017,7 +2064,7 @@ library ReserveConfiguration {
     require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);
 
     self.data =
-      (self.data & LIQUIDATION_BONUS_MASK) |
+      (self.data & ~LIQUIDATION_BONUS_MASK) |
       (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
   }
 
@@ -2029,7 +2076,7 @@ library ReserveConfiguration {
   function getLiquidationBonus(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
+    return (self.data & LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
   }
 
   /**
@@ -2043,7 +2090,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);
 
-    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
+    self.data = (self.data & ~DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
   }
 
   /**
@@ -2054,7 +2101,7 @@ library ReserveConfiguration {
   function getDecimals(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
+    return (self.data & DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
   }
 
   /**
@@ -2064,7 +2111,7 @@ library ReserveConfiguration {
    */
   function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
     self.data =
-      (self.data & ACTIVE_MASK) |
+      (self.data & ~ACTIVE_MASK) |
       (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
   }
 
@@ -2074,7 +2121,7 @@ library ReserveConfiguration {
    * @return The active state
    */
   function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~ACTIVE_MASK) != 0;
+    return (self.data & ACTIVE_MASK) != 0;
   }
 
   /**
@@ -2084,7 +2131,7 @@ library ReserveConfiguration {
    */
   function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
     self.data =
-      (self.data & FROZEN_MASK) |
+      (self.data & ~FROZEN_MASK) |
       (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
   }
 
@@ -2094,7 +2141,7 @@ library ReserveConfiguration {
    * @return The frozen state
    */
   function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~FROZEN_MASK) != 0;
+    return (self.data & FROZEN_MASK) != 0;
   }
 
   /**
@@ -2104,7 +2151,7 @@ library ReserveConfiguration {
    */
   function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
     self.data =
-      (self.data & PAUSED_MASK) |
+      (self.data & ~PAUSED_MASK) |
       (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
   }
 
@@ -2114,7 +2161,7 @@ library ReserveConfiguration {
    * @return The paused state
    */
   function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~PAUSED_MASK) != 0;
+    return (self.data & PAUSED_MASK) != 0;
   }
 
   /**
@@ -2131,7 +2178,7 @@ library ReserveConfiguration {
     bool borrowable
   ) internal pure {
     self.data =
-      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
+      (self.data & ~BORROWABLE_IN_ISOLATION_MASK) |
       (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
   }
 
@@ -2147,7 +2194,7 @@ library ReserveConfiguration {
   function getBorrowableInIsolation(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
+    return (self.data & BORROWABLE_IN_ISOLATION_MASK) != 0;
   }
 
   /**
@@ -2161,7 +2208,7 @@ library ReserveConfiguration {
     bool siloed
   ) internal pure {
     self.data =
-      (self.data & SILOED_BORROWING_MASK) |
+      (self.data & ~SILOED_BORROWING_MASK) |
       (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
   }
 
@@ -2174,7 +2221,7 @@ library ReserveConfiguration {
   function getSiloedBorrowing(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~SILOED_BORROWING_MASK) != 0;
+    return (self.data & SILOED_BORROWING_MASK) != 0;
   }
 
   /**
@@ -2187,7 +2234,7 @@ library ReserveConfiguration {
     bool enabled
   ) internal pure {
     self.data =
-      (self.data & BORROWING_MASK) |
+      (self.data & ~BORROWING_MASK) |
       (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
   }
 
@@ -2199,7 +2246,7 @@ library ReserveConfiguration {
   function getBorrowingEnabled(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~BORROWING_MASK) != 0;
+    return (self.data & BORROWING_MASK) != 0;
   }
 
   /**
@@ -2214,7 +2261,7 @@ library ReserveConfiguration {
     require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);
 
     self.data =
-      (self.data & RESERVE_FACTOR_MASK) |
+      (self.data & ~RESERVE_FACTOR_MASK) |
       (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
   }
 
@@ -2226,7 +2273,7 @@ library ReserveConfiguration {
   function getReserveFactor(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
+    return (self.data & RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
   }
 
   /**
@@ -2240,7 +2287,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);
 
-    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
+    self.data = (self.data & ~BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
   }
 
   /**
@@ -2251,7 +2298,7 @@ library ReserveConfiguration {
   function getBorrowCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
+    return (self.data & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2265,7 +2312,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);
 
-    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
+    self.data = (self.data & ~SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
   }
 
   /**
@@ -2276,7 +2323,7 @@ library ReserveConfiguration {
   function getSupplyCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
+    return (self.data & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2290,7 +2337,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);
 
-    self.data = (self.data & DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
+    self.data = (self.data & ~DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
   }
 
   /**
@@ -2301,7 +2348,7 @@ library ReserveConfiguration {
   function getDebtCeiling(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
+    return (self.data & DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
   }
 
   /**
@@ -2319,7 +2366,7 @@ library ReserveConfiguration {
     );
 
     self.data =
-      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
+      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) |
       (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
   }
 
@@ -2332,7 +2379,7 @@ library ReserveConfiguration {
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
     return
-      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
+      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
   }
 
   /**
@@ -2347,7 +2394,7 @@ library ReserveConfiguration {
     require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.INVALID_UNBACKED_MINT_CAP);
 
     self.data =
-      (self.data & UNBACKED_MINT_CAP_MASK) |
+      (self.data & ~UNBACKED_MINT_CAP_MASK) |
       (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
   }
 
@@ -2359,7 +2406,7 @@ library ReserveConfiguration {
   function getUnbackedMintCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
+    return (self.data & UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2372,7 +2419,7 @@ library ReserveConfiguration {
     bool flashLoanEnabled
   ) internal pure {
     self.data =
-      (self.data & FLASHLOAN_ENABLED_MASK) |
+      (self.data & ~FLASHLOAN_ENABLED_MASK) |
       (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
   }
 
@@ -2384,7 +2431,7 @@ library ReserveConfiguration {
   function getFlashLoanEnabled(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
+    return (self.data & FLASHLOAN_ENABLED_MASK) != 0;
   }
 
   /**
@@ -2397,21 +2444,24 @@ library ReserveConfiguration {
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
@@ -2428,10 +2478,10 @@ library ReserveConfiguration {
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
 
@@ -2450,11 +2500,11 @@ library ReserveConfiguration {
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
 
@@ -2470,13 +2520,13 @@ library ReserveConfiguration {
     uint256 dataLocal = self.data;
 
     return (
-      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
-      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
+      (dataLocal & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
+      (dataLocal & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
     );
   }
 }
 
-// downloads/LINEA/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/helpers/WalletBalanceProvider.sol
+// downloads/MANTLE/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/helpers/WalletBalanceProvider.sol
 
 /**
  * @title WalletBalanceProvider contract
```
