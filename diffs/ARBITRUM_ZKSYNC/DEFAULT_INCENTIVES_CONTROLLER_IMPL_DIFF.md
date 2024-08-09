```diff
diff --git a/./downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol b/./downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
index 8c00995..455ec9b 100644
--- a/./downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
+++ b/./downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL.sol
@@ -1,7 +1,241 @@
 // SPDX-License-Identifier: BUSL-1.1
-pragma solidity =0.8.10 ^0.8.0 ^0.8.10;
+pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
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
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
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
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
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
+// src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -77,7 +311,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
+// src/core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
 
@@ -333,22 +567,22 @@ library SafeCast {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-core/contracts/interfaces/IScaledBalanceToken.sol
+// src/core/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
  * @author Aave
- * @notice Defines the basic interface for a scaledbalance token.
- **/
+ * @notice Defines the basic interface for a scaled-balance token.
+ */
 interface IScaledBalanceToken {
   /**
    * @dev Emitted after the mint action
    * @param caller The address performing the mint
-   * @param onBehalfOf The address of the user that will receive the minted scaled balance tokens
-   * @param value The amount being minted (user entered amount + balance increase from interest)
-   * @param balanceIncrease The increase in balance since the last action of the user
+   * @param onBehalfOf The address of the user that will receive the minted tokens
+   * @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
+   * @param balanceIncrease The increase in scaled-up balance since the last action of 'onBehalfOf'
    * @param index The next liquidity index of the reserve
-   **/
+   */
   event Mint(
     address indexed caller,
     address indexed onBehalfOf,
@@ -358,13 +592,14 @@ interface IScaledBalanceToken {
   );
 
   /**
-   * @dev Emitted after scaled balance tokens are burned
-   * @param from The address from which the scaled tokens will be burned
+   * @dev Emitted after the burn action
+   * @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
+   * @param from The address from which the tokens will be burned
    * @param target The address that will receive the underlying, if any
-   * @param value The amount being burned (user entered amount - balance increase from interest)
-   * @param balanceIncrease The increase in balance since the last action of the user
+   * @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
+   * @param balanceIncrease The increase in scaled-up balance since the last action of 'from'
    * @param index The next liquidity index of the reserve
-   **/
+   */
   event Burn(
     address indexed from,
     address indexed target,
@@ -379,7 +614,7 @@ interface IScaledBalanceToken {
    * at the moment of the update
    * @param user The user whose balance is calculated
    * @return The scaled balance of the user
-   **/
+   */
   function scaledBalanceOf(address user) external view returns (uint256);
 
   /**
@@ -387,24 +622,24 @@ interface IScaledBalanceToken {
    * @param user The address of the user
    * @return The scaled balance of the user
    * @return The scaled total supply
-   **/
+   */
   function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);
 
   /**
    * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
    * @return The scaled total supply
-   **/
+   */
   function scaledTotalSupply() external view returns (uint256);
 
   /**
    * @notice Returns last index interest was accrued to the user's balance
    * @param user The address of the user
    * @return The last index interest was accrued to the user's balance, expressed in ray
-   **/
+   */
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
+// src/core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
 
 /**
  * @title VersionedInitializable
@@ -456,13 +691,13 @@ abstract contract VersionedInitializable {
    * @notice Returns the revision number of the contract
    * @dev Needs to be defined in the inherited class as a constant.
    * @return The revision number
-   **/
+   */
   function getRevision() internal pure virtual returns (uint256);
 
   /**
    * @notice Returns true if and only if the function is running in the constructor
    * @return True if the function is running in the constructor
-   **/
+   */
   function isConstructor() private view returns (bool) {
     // extcodesize checks the size of the code stored in an address, and
     // address returns the current address. Since the code is still not
@@ -481,241 +716,7 @@ abstract contract VersionedInitializable {
   uint256[50] private ______gap;
 }
 
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol
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
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-periphery/contracts/rewards/interfaces/IRewardsDistributor.sol
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
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol
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
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -725,7 +726,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-periphery/contracts/rewards/libraries/RewardsDataTypes.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol
 
 library RewardsDataTypes {
   struct RewardsConfigInput {
@@ -776,7 +777,7 @@ library RewardsDataTypes {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-periphery/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/interfaces/IRewardsController.sol
 
 /**
  * @title IRewardsController
@@ -974,7 +975,7 @@ interface IRewardsController is IRewardsDistributor {
   ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
 }
 
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-periphery/contracts/rewards/RewardsDistributor.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsDistributor.sol
 
 /**
  * @title RewardsDistributor
@@ -1014,7 +1015,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
   function getRewardsData(
     address asset,
     address reward
-  ) public view override returns (uint256, uint256, uint256, uint256) {
+  ) external view override returns (uint256, uint256, uint256, uint256) {
     return (
       _assets[asset].rewards[reward].index,
       _assets[asset].rewards[reward].emissionPerSecond,
@@ -1066,7 +1067,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
     address user,
     address asset,
     address reward
-  ) public view override returns (uint256) {
+  ) external view override returns (uint256) {
     return _assets[asset].rewards[reward].usersData[user].index;
   }
 
@@ -1505,7 +1506,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
   }
 }
 
-// downloads/ARBITRUM/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/lib/aave-v3-periphery/contracts/rewards/RewardsController.sol
+// downloads/ZKSYNC/DEFAULT_INCENTIVES_CONTROLLER_IMPL/RewardsController/src/periphery/contracts/rewards/RewardsController.sol
 
 /**
  * @title RewardsController
@@ -1515,7 +1516,7 @@ abstract contract RewardsDistributor is IRewardsDistributor {
 contract RewardsController is RewardsDistributor, VersionedInitializable, IRewardsController {
   using SafeCast for uint256;
 
-  uint256 public constant REVISION = 2;
+  uint256 public constant REVISION = 1;
 
   // This mapping allows whitelisted addresses to claim on behalf of others
   // useful for contracts that hold tokens to be rewarded but don't have any native logic to claim Liquidity Mining rewards
```
