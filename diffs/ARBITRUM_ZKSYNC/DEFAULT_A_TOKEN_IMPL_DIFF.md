```diff
diff --git a/./downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL.sol b/./downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL.sol
index efb0fd4..459d34e 100644
--- a/./downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL.sol
+++ b/./downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: BUSL-1.1
-pragma solidity =0.8.10 ^0.8.0;
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +24,7 @@ abstract contract Context {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -100,7 +100,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
 
@@ -356,7 +356,7 @@ library SafeCast {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -375,7 +375,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -602,7 +602,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/interfaces/IScaledBalanceToken.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
@@ -674,7 +674,7 @@ interface IScaledBalanceToken {
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
 
 /**
  * @title VersionedInitializable
@@ -751,7 +751,7 @@ abstract contract VersionedInitializable {
   uint256[50] private ______gap;
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -849,9 +849,17 @@ library Errors {
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
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/protocol/libraries/math/WadRayMath.sol
 
 /**
  * @title WadRayMath library
@@ -977,9 +985,46 @@ library WadRayMath {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/protocol/libraries/types/DataTypes.sol
 
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
@@ -997,6 +1042,8 @@ library DataTypes {
     uint40 lastUpdateTimestamp;
     //the id of the reserve. Represents the position in the list of the active reserves
     uint16 id;
+    //timestamp until when liquidations are not allowed on the reserve, if set to past liquidations will be allowed
+    uint40 liquidationGracePeriodUntil;
     //aToken address
     address aTokenAddress;
     //stableDebtToken address
@@ -1011,6 +1058,8 @@ library DataTypes {
     uint128 unbacked;
     //the outstanding debt borrowed against this asset in isolation mode
     uint128 isolationModeTotalDebt;
+    //the amount of underlying accounted for by the protocol
+    uint128 virtualUnderlyingBalance;
   }
 
   struct ReserveConfigurationMap {
@@ -1024,15 +1073,17 @@ library DataTypes {
     //bit 59: stable rate borrowing enabled
     //bit 60: asset is paused
     //bit 61: borrowing in isolation mode is enabled
-    //bit 62-63: reserved
+    //bit 62: siloed borrowing enabled
+    //bit 63: flashloaning enabled
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
@@ -1167,6 +1218,7 @@ library DataTypes {
     uint256 maxStableRateBorrowSizePercent;
     uint256 reservesCount;
     address addressesProvider;
+    address pool;
     uint8 userEModeCategory;
     bool isAuthorizedFlashBorrower;
   }
@@ -1231,7 +1283,8 @@ library DataTypes {
     uint256 averageStableBorrowRate;
     uint256 reserveFactor;
     address reserve;
-    address aToken;
+    bool usingVirtualBalance;
+    uint256 virtualUnderlyingBalance;
   }
 
   struct InitReserveParams {
@@ -1245,7 +1298,7 @@ library DataTypes {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/protocol/tokenization/base/EIP712Base.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/protocol/tokenization/base/EIP712Base.sol
 
 /**
  * @title EIP712Base
@@ -1315,7 +1368,7 @@ abstract contract EIP712Base {
   function _EIP712BaseId() internal view virtual returns (string memory);
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -1428,7 +1481,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1438,7 +1491,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/interfaces/IACLManager.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -1611,7 +1664,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/interfaces/IPool.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1989,6 +2042,14 @@ interface IPool {
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
@@ -2133,6 +2194,22 @@ interface IPool {
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
@@ -2188,7 +2265,23 @@ interface IPool {
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
@@ -2216,6 +2309,13 @@ interface IPool {
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
@@ -2286,6 +2386,22 @@ interface IPool {
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
@@ -2343,9 +2459,44 @@ interface IPool {
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
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/interfaces/IInitializableAToken.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -2398,7 +2549,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/interfaces/IAToken.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/interfaces/IAToken.sol
 
 /**
  * @title IAToken
@@ -2532,7 +2683,7 @@ interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
   function rescueTokens(address token, address to, uint256 amount) external;
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
 
 /**
  * @title IncentivizedERC20
@@ -2587,15 +2738,15 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
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
 
@@ -2756,7 +2907,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/protocol/tokenization/base/MintableIncentivizedERC20.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/protocol/tokenization/base/MintableIncentivizedERC20.sol
 
 /**
  * @title MintableIncentivizedERC20
@@ -2818,7 +2969,7 @@ abstract contract MintableIncentivizedERC20 is IncentivizedERC20 {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/protocol/tokenization/base/ScaledBalanceTokenBase.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/protocol/tokenization/base/ScaledBalanceTokenBase.sol
 
 /**
  * @title ScaledBalanceTokenBase
@@ -2967,14 +3118,14 @@ abstract contract ScaledBalanceTokenBase is MintableIncentivizedERC20, IScaledBa
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_A_TOKEN_IMPL/AToken/lib/aave-v3-core/contracts/protocol/tokenization/AToken.sol
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/contracts/protocol/tokenization/AToken.sol
 
 /**
  * @title Aave ERC20 AToken
  * @author Aave
  * @notice Implementation of the interest bearing token for the Aave protocol
  */
-contract AToken is VersionedInitializable, ScaledBalanceTokenBase, EIP712Base, IAToken {
+abstract contract AToken is VersionedInitializable, ScaledBalanceTokenBase, EIP712Base, IAToken {
   using WadRayMath for uint256;
   using SafeCast for uint256;
   using GPv2SafeERC20 for IERC20;
@@ -2982,16 +3133,9 @@ contract AToken is VersionedInitializable, ScaledBalanceTokenBase, EIP712Base, I
   bytes32 public constant PERMIT_TYPEHASH =
     keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
 
-  uint256 public constant ATOKEN_REVISION = 0x2;
-
   address internal _treasury;
   address internal _underlyingAsset;
 
-  /// @inheritdoc VersionedInitializable
-  function getRevision() internal pure virtual override returns (uint256) {
-    return ATOKEN_REVISION;
-  }
-
   /**
    * @dev Constructor.
    * @param pool The address of the Pool contract
@@ -3012,29 +3156,7 @@ contract AToken is VersionedInitializable, ScaledBalanceTokenBase, EIP712Base, I
     string calldata aTokenName,
     string calldata aTokenSymbol,
     bytes calldata params
-  ) public virtual override initializer {
-    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
-    _setName(aTokenName);
-    _setSymbol(aTokenSymbol);
-    _setDecimals(aTokenDecimals);
-
-    _treasury = treasury;
-    _underlyingAsset = underlyingAsset;
-    _incentivesController = incentivesController;
-
-    _domainSeparator = _calculateDomainSeparator();
-
-    emit Initialized(
-      underlyingAsset,
-      address(POOL),
-      treasury,
-      address(incentivesController),
-      aTokenDecimals,
-      aTokenName,
-      aTokenSymbol,
-      params
-    );
-  }
+  ) public virtual;
 
   /// @inheritdoc IAToken
   function mint(
@@ -3208,3 +3330,50 @@ contract AToken is VersionedInitializable, ScaledBalanceTokenBase, EIP712Base, I
     IERC20(token).safeTransfer(to, amount);
   }
 }
+
+// downloads/ZKSYNC/DEFAULT_A_TOKEN_IMPL/ATokenInstance/src/core/instances/ATokenInstance.sol
+
+contract ATokenInstance is AToken {
+  uint256 public constant ATOKEN_REVISION = 1;
+
+  constructor(IPool pool) AToken(pool) {}
+
+  /// @inheritdoc VersionedInitializable
+  function getRevision() internal pure virtual override returns (uint256) {
+    return ATOKEN_REVISION;
+  }
+
+  /// @inheritdoc IInitializableAToken
+  function initialize(
+    IPool initializingPool,
+    address treasury,
+    address underlyingAsset,
+    IAaveIncentivesController incentivesController,
+    uint8 aTokenDecimals,
+    string calldata aTokenName,
+    string calldata aTokenSymbol,
+    bytes calldata params
+  ) public virtual override initializer {
+    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
+    _setName(aTokenName);
+    _setSymbol(aTokenSymbol);
+    _setDecimals(aTokenDecimals);
+
+    _treasury = treasury;
+    _underlyingAsset = underlyingAsset;
+    _incentivesController = incentivesController;
+
+    _domainSeparator = _calculateDomainSeparator();
+
+    emit Initialized(
+      underlyingAsset,
+      address(POOL),
+      treasury,
+      address(incentivesController),
+      aTokenDecimals,
+      aTokenName,
+      aTokenSymbol,
+      params
+    );
+  }
+}
```
