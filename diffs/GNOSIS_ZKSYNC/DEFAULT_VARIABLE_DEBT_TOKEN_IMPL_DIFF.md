```diff
diff --git a/./downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol b/./downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol
index 96f262c..e6dd5a5 100644
--- a/./downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol
+++ b/./downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +24,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -100,7 +100,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
 
@@ -356,7 +356,7 @@ library SafeCast {
   }
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -375,7 +375,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/interfaces/ICreditDelegationToken.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/interfaces/ICreditDelegationToken.sol
 
 /**
  * @title ICreditDelegationToken
@@ -435,7 +435,7 @@ interface ICreditDelegationToken {
   ) external;
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -662,7 +662,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/interfaces/IScaledBalanceToken.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
@@ -734,7 +734,7 @@ interface IScaledBalanceToken {
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
 
 /**
  * @title VersionedInitializable
@@ -811,7 +811,7 @@ abstract contract VersionedInitializable {
   uint256[50] private ______gap;
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -909,9 +909,17 @@ library Errors {
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
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/libraries/math/WadRayMath.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/libraries/math/WadRayMath.sol
 
 /**
  * @title WadRayMath library
@@ -1037,9 +1045,46 @@ library WadRayMath {
   }
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/libraries/types/DataTypes.sol
 
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
@@ -1057,6 +1102,8 @@ library DataTypes {
     uint40 lastUpdateTimestamp;
     //the id of the reserve. Represents the position in the list of the active reserves
     uint16 id;
+    //timestamp until when liquidations are not allowed on the reserve, if set to past liquidations will be allowed
+    uint40 liquidationGracePeriodUntil;
     //aToken address
     address aTokenAddress;
     //stableDebtToken address
@@ -1071,6 +1118,8 @@ library DataTypes {
     uint128 unbacked;
     //the outstanding debt borrowed against this asset in isolation mode
     uint128 isolationModeTotalDebt;
+    //the amount of underlying accounted for by the protocol
+    uint128 virtualUnderlyingBalance;
   }
 
   struct ReserveConfigurationMap {
@@ -1087,13 +1136,14 @@ library DataTypes {
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
@@ -1228,6 +1278,7 @@ library DataTypes {
     uint256 maxStableRateBorrowSizePercent;
     uint256 reservesCount;
     address addressesProvider;
+    address pool;
     uint8 userEModeCategory;
     bool isAuthorizedFlashBorrower;
   }
@@ -1292,7 +1343,8 @@ library DataTypes {
     uint256 averageStableBorrowRate;
     uint256 reserveFactor;
     address reserve;
-    address aToken;
+    bool usingVirtualBalance;
+    uint256 virtualUnderlyingBalance;
   }
 
   struct InitReserveParams {
@@ -1306,7 +1358,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/tokenization/base/EIP712Base.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/tokenization/base/EIP712Base.sol
 
 /**
  * @title EIP712Base
@@ -1376,7 +1428,7 @@ abstract contract EIP712Base {
   function _EIP712BaseId() internal view virtual returns (string memory);
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1386,7 +1438,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/interfaces/IACLManager.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -1559,7 +1611,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/interfaces/IPool.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1937,6 +1989,14 @@ interface IPool {
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
@@ -2081,6 +2141,22 @@ interface IPool {
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
@@ -2136,7 +2212,23 @@ interface IPool {
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
@@ -2164,6 +2256,13 @@ interface IPool {
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
@@ -2234,6 +2333,22 @@ interface IPool {
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
@@ -2291,9 +2406,44 @@ interface IPool {
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
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -2342,7 +2492,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/tokenization/base/DebtTokenBase.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/tokenization/base/DebtTokenBase.sol
 
 /**
  * @title DebtTokenBase
@@ -2438,7 +2588,7 @@ abstract contract DebtTokenBase is
   }
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/interfaces/IVariableDebtToken.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/interfaces/IVariableDebtToken.sol
 
 /**
  * @title IVariableDebtToken
@@ -2481,7 +2631,7 @@ interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
   function UNDERLYING_ASSET_ADDRESS() external view returns (address);
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
 
 /**
  * @title IncentivizedERC20
@@ -2536,15 +2686,15 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   /**
    * @dev Constructor.
    * @param pool The reference to the main Pool contract
-   * @param name The name of the token
-   * @param symbol The symbol of the token
-   * @param decimals The number of decimals of the token
+   * @param name_ The name of the token
+   * @param symbol_ The symbol of the token
+   * @param decimals_ The number of decimals of the token
    */
-  constructor(IPool pool, string memory name, string memory symbol, uint8 decimals) {
+  constructor(IPool pool, string memory name_, string memory symbol_, uint8 decimals_) {
     _addressesProvider = pool.ADDRESSES_PROVIDER();
-    _name = name;
-    _symbol = symbol;
-    _decimals = decimals;
+    _name = name_;
+    _symbol = symbol_;
+    _decimals = decimals_;
     POOL = pool;
   }
 
@@ -2705,7 +2855,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/tokenization/base/MintableIncentivizedERC20.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/tokenization/base/MintableIncentivizedERC20.sol
 
 /**
  * @title MintableIncentivizedERC20
@@ -2767,7 +2917,7 @@ abstract contract MintableIncentivizedERC20 is IncentivizedERC20 {
   }
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/tokenization/base/ScaledBalanceTokenBase.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/tokenization/base/ScaledBalanceTokenBase.sol
 
 /**
  * @title ScaledBalanceTokenBase
@@ -2916,7 +3066,7 @@ abstract contract ScaledBalanceTokenBase is MintableIncentivizedERC20, IScaledBa
   }
 }
 
-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/tokenization/VariableDebtToken.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/tokenization/VariableDebtToken.sol
 
 /**
  * @title VariableDebtToken
@@ -2925,12 +3075,10 @@ abstract contract ScaledBalanceTokenBase is MintableIncentivizedERC20, IScaledBa
  * at variable rate mode
  * @dev Transfer and approve functionalities are disabled since its a non-transferable token
  */
-contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDebtToken {
+abstract contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDebtToken {
   using WadRayMath for uint256;
   using SafeCast for uint256;
 
-  uint256 public constant DEBT_TOKEN_REVISION = 0x1;
-
   /**
    * @dev Constructor.
    * @param pool The address of the Pool contract
@@ -2953,32 +3101,7 @@ contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDe
     string memory debtTokenName,
     string memory debtTokenSymbol,
     bytes calldata params
-  ) external override initializer {
-    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
-    _setName(debtTokenName);
-    _setSymbol(debtTokenSymbol);
-    _setDecimals(debtTokenDecimals);
-
-    _underlyingAsset = underlyingAsset;
-    _incentivesController = incentivesController;
-
-    _domainSeparator = _calculateDomainSeparator();
-
-    emit Initialized(
-      underlyingAsset,
-      address(POOL),
-      address(incentivesController),
-      debtTokenDecimals,
-      debtTokenName,
-      debtTokenSymbol,
-      params
-    );
-  }
-
-  /// @inheritdoc VersionedInitializable
-  function getRevision() internal pure virtual override returns (uint256) {
-    return DEBT_TOKEN_REVISION;
-  }
+  ) external virtual;
 
   /// @inheritdoc IERC20
   function balanceOf(address user) public view virtual override returns (uint256) {
@@ -3057,3 +3180,47 @@ contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDe
     return _underlyingAsset;
   }
 }
+
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/instances/VariableDebtTokenInstance.sol
+
+contract VariableDebtTokenInstance is VariableDebtToken {
+  uint256 public constant DEBT_TOKEN_REVISION = 1;
+
+  constructor(IPool pool) VariableDebtToken(pool) {}
+
+  /// @inheritdoc VersionedInitializable
+  function getRevision() internal pure virtual override returns (uint256) {
+    return DEBT_TOKEN_REVISION;
+  }
+
+  /// @inheritdoc IInitializableDebtToken
+  function initialize(
+    IPool initializingPool,
+    address underlyingAsset,
+    IAaveIncentivesController incentivesController,
+    uint8 debtTokenDecimals,
+    string memory debtTokenName,
+    string memory debtTokenSymbol,
+    bytes calldata params
+  ) external override initializer {
+    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
+    _setName(debtTokenName);
+    _setSymbol(debtTokenSymbol);
+    _setDecimals(debtTokenDecimals);
+
+    _underlyingAsset = underlyingAsset;
+    _incentivesController = incentivesController;
+
+    _domainSeparator = _calculateDomainSeparator();
+
+    emit Initialized(
+      underlyingAsset,
+      address(POOL),
+      address(incentivesController),
+      debtTokenDecimals,
+      debtTokenName,
+      debtTokenSymbol,
+      params
+    );
+  }
+}
```
