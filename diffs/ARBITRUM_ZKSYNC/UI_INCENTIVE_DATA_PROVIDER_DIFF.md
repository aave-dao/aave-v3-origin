```diff
diff --git a/./downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER.sol b/./downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER.sol
index eee6caa..8a55fee 100644
--- a/./downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER.sol
+++ b/./downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER.sol
@@ -1,7 +1,241 @@
-// SPDX-License-Identifier: AGPL-3.0
-pragma solidity =0.8.10 ^0.8.0 ^0.8.10;
+// SPDX-License-Identifier: BUSL-1.1
+pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
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
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
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
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
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
+// src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +258,7 @@ abstract contract Context {
   }
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -100,7 +334,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
+// src/core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
 
@@ -356,7 +590,7 @@ library SafeCast {
   }
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/interfaces/IAaveIncentivesController.sol
+// src/core/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -375,7 +609,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol
+// src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -602,7 +836,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/protocol/libraries/helpers/Errors.sol
+// src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -670,7 +904,7 @@ library Errors {
   string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
   string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
   string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
-  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
+  string public constant USER_IN_ISOLATION_MODE_OR_LTV_ZERO = '62'; // 'User is in isolation mode or ltv is zero'
   string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
   string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
   string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
@@ -700,9 +934,17 @@ library Errors {
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
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/protocol/libraries/math/WadRayMath.sol
+// src/core/contracts/protocol/libraries/math/WadRayMath.sol
 
 /**
  * @title WadRayMath library
@@ -828,9 +1070,46 @@ library WadRayMath {
   }
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol
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
@@ -848,6 +1127,8 @@ library DataTypes {
     uint40 lastUpdateTimestamp;
     //the id of the reserve. Represents the position in the list of the active reserves
     uint16 id;
+    //timestamp until when liquidations are not allowed on the reserve, if set to past liquidations will be allowed
+    uint40 liquidationGracePeriodUntil;
     //aToken address
     address aTokenAddress;
     //stableDebtToken address
@@ -862,6 +1143,8 @@ library DataTypes {
     uint128 unbacked;
     //the outstanding debt borrowed against this asset in isolation mode
     uint128 isolationModeTotalDebt;
+    //the amount of underlying accounted for by the protocol
+    uint128 virtualUnderlyingBalance;
   }
 
   struct ReserveConfigurationMap {
@@ -875,15 +1158,17 @@ library DataTypes {
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
@@ -1018,6 +1303,7 @@ library DataTypes {
     uint256 maxStableRateBorrowSizePercent;
     uint256 reservesCount;
     address addressesProvider;
+    address pool;
     uint8 userEModeCategory;
     bool isAuthorizedFlashBorrower;
   }
@@ -1082,7 +1368,8 @@ library DataTypes {
     uint256 averageStableBorrowRate;
     uint256 reserveFactor;
     address reserve;
-    address aToken;
+    bool usingVirtualBalance;
+    uint256 virtualUnderlyingBalance;
   }
 
   struct InitReserveParams {
@@ -1096,241 +1383,80 @@ library DataTypes {
   }
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/periphery-v3/contracts/misc/interfaces/IEACAggregatorProxy.sol
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
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/periphery-v3/contracts/rewards/interfaces/IRewardsDistributor.sol
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
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/misc/interfaces/IUiIncentiveDataProviderV3.sol
+
+interface IUiIncentiveDataProviderV3 {
+  struct AggregatedReserveIncentiveData {
+    address underlyingAsset;
+    IncentiveData aIncentiveData;
+    IncentiveData vIncentiveData;
+    IncentiveData sIncentiveData;
+  }
+
+  struct IncentiveData {
+    address tokenAddress;
+    address incentiveControllerAddress;
+    RewardInfo[] rewardsTokenInformation;
+  }
+
+  struct RewardInfo {
+    string rewardTokenSymbol;
+    address rewardTokenAddress;
+    address rewardOracleAddress;
+    uint256 emissionPerSecond;
+    uint256 incentivesLastUpdateTimestamp;
+    uint256 tokenIncentivesIndex;
+    uint256 emissionEndTimestamp;
+    int256 rewardPriceFeed;
+    uint8 rewardTokenDecimals;
+    uint8 precision;
+    uint8 priceFeedDecimals;
+  }
+
+  struct UserReserveIncentiveData {
+    address underlyingAsset;
+    UserIncentiveData aTokenIncentivesUserData;
+    UserIncentiveData vTokenIncentivesUserData;
+    UserIncentiveData sTokenIncentivesUserData;
+  }
+
+  struct UserIncentiveData {
+    address tokenAddress;
+    address incentiveControllerAddress;
+    UserRewardInfo[] userRewardsInformation;
+  }
+
+  struct UserRewardInfo {
+    string rewardTokenSymbol;
+    address rewardOracleAddress;
+    address rewardTokenAddress;
+    uint256 userUnclaimedRewards;
+    uint256 tokenIncentivesUserIndex;
+    int256 rewardPriceFeed;
+    uint8 priceFeedDecimals;
+    uint8 rewardTokenDecimals;
+  }
+
+  function getReservesIncentivesData(
+    IPoolAddressesProvider provider
+  ) external view returns (AggregatedReserveIncentiveData[] memory);
+
+  function getUserReservesIncentivesData(
+    IPoolAddressesProvider provider,
     address user
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
+  ) external view returns (UserReserveIncentiveData[] memory);
 
-  /**
-   * @dev Returns the address of the emission manager.
-   * Deprecated: This getter is maintained for compatibility purposes. Use the `EMISSION_MANAGER()` function instead.
-   * @return The address of the EmissionManager
-   */
-  function getEmissionManager() external view returns (address);
-}
-
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/periphery-v3/contracts/rewards/interfaces/ITransferStrategyBase.sol
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
+  // generic method with full data
+  function getFullReservesIncentiveData(
+    IPoolAddressesProvider provider,
+    address user
+  )
+    external
+    view
+    returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory);
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1340,7 +1466,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/interfaces/IACLManager.sol
+// src/core/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -1513,80 +1639,58 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/periphery-v3/contracts/misc/interfaces/IUiIncentiveDataProviderV3.sol
-
-interface IUiIncentiveDataProviderV3 {
-  struct AggregatedReserveIncentiveData {
-    address underlyingAsset;
-    IncentiveData aIncentiveData;
-    IncentiveData vIncentiveData;
-    IncentiveData sIncentiveData;
-  }
-
-  struct IncentiveData {
-    address tokenAddress;
-    address incentiveControllerAddress;
-    RewardInfo[] rewardsTokenInformation;
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
+
+library RewardsDataTypes {
+  struct RewardsConfigInput {
+    uint88 emissionPerSecond;
+    uint256 totalSupply;
+    uint32 distributionEnd;
+    address asset;
+    address reward;
+    ITransferStrategyBase transferStrategy;
+    IEACAggregatorProxy rewardOracle;
   }
 
-  struct RewardInfo {
-    string rewardTokenSymbol;
-    address rewardTokenAddress;
-    address rewardOracleAddress;
-    uint256 emissionPerSecond;
-    uint256 incentivesLastUpdateTimestamp;
-    uint256 tokenIncentivesIndex;
-    uint256 emissionEndTimestamp;
-    int256 rewardPriceFeed;
-    uint8 rewardTokenDecimals;
-    uint8 precision;
-    uint8 priceFeedDecimals;
+  struct UserAssetBalance {
+    address asset;
+    uint256 userBalance;
+    uint256 totalSupply;
   }
 
-  struct UserReserveIncentiveData {
-    address underlyingAsset;
-    UserIncentiveData aTokenIncentivesUserData;
-    UserIncentiveData vTokenIncentivesUserData;
-    UserIncentiveData sTokenIncentivesUserData;
+  struct UserData {
+    // Liquidity index of the reward distribution for the user
+    uint104 index;
+    // Amount of accrued rewards for the user since last user index update
+    uint128 accrued;
   }
 
-  struct UserIncentiveData {
-    address tokenAddress;
-    address incentiveControllerAddress;
-    UserRewardInfo[] userRewardsInformation;
+  struct RewardData {
+    // Liquidity index of the reward distribution
+    uint104 index;
+    // Amount of reward tokens distributed per second
+    uint88 emissionPerSecond;
+    // Timestamp of the last reward index update
+    uint32 lastUpdateTimestamp;
+    // The end of the distribution of rewards (in seconds)
+    uint32 distributionEnd;
+    // Map of user addresses and their rewards data (userAddress => userData)
+    mapping(address => UserData) usersData;
   }
 
-  struct UserRewardInfo {
-    string rewardTokenSymbol;
-    address rewardOracleAddress;
-    address rewardTokenAddress;
-    uint256 userUnclaimedRewards;
-    uint256 tokenIncentivesUserIndex;
-    int256 rewardPriceFeed;
-    uint8 priceFeedDecimals;
-    uint8 rewardTokenDecimals;
+  struct AssetData {
+    // Map of reward token addresses and their data (rewardTokenAddress => rewardData)
+    mapping(address => RewardData) rewards;
+    // List of reward token addresses for the asset
+    mapping(uint128 => address) availableRewards;
+    // Count of reward tokens for the asset
+    uint128 availableRewardsCount;
+    // Number of decimals of the asset
+    uint8 decimals;
   }
-
-  function getReservesIncentivesData(
-    IPoolAddressesProvider provider
-  ) external view returns (AggregatedReserveIncentiveData[] memory);
-
-  function getUserReservesIncentivesData(
-    IPoolAddressesProvider provider,
-    address user
-  ) external view returns (UserReserveIncentiveData[] memory);
-
-  // generic method with full data
-  function getFullReservesIncentiveData(
-    IPoolAddressesProvider provider,
-    address user
-  )
-    external
-    view
-    returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory);
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/interfaces/IPool.sol
+// src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1964,6 +2068,14 @@ interface IPool {
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
@@ -2005,7 +2117,7 @@ interface IPool {
    * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
    * as long as the amount taken plus a fee is returned.
    * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
-   * into consideration. For further details please visit https://developers.aave.com
+   * into consideration. For further details please visit https://docs.aave.com/developers/
    * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
    * @param assets The addresses of the assets being flash-borrowed
    * @param amounts The amounts of the assets being flash-borrowed
@@ -2032,7 +2144,7 @@ interface IPool {
    * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
    * as long as the amount taken plus a fee is returned.
    * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
-   * into consideration. For further details please visit https://developers.aave.com
+   * into consideration. For further details please visit https://docs.aave.com/developers/
    * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
    * @param asset The address of the asset being flash-borrowed
    * @param amount The amount of the asset being flash-borrowed
@@ -2108,6 +2220,22 @@ interface IPool {
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
@@ -2163,7 +2291,23 @@ interface IPool {
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
@@ -2191,6 +2335,13 @@ interface IPool {
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
@@ -2261,6 +2412,22 @@ interface IPool {
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
@@ -2318,9 +2485,44 @@ interface IPool {
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
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -2347,6 +2549,7 @@ library ReserveConfiguration {
   uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
   uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
   uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
+  uint256 internal constant VIRTUAL_ACC_ACTIVE_MASK =        0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
 
   /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
   uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
@@ -2367,6 +2570,7 @@ library ReserveConfiguration {
   uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
   uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
   uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;
+  uint256 internal constant VIRTUAL_ACC_START_BIT_POSITION = 252;
 
   uint256 internal constant MAX_VALID_LTV = 65535;
   uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
@@ -2862,6 +3066,33 @@ library ReserveConfiguration {
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
@@ -2928,58 +3159,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/periphery-v3/contracts/rewards/libraries/RewardsDataTypes.sol
-
-library RewardsDataTypes {
-  struct RewardsConfigInput {
-    uint88 emissionPerSecond;
-    uint256 totalSupply;
-    uint32 distributionEnd;
-    address asset;
-    address reward;
-    ITransferStrategyBase transferStrategy;
-    IEACAggregatorProxy rewardOracle;
-  }
-
-  struct UserAssetBalance {
-    address asset;
-    uint256 userBalance;
-    uint256 totalSupply;
-  }
-
-  struct UserData {
-    // Liquidity index of the reward distribution for the user
-    uint104 index;
-    // Amount of accrued rewards for the user since last user index update
-    uint128 accrued;
-  }
-
-  struct RewardData {
-    // Liquidity index of the reward distribution
-    uint104 index;
-    // Amount of reward tokens distributed per second
-    uint88 emissionPerSecond;
-    // Timestamp of the last reward index update
-    uint32 lastUpdateTimestamp;
-    // The end of the distribution of rewards (in seconds)
-    uint32 distributionEnd;
-    // Map of user addresses and their rewards data (userAddress => userData)
-    mapping(address => UserData) usersData;
-  }
-
-  struct AssetData {
-    // Map of reward token addresses and their data (rewardTokenAddress => rewardData)
-    mapping(address => RewardData) rewards;
-    // List of reward token addresses for the asset
-    mapping(uint128 => address) availableRewards;
-    // Count of reward tokens for the asset
-    uint128 availableRewardsCount;
-    // Number of decimals of the asset
-    uint8 decimals;
-  }
-}
-
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/protocol/libraries/configuration/UserConfiguration.sol
+// src/core/contracts/protocol/libraries/configuration/UserConfiguration.sol
 
 /**
  * @title UserConfiguration library
@@ -3211,7 +3391,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
 
 /**
  * @title IRewardsController
@@ -3409,7 +3589,7 @@ interface IRewardsController is IRewardsDistributor {
   ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/core-v3/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
 
 /**
  * @title IncentivizedERC20
@@ -3464,15 +3644,15 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
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
 
@@ -3633,7 +3813,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }
 
-// downloads/ARBITRUM/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/@aave/periphery-v3/contracts/misc/UiIncentiveDataProviderV3.sol
+// downloads/ZKSYNC/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/periphery/contracts/misc/UiIncentiveDataProviderV3.sol
 
 contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
   using UserConfiguration for DataTypes.UserConfigurationMap;
@@ -3668,7 +3848,7 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
       AggregatedReserveIncentiveData memory reserveIncentiveData = reservesIncentiveData[i];
       reserveIncentiveData.underlyingAsset = reserves[i];
 
-      DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);
+      DataTypes.ReserveDataLegacy memory baseData = pool.getReserveData(reserves[i]);
 
       // Get aTokens rewards information
       // TODO: check that this is deployed correctly on contract and remove casting
@@ -3857,7 +4037,7 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
     );
 
     for (uint256 i = 0; i < reserves.length; i++) {
-      DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);
+      DataTypes.ReserveDataLegacy memory baseData = pool.getReserveData(reserves[i]);
 
       // user reserve data
       userReservesIncentivesData[i].underlyingAsset = reserves[i];
```
