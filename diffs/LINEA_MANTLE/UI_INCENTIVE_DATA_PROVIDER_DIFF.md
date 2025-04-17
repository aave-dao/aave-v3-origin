```diff
diff --git a/./downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER.sol b/./downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER.sol
index 116b0dd..7be58b1 100644
--- a/./downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER.sol
+++ b/./downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER.sol
@@ -1,7 +1,55 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/chainlink/AggregatorInterface.sol
+
+// Chainlink Contracts v0.8
+
+interface AggregatorInterface {
+  function decimals() external view returns (uint8);
+
+  function description() external view returns (string memory);
+
+  function getRoundData(
+    uint80 _roundId
+  )
+    external
+    view
+    returns (
+      uint80 roundId,
+      int256 answer,
+      uint256 startedAt,
+      uint256 updatedAt,
+      uint80 answeredInRound
+    );
+
+  function latestRoundData()
+    external
+    view
+    returns (
+      uint80 roundId,
+      int256 answer,
+      uint256 startedAt,
+      uint256 updatedAt,
+      uint80 answeredInRound
+    );
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
+  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
+
+  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
+}
+
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +72,7 @@ abstract contract Context {
   }
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -75,8 +123,9 @@ library DataTypes {
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
@@ -242,6 +291,11 @@ library DataTypes {
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
@@ -348,7 +402,7 @@ library DataTypes {
   }
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -449,9 +503,13 @@ library Errors {
   string public constant INVALID_GRACE_PERIOD = '98'; // Grace period above a valid range
   string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
   string public constant NOT_BORROWABLE_IN_EMODE = '100'; // Asset not borrowable in eMode
+  string public constant CALLER_NOT_UMBRELLA = '101'; // The caller of the function is not the umbrella contract
+  string public constant RESERVE_NOT_IN_DEFICIT = '102'; // The reserve is not in deficit
+  string public constant MUST_NOT_LEAVE_DUST = '103'; // Below a certain threshold liquidators need to take the full position
+  string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -470,26 +528,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/interfaces/IEACAggregatorProxy.sol
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
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -565,7 +604,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -792,7 +831,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/interfaces/IRewardsDistributor.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/interfaces/IRewardsDistributor.sol
 
 /**
  * @title IRewardsDistributor
@@ -969,7 +1008,7 @@ interface IRewardsDistributor {
   function getEmissionManager() external view returns (address);
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/interfaces/ITransferStrategyBase.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/interfaces/ITransferStrategyBase.sol
 
 interface ITransferStrategyBase {
   event EmergencyWithdrawal(
@@ -1007,7 +1046,7 @@ interface ITransferStrategyBase {
   function emergencyWithdrawal(address token, address to, uint256 amount) external;
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
 
@@ -1263,7 +1302,7 @@ library SafeCast {
   }
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/math/WadRayMath.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/math/WadRayMath.sol
 
 /**
  * @title WadRayMath library
@@ -1389,7 +1428,7 @@ library WadRayMath {
   }
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/interfaces/IACLManager.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -1562,7 +1601,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1572,7 +1611,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/interfaces/IUiIncentiveDataProviderV3.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/interfaces/IUiIncentiveDataProviderV3.sol
 
 interface IUiIncentiveDataProviderV3 {
   struct AggregatedReserveIncentiveData {
@@ -1643,7 +1682,7 @@ interface IUiIncentiveDataProviderV3 {
     returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory);
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/interfaces/IPool.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1826,6 +1865,14 @@ interface IPool {
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
@@ -1833,6 +1880,14 @@ interface IPool {
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
@@ -2200,16 +2255,6 @@ interface IPool {
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
@@ -2384,7 +2429,7 @@ interface IPool {
    * @param asset The address of the underlying asset
    * @return Timestamp when the liquidation grace period will end
    **/
-  function getLiquidationGracePeriod(address asset) external returns (uint40);
+  function getLiquidationGracePeriod(address asset) external view returns (uint40);
 
   /**
    * @notice Returns the total fee on flash loans
@@ -2438,6 +2483,37 @@ interface IPool {
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
@@ -2474,7 +2550,7 @@ interface IPool {
   function getSupplyLogic() external view returns (address);
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -2482,26 +2558,26 @@ interface IPool {
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
@@ -2545,7 +2621,7 @@ library ReserveConfiguration {
   function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
     require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);
 
-    self.data = (self.data & LTV_MASK) | ltv;
+    self.data = (self.data & ~LTV_MASK) | ltv;
   }
 
   /**
@@ -2554,7 +2630,7 @@ library ReserveConfiguration {
    * @return The loan to value
    */
   function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
-    return self.data & ~LTV_MASK;
+    return self.data & LTV_MASK;
   }
 
   /**
@@ -2569,7 +2645,7 @@ library ReserveConfiguration {
     require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);
 
     self.data =
-      (self.data & LIQUIDATION_THRESHOLD_MASK) |
+      (self.data & ~LIQUIDATION_THRESHOLD_MASK) |
       (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
   }
 
@@ -2581,7 +2657,7 @@ library ReserveConfiguration {
   function getLiquidationThreshold(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
+    return (self.data & LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
   }
 
   /**
@@ -2596,7 +2672,7 @@ library ReserveConfiguration {
     require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);
 
     self.data =
-      (self.data & LIQUIDATION_BONUS_MASK) |
+      (self.data & ~LIQUIDATION_BONUS_MASK) |
       (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
   }
 
@@ -2608,7 +2684,7 @@ library ReserveConfiguration {
   function getLiquidationBonus(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
+    return (self.data & LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
   }
 
   /**
@@ -2622,7 +2698,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);
 
-    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
+    self.data = (self.data & ~DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
   }
 
   /**
@@ -2633,7 +2709,7 @@ library ReserveConfiguration {
   function getDecimals(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
+    return (self.data & DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
   }
 
   /**
@@ -2643,7 +2719,7 @@ library ReserveConfiguration {
    */
   function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
     self.data =
-      (self.data & ACTIVE_MASK) |
+      (self.data & ~ACTIVE_MASK) |
       (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
   }
 
@@ -2653,7 +2729,7 @@ library ReserveConfiguration {
    * @return The active state
    */
   function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~ACTIVE_MASK) != 0;
+    return (self.data & ACTIVE_MASK) != 0;
   }
 
   /**
@@ -2663,7 +2739,7 @@ library ReserveConfiguration {
    */
   function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
     self.data =
-      (self.data & FROZEN_MASK) |
+      (self.data & ~FROZEN_MASK) |
       (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
   }
 
@@ -2673,7 +2749,7 @@ library ReserveConfiguration {
    * @return The frozen state
    */
   function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~FROZEN_MASK) != 0;
+    return (self.data & FROZEN_MASK) != 0;
   }
 
   /**
@@ -2683,7 +2759,7 @@ library ReserveConfiguration {
    */
   function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
     self.data =
-      (self.data & PAUSED_MASK) |
+      (self.data & ~PAUSED_MASK) |
       (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
   }
 
@@ -2693,7 +2769,7 @@ library ReserveConfiguration {
    * @return The paused state
    */
   function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~PAUSED_MASK) != 0;
+    return (self.data & PAUSED_MASK) != 0;
   }
 
   /**
@@ -2710,7 +2786,7 @@ library ReserveConfiguration {
     bool borrowable
   ) internal pure {
     self.data =
-      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
+      (self.data & ~BORROWABLE_IN_ISOLATION_MASK) |
       (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
   }
 
@@ -2726,7 +2802,7 @@ library ReserveConfiguration {
   function getBorrowableInIsolation(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
+    return (self.data & BORROWABLE_IN_ISOLATION_MASK) != 0;
   }
 
   /**
@@ -2740,7 +2816,7 @@ library ReserveConfiguration {
     bool siloed
   ) internal pure {
     self.data =
-      (self.data & SILOED_BORROWING_MASK) |
+      (self.data & ~SILOED_BORROWING_MASK) |
       (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
   }
 
@@ -2753,7 +2829,7 @@ library ReserveConfiguration {
   function getSiloedBorrowing(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~SILOED_BORROWING_MASK) != 0;
+    return (self.data & SILOED_BORROWING_MASK) != 0;
   }
 
   /**
@@ -2766,7 +2842,7 @@ library ReserveConfiguration {
     bool enabled
   ) internal pure {
     self.data =
-      (self.data & BORROWING_MASK) |
+      (self.data & ~BORROWING_MASK) |
       (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
   }
 
@@ -2778,7 +2854,7 @@ library ReserveConfiguration {
   function getBorrowingEnabled(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~BORROWING_MASK) != 0;
+    return (self.data & BORROWING_MASK) != 0;
   }
 
   /**
@@ -2793,7 +2869,7 @@ library ReserveConfiguration {
     require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);
 
     self.data =
-      (self.data & RESERVE_FACTOR_MASK) |
+      (self.data & ~RESERVE_FACTOR_MASK) |
       (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
   }
 
@@ -2805,7 +2881,7 @@ library ReserveConfiguration {
   function getReserveFactor(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
+    return (self.data & RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
   }
 
   /**
@@ -2819,7 +2895,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);
 
-    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
+    self.data = (self.data & ~BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
   }
 
   /**
@@ -2830,7 +2906,7 @@ library ReserveConfiguration {
   function getBorrowCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
+    return (self.data & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2844,7 +2920,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);
 
-    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
+    self.data = (self.data & ~SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
   }
 
   /**
@@ -2855,7 +2931,7 @@ library ReserveConfiguration {
   function getSupplyCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
+    return (self.data & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2869,7 +2945,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);
 
-    self.data = (self.data & DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
+    self.data = (self.data & ~DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
   }
 
   /**
@@ -2880,7 +2956,7 @@ library ReserveConfiguration {
   function getDebtCeiling(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
+    return (self.data & DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
   }
 
   /**
@@ -2898,7 +2974,7 @@ library ReserveConfiguration {
     );
 
     self.data =
-      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
+      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) |
       (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
   }
 
@@ -2911,7 +2987,7 @@ library ReserveConfiguration {
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
     return
-      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
+      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
   }
 
   /**
@@ -2926,7 +3002,7 @@ library ReserveConfiguration {
     require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.INVALID_UNBACKED_MINT_CAP);
 
     self.data =
-      (self.data & UNBACKED_MINT_CAP_MASK) |
+      (self.data & ~UNBACKED_MINT_CAP_MASK) |
       (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
   }
 
@@ -2938,7 +3014,7 @@ library ReserveConfiguration {
   function getUnbackedMintCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
+    return (self.data & UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2951,7 +3027,7 @@ library ReserveConfiguration {
     bool flashLoanEnabled
   ) internal pure {
     self.data =
-      (self.data & FLASHLOAN_ENABLED_MASK) |
+      (self.data & ~FLASHLOAN_ENABLED_MASK) |
       (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
   }
 
@@ -2963,7 +3039,7 @@ library ReserveConfiguration {
   function getFlashLoanEnabled(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
+    return (self.data & FLASHLOAN_ENABLED_MASK) != 0;
   }
 
   /**
@@ -2976,21 +3052,24 @@ library ReserveConfiguration {
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
@@ -3007,10 +3086,10 @@ library ReserveConfiguration {
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
 
@@ -3029,11 +3108,11 @@ library ReserveConfiguration {
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
 
@@ -3049,13 +3128,13 @@ library ReserveConfiguration {
     uint256 dataLocal = self.data;
 
     return (
-      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
-      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
+      (dataLocal & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
+      (dataLocal & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
     );
   }
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/libraries/RewardsDataTypes.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/libraries/RewardsDataTypes.sol
 
 library RewardsDataTypes {
   struct RewardsConfigInput {
@@ -3065,7 +3144,7 @@ library RewardsDataTypes {
     address asset;
     address reward;
     ITransferStrategyBase transferStrategy;
-    IEACAggregatorProxy rewardOracle;
+    AggregatorInterface rewardOracle;
   }
 
   struct UserAssetBalance {
@@ -3106,7 +3185,7 @@ library RewardsDataTypes {
   }
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
 
 /**
  * @title UserConfiguration library
@@ -3338,7 +3417,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/rewards/interfaces/IRewardsController.sol
 
 /**
  * @title IRewardsController
@@ -3404,9 +3483,9 @@ interface IRewardsController is IRewardsDistributor {
    * This check is enforced for integrators to be able to show incentives at
    * the current Aave UI without the need to setup an external price registry
    * @param reward The address of the reward to set the price aggregator
-   * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
+   * @param rewardOracle The address of price aggregator that follows AggregatorInterface interface
    */
-  function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;
+  function setRewardOracle(address reward, AggregatorInterface rewardOracle) external;
 
   /**
    * @dev Get the price aggregator oracle address
@@ -3438,8 +3517,8 @@ interface IRewardsController is IRewardsDistributor {
    *   address asset: The asset address to incentivize
    *   address reward: The reward token address
    *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
-   *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
-   *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
+   *   AggregatorInterface rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
+   *                                     Must follow Chainlink Aggregator AggregatorInterface interface to be compatible.
    */
   function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;
 
@@ -3536,7 +3615,7 @@ interface IRewardsController is IRewardsDistributor {
   ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/protocol/tokenization/base/IncentivizedERC20.sol
 
 /**
  * @title IncentivizedERC20
@@ -3759,7 +3838,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }
 
-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/UiIncentiveDataProviderV3.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/UiIncentiveDataProviderV3.sol
 
 contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
   using UserConfiguration for DataTypes.UserConfigurationMap;
@@ -3834,10 +3913,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           rewardInformation.rewardOracleAddress = aTokenIncentiveController.getRewardOracle(
             rewardInformation.rewardTokenAddress
           );
-          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          rewardInformation.priceFeedDecimals = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).decimals();
-          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          rewardInformation.rewardPriceFeed = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).latestAnswer();
 
@@ -3888,10 +3967,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           rewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
             rewardInformation.rewardTokenAddress
           );
-          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          rewardInformation.priceFeedDecimals = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).decimals();
-          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          rewardInformation.rewardPriceFeed = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).latestAnswer();
 
@@ -3968,10 +4047,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           userRewardInformation.rewardOracleAddress = aTokenIncentiveController.getRewardOracle(
             userRewardInformation.rewardTokenAddress
           );
-          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          userRewardInformation.priceFeedDecimals = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).decimals();
-          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          userRewardInformation.rewardPriceFeed = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).latestAnswer();
 
@@ -4021,10 +4100,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           userRewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
             userRewardInformation.rewardTokenAddress
           );
-          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          userRewardInformation.priceFeedDecimals = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).decimals();
-          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          userRewardInformation.rewardPriceFeed = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).latestAnswer();
 
```
