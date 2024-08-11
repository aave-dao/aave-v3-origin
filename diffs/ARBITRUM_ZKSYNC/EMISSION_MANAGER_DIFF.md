```diff
diff --git a/./downloads/ARBITRUM/EMISSION_MANAGER.sol b/./downloads/ZKSYNC/EMISSION_MANAGER.sol
index be75e57..16d9cb7 100644
--- a/./downloads/ARBITRUM/EMISSION_MANAGER.sol
+++ b/./downloads/ZKSYNC/EMISSION_MANAGER.sol

-// downloads/ARBITRUM/EMISSION_MANAGER/EmissionManager/@aave/periphery-v3/contracts/rewards/interfaces/IRewardsDistributor.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/IRewardsDistributor.sol

 /**
  * @title IRewardsDistributor
@@ -89,16 +66,6 @@ interface IRewardsDistributor {
     uint256 rewardsAccrued
   );

-  /**
-   * @dev Emitted when the emission manager address is updated.
-   * @param oldEmissionManager The address of the old emission manager
-   * @param newEmissionManager The address of the new emission manager
-   */
-  event EmissionManagerUpdated(
-    address indexed oldEmissionManager,
-    address indexed newEmissionManager
-  );
-
   /**
    * @dev Sets the end date for the distribution
    * @param asset The asset to incentivize
@@ -154,6 +121,15 @@ interface IRewardsDistributor {
     address reward
   ) external view returns (uint256, uint256, uint256, uint256);

+  /**
+   * @dev Calculates the next value of an specific distribution index, with validations.
+   * @param asset The incentivized asset
+   * @param reward The reward token of the incentivized asset
+   * @return The old index of the asset distribution
+   * @return The new index of the asset distribution
+   **/
+  function getAssetIndex(address asset, address reward) external view returns (uint256, uint256);
+
   /**
    * @dev Returns the list of available reward token addresses of an incentivized asset
    * @param asset The incentivized asset
@@ -211,16 +187,17 @@ interface IRewardsDistributor {
    * @dev Returns the address of the emission manager
    * @return The address of the EmissionManager
    */
+  function EMISSION_MANAGER() external view returns (address);
+
+  /**
+   * @dev Returns the address of the emission manager.
+   * Deprecated: This getter is maintained for compatibility purposes. Use the `EMISSION_MANAGER()` function instead.
+   * @return The address of the EmissionManager
+   */
   function getEmissionManager() external view returns (address);
-
-  /**
-   * @dev Updates the address of the emission manager
-   * @param emissionManager The address of the new EmissionManager
-   */
-  function setEmissionManager(address emissionManager) external;
 }

-// downloads/ARBITRUM/EMISSION_MANAGER/EmissionManager/@aave/periphery-v3/contracts/rewards/libraries/RewardsDataTypes.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol

 library RewardsDataTypes {
   struct RewardsConfigInput {
@@ -344,27 +344,38 @@ library RewardsDataTypes {
   }

   struct UserData {
-    uint104 index; // matches reward index
+    // Liquidity index of the reward distribution for the user
+    uint104 index;
+    // Amount of accrued rewards for the user since last user index update
     uint128 accrued;
   }

   struct RewardData {
+    // Liquidity index of the reward distribution
     uint104 index;
+    // Amount of reward tokens distributed per second
     uint88 emissionPerSecond;
+    // Timestamp of the last reward index update
     uint32 lastUpdateTimestamp;
+    // The end of the distribution of rewards (in seconds)
     uint32 distributionEnd;
+    // Map of user addresses and their rewards data (userAddress => userData)
     mapping(address => UserData) usersData;
   }

   struct AssetData {
+    // Map of reward token addresses and their data (rewardTokenAddress => rewardData)
     mapping(address => RewardData) rewards;
+    // List of reward token addresses for the asset
     mapping(uint128 => address) availableRewards;
+    // Count of reward tokens for the asset
     uint128 availableRewardsCount;
+    // Number of decimals of the asset
     uint8 decimals;
   }
 }

-// downloads/ARBITRUM/EMISSION_MANAGER/EmissionManager/@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/IRewardsController.sol

 /**
  * @title IRewardsController
@@ -470,12 +481,13 @@ interface IRewardsController is IRewardsDistributor {
   function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

   /**
-   * @dev Called by the corresponding asset on any update that affects the rewards distribution
-   * @param user The address of the user
-   * @param userBalance The user balance of the asset
-   * @param totalSupply The total supply of the asset
+   * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
+   * @dev The units of `totalSupply` and `userBalance` should be the same.
+   * @param user The address of the user whose asset balance has changed
+   * @param totalSupply The total supply of the asset prior to user balance change
+   * @param userBalance The previous user balance prior to balance change
    **/
-  function handleAction(address user, uint256 userBalance, uint256 totalSupply) external;
+  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;

   /**
    * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
@@ -561,7 +573,7 @@ interface IRewardsController is IRewardsDistributor {
   ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
 }

-// downloads/ARBITRUM/EMISSION_MANAGER/EmissionManager/@aave/periphery-v3/contracts/rewards/interfaces/IEmissionManager.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/interfaces/IEmissionManager.sol

 /**
  * @title IEmissionManager
@@ -645,13 +657,6 @@ interface IEmissionManager {
    */
   function setClaimer(address user, address claimer) external;

-  /**
-   * @dev Updates the address of the emission manager
-   * @dev Only callable by the owner of the EmissionManager
-   * @param emissionManager The address of the new EmissionManager
-   */
-  function setEmissionManager(address emissionManager) external;
-
   /**
    * @dev Updates the admin of the reward emission
    * @dev Only callable by the owner of the EmissionManager
@@ -681,7 +686,7 @@ interface IEmissionManager {
   function getEmissionAdmin(address reward) external view returns (address);
 }

-// downloads/ARBITRUM/EMISSION_MANAGER/EmissionManager/@aave/periphery-v3/contracts/rewards/EmissionManager.sol
+// downloads/ZKSYNC/EMISSION_MANAGER/EmissionManager/src/periphery/contracts/rewards/EmissionManager.sol

 /**
  * @title EmissionManager
@@ -704,11 +709,9 @@ contract EmissionManager is Ownable, IEmissionManager {

   /**
    * Constructor.
-   * @param controller The address of the RewardsController contract
    * @param owner The address of the owner
    */
-  constructor(address controller, address owner) {
-    _rewardsController = IRewardsController(controller);
+  constructor(address owner) {
     transferOwnership(owner);
   }

@@ -762,11 +765,6 @@ contract EmissionManager is Ownable, IEmissionManager {
     _rewardsController.setClaimer(user, claimer);
   }

-  /// @inheritdoc IEmissionManager
-  function setEmissionManager(address emissionManager) external override onlyOwner {
-    _rewardsController.setEmissionManager(emissionManager);
-  }
-
   /// @inheritdoc IEmissionManager
   function setEmissionAdmin(address reward, address admin) external override onlyOwner {
     address oldAdmin = _emissionAdmins[reward];
```
