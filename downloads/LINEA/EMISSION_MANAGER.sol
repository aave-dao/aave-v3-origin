// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

// downloads/LINEA/EMISSION_MANAGER/EmissionManager/src/contracts/dependencies/openzeppelin/contracts/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// downloads/LINEA/EMISSION_MANAGER/EmissionManager/src/contracts/helpers/interfaces/IEACAggregatorProxy.sol

interface IEACAggregatorProxy {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// downloads/LINEA/EMISSION_MANAGER/EmissionManager/src/contracts/rewards/interfaces/IRewardsDistributor.sol

/**
 * @title IRewardsDistributor
 * @author Aave
 * @notice Defines the basic interface for a Rewards Distributor.
 */
interface IRewardsDistributor {
  /**
   * @dev Emitted when the configuration of the rewards of an asset is updated.
   * @param asset The address of the incentivized asset
   * @param reward The address of the reward token
   * @param oldEmission The old emissions per second value of the reward distribution
   * @param newEmission The new emissions per second value of the reward distribution
   * @param oldDistributionEnd The old end timestamp of the reward distribution
   * @param newDistributionEnd The new end timestamp of the reward distribution
   * @param assetIndex The index of the asset distribution
   */
  event AssetConfigUpdated(
    address indexed asset,
    address indexed reward,
    uint256 oldEmission,
    uint256 newEmission,
    uint256 oldDistributionEnd,
    uint256 newDistributionEnd,
    uint256 assetIndex
  );

  /**
   * @dev Emitted when rewards of an asset are accrued on behalf of a user.
   * @param asset The address of the incentivized asset
   * @param reward The address of the reward token
   * @param user The address of the user that rewards are accrued on behalf of
   * @param assetIndex The index of the asset distribution
   * @param userIndex The index of the asset distribution on behalf of the user
   * @param rewardsAccrued The amount of rewards accrued
   */
  event Accrued(
    address indexed asset,
    address indexed reward,
    address indexed user,
    uint256 assetIndex,
    uint256 userIndex,
    uint256 rewardsAccrued
  );

  /**
   * @dev Sets the end date for the distribution
   * @param asset The asset to incentivize
   * @param reward The reward token that incentives the asset
   * @param newDistributionEnd The end date of the incentivization, in unix time format
   **/
  function setDistributionEnd(address asset, address reward, uint32 newDistributionEnd) external;

  /**
   * @dev Sets the emission per second of a set of reward distributions
   * @param asset The asset is being incentivized
   * @param rewards List of reward addresses are being distributed
   * @param newEmissionsPerSecond List of new reward emissions per second
   */
  function setEmissionPerSecond(
    address asset,
    address[] calldata rewards,
    uint88[] calldata newEmissionsPerSecond
  ) external;

  /**
   * @dev Gets the end date for the distribution
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The timestamp with the end of the distribution, in unix time format
   **/
  function getDistributionEnd(address asset, address reward) external view returns (uint256);

  /**
   * @dev Returns the index of a user on a reward distribution
   * @param user Address of the user
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The current user asset index, not including new distributions
   **/
  function getUserAssetIndex(
    address user,
    address asset,
    address reward
  ) external view returns (uint256);

  /**
   * @dev Returns the configuration of the distribution reward for a certain asset
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The index of the asset distribution
   * @return The emission per second of the reward distribution
   * @return The timestamp of the last update of the index
   * @return The timestamp of the distribution end
   **/
  function getRewardsData(
    address asset,
    address reward
  ) external view returns (uint256, uint256, uint256, uint256);

  /**
   * @dev Calculates the next value of an specific distribution index, with validations.
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The old index of the asset distribution
   * @return The new index of the asset distribution
   **/
  function getAssetIndex(address asset, address reward) external view returns (uint256, uint256);

  /**
   * @dev Returns the list of available reward token addresses of an incentivized asset
   * @param asset The incentivized asset
   * @return List of rewards addresses of the input asset
   **/
  function getRewardsByAsset(address asset) external view returns (address[] memory);

  /**
   * @dev Returns the list of available reward addresses
   * @return List of rewards supported in this contract
   **/
  function getRewardsList() external view returns (address[] memory);

  /**
   * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
   * @param user The address of the user
   * @param reward The address of the reward token
   * @return Unclaimed rewards, not including new distributions
   **/
  function getUserAccruedRewards(address user, address reward) external view returns (uint256);

  /**
   * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
   * @param assets List of incentivized assets to check eligible distributions
   * @param user The address of the user
   * @param reward The address of the reward token
   * @return The rewards amount
   **/
  function getUserRewards(
    address[] calldata assets,
    address user,
    address reward
  ) external view returns (uint256);

  /**
   * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
   * @param assets List of incentivized assets to check eligible distributions
   * @param user The address of the user
   * @return The list of reward addresses
   * @return The list of unclaimed amount of rewards
   **/
  function getAllUserRewards(
    address[] calldata assets,
    address user
  ) external view returns (address[] memory, uint256[] memory);

  /**
   * @dev Returns the decimals of an asset to calculate the distribution delta
   * @param asset The address to retrieve decimals
   * @return The decimals of an underlying asset
   */
  function getAssetDecimals(address asset) external view returns (uint8);

  /**
   * @dev Returns the address of the emission manager
   * @return The address of the EmissionManager
   */
  function EMISSION_MANAGER() external view returns (address);

  /**
   * @dev Returns the address of the emission manager.
   * Deprecated: This getter is maintained for compatibility purposes. Use the `EMISSION_MANAGER()` function instead.
   * @return The address of the EmissionManager
   */
  function getEmissionManager() external view returns (address);
}

// downloads/LINEA/EMISSION_MANAGER/EmissionManager/src/contracts/rewards/interfaces/ITransferStrategyBase.sol

interface ITransferStrategyBase {
  event EmergencyWithdrawal(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /**
   * @dev Perform custom transfer logic via delegate call from source contract to a TransferStrategy implementation
   * @param to Account to transfer rewards
   * @param reward Address of the reward token
   * @param amount Amount to transfer to the "to" address parameter
   * @return Returns true bool if transfer logic succeeds
   */
  function performTransfer(address to, address reward, uint256 amount) external returns (bool);

  /**
   * @return Returns the address of the Incentives Controller
   */
  function getIncentivesController() external view returns (address);

  /**
   * @return Returns the address of the Rewards admin
   */
  function getRewardsAdmin() external view returns (address);

  /**
   * @dev Perform an emergency token withdrawal only callable by the Rewards admin
   * @param token Address of the token to withdraw funds from this contract
   * @param to Address of the recipient of the withdrawal
   * @param amount Amount of the withdrawal
   */
  function emergencyWithdrawal(address token, address to, uint256 amount) external;
}

// downloads/LINEA/EMISSION_MANAGER/EmissionManager/src/contracts/dependencies/openzeppelin/contracts/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// downloads/LINEA/EMISSION_MANAGER/EmissionManager/src/contracts/rewards/libraries/RewardsDataTypes.sol

library RewardsDataTypes {
  struct RewardsConfigInput {
    uint88 emissionPerSecond;
    uint256 totalSupply;
    uint32 distributionEnd;
    address asset;
    address reward;
    ITransferStrategyBase transferStrategy;
    IEACAggregatorProxy rewardOracle;
  }

  struct UserAssetBalance {
    address asset;
    uint256 userBalance;
    uint256 totalSupply;
  }

  struct UserData {
    // Liquidity index of the reward distribution for the user
    uint104 index;
    // Amount of accrued rewards for the user since last user index update
    uint128 accrued;
  }

  struct RewardData {
    // Liquidity index of the reward distribution
    uint104 index;
    // Amount of reward tokens distributed per second
    uint88 emissionPerSecond;
    // Timestamp of the last reward index update
    uint32 lastUpdateTimestamp;
    // The end of the distribution of rewards (in seconds)
    uint32 distributionEnd;
    // Map of user addresses and their rewards data (userAddress => userData)
    mapping(address => UserData) usersData;
  }

  struct AssetData {
    // Map of reward token addresses and their data (rewardTokenAddress => rewardData)
    mapping(address => RewardData) rewards;
    // List of reward token addresses for the asset
    mapping(uint128 => address) availableRewards;
    // Count of reward tokens for the asset
    uint128 availableRewardsCount;
    // Number of decimals of the asset
    uint8 decimals;
  }
}

// downloads/LINEA/EMISSION_MANAGER/EmissionManager/src/contracts/rewards/interfaces/IRewardsController.sol

/**
 * @title IRewardsController
 * @author Aave
 * @notice Defines the basic interface for a Rewards Controller.
 */
interface IRewardsController is IRewardsDistributor {
  /**
   * @dev Emitted when a new address is whitelisted as claimer of rewards on behalf of a user
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  event ClaimerSet(address indexed user, address indexed claimer);

  /**
   * @dev Emitted when rewards are claimed
   * @param user The address of the user rewards has been claimed on behalf of
   * @param reward The address of the token reward is claimed
   * @param to The address of the receiver of the rewards
   * @param claimer The address of the claimer
   * @param amount The amount of rewards claimed
   */
  event RewardsClaimed(
    address indexed user,
    address indexed reward,
    address indexed to,
    address claimer,
    uint256 amount
  );

  /**
   * @dev Emitted when a transfer strategy is installed for the reward distribution
   * @param reward The address of the token reward
   * @param transferStrategy The address of TransferStrategy contract
   */
  event TransferStrategyInstalled(address indexed reward, address indexed transferStrategy);

  /**
   * @dev Emitted when the reward oracle is updated
   * @param reward The address of the token reward
   * @param rewardOracle The address of oracle
   */
  event RewardOracleUpdated(address indexed reward, address indexed rewardOracle);

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Sets a TransferStrategy logic contract that determines the logic of the rewards transfer
   * @param reward The address of the reward token
   * @param transferStrategy The address of the TransferStrategy logic contract
   */
  function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external;

  /**
   * @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
   * @notice At the moment of reward configuration, the Incentives Controller performs
   * a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
   * This check is enforced for integrators to be able to show incentives at
   * the current Aave UI without the need to setup an external price registry
   * @param reward The address of the reward to set the price aggregator
   * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
   */
  function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

  /**
   * @dev Get the price aggregator oracle address
   * @param reward The address of the reward
   * @return The price oracle of the reward
   */
  function getRewardOracle(address reward) external view returns (address);

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Returns the Transfer Strategy implementation contract address being used for a reward address
   * @param reward The address of the reward
   * @return The address of the TransferStrategy contract
   */
  function getTransferStrategy(address reward) external view returns (address);

  /**
   * @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
   * @param config The assets configuration input, the list of structs contains the following fields:
   *   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
   *   uint256 totalSupply: The total supply of the asset to incentivize
   *   uint40 distributionEnd: The end of the distribution of the incentives for an asset
   *   address asset: The asset address to incentivize
   *   address reward: The reward token address
   *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
   *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
   *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
   */
  function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

  /**
   * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
   * @dev The units of `totalSupply` and `userBalance` should be the same.
   * @param user The address of the user whose asset balance has changed
   * @param totalSupply The total supply of the asset prior to user balance change
   * @param userBalance The previous user balance prior to balance change
   **/
  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;

  /**
   * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets List of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
   * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsToSelf(
    address[] calldata assets,
    uint256 amount,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
   **/
  function claimAllRewards(
    address[] calldata assets,
    address to
  ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  /**
   * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  /**
   * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsToSelf(
    address[] calldata assets
  ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// downloads/LINEA/EMISSION_MANAGER/EmissionManager/src/contracts/rewards/interfaces/IEmissionManager.sol

/**
 * @title IEmissionManager
 * @author Aave
 * @notice Defines the basic interface for the Emission Manager
 */
interface IEmissionManager {
  /**
   * @dev Emitted when the admin of a reward emission is updated.
   * @param reward The address of the rewarding token
   * @param oldAdmin The address of the old emission admin
   * @param newAdmin The address of the new emission admin
   */
  event EmissionAdminUpdated(
    address indexed reward,
    address indexed oldAdmin,
    address indexed newAdmin
  );

  /**
   * @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
   * @dev Only callable by the emission admin of the given rewards
   * @param config The assets configuration input, the list of structs contains the following fields:
   *   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
   *   uint256 totalSupply: The total supply of the asset to incentivize
   *   uint40 distributionEnd: The end of the distribution of the incentives for an asset
   *   address asset: The asset address to incentivize
   *   address reward: The reward token address
   *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
   *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
   *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
   */
  function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

  /**
   * @dev Sets a TransferStrategy logic contract that determines the logic of the rewards transfer
   * @dev Only callable by the emission admin of the given reward
   * @param reward The address of the reward token
   * @param transferStrategy The address of the TransferStrategy logic contract
   */
  function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external;

  /**
   * @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
   * @dev Only callable by the emission admin of the given reward
   * @notice At the moment of reward configuration, the Incentives Controller performs
   * a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
   * This check is enforced for integrators to be able to show incentives at
   * the current Aave UI without the need to setup an external price registry
   * @param reward The address of the reward to set the price aggregator
   * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
   */
  function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

  /**
   * @dev Sets the end date for the distribution
   * @dev Only callable by the emission admin of the given reward
   * @param asset The asset to incentivize
   * @param reward The reward token that incentives the asset
   * @param newDistributionEnd The end date of the incentivization, in unix time format
   **/
  function setDistributionEnd(address asset, address reward, uint32 newDistributionEnd) external;

  /**
   * @dev Sets the emission per second of a set of reward distributions
   * @param asset The asset is being incentivized
   * @param rewards List of reward addresses are being distributed
   * @param newEmissionsPerSecond List of new reward emissions per second
   */
  function setEmissionPerSecond(
    address asset,
    address[] calldata rewards,
    uint88[] calldata newEmissionsPerSecond
  ) external;

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @dev Only callable by the owner of the EmissionManager
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Updates the admin of the reward emission
   * @dev Only callable by the owner of the EmissionManager
   * @param reward The address of the reward token
   * @param admin The address of the new admin of the emission
   */
  function setEmissionAdmin(address reward, address admin) external;

  /**
   * @dev Updates the address of the rewards controller
   * @dev Only callable by the owner of the EmissionManager
   * @param controller the address of the RewardsController contract
   */
  function setRewardsController(address controller) external;

  /**
   * @dev Returns the rewards controller address
   * @return The address of the RewardsController contract
   */
  function getRewardsController() external view returns (IRewardsController);

  /**
   * @dev Returns the admin of the given reward emission
   * @param reward The address of the reward token
   * @return The address of the emission admin
   */
  function getEmissionAdmin(address reward) external view returns (address);
}

// downloads/LINEA/EMISSION_MANAGER/EmissionManager/src/contracts/rewards/EmissionManager.sol

/**
 * @title EmissionManager
 * @author Aave
 * @notice It manages the list of admins of reward emissions and provides functions to control reward emissions.
 */
contract EmissionManager is Ownable, IEmissionManager {
  // reward => emissionAdmin
  mapping(address => address) internal _emissionAdmins;

  IRewardsController internal _rewardsController;

  /**
   * @dev Only emission admin of the given reward can call functions marked by this modifier.
   **/
  modifier onlyEmissionAdmin(address reward) {
    require(msg.sender == _emissionAdmins[reward], 'ONLY_EMISSION_ADMIN');
    _;
  }

  /**
   * Constructor.
   * @param owner The address of the owner
   */
  constructor(address owner) {
    transferOwnership(owner);
  }

  /// @inheritdoc IEmissionManager
  function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external override {
    for (uint256 i = 0; i < config.length; i++) {
      require(_emissionAdmins[config[i].reward] == msg.sender, 'ONLY_EMISSION_ADMIN');
    }
    _rewardsController.configureAssets(config);
  }

  /// @inheritdoc IEmissionManager
  function setTransferStrategy(
    address reward,
    ITransferStrategyBase transferStrategy
  ) external override onlyEmissionAdmin(reward) {
    _rewardsController.setTransferStrategy(reward, transferStrategy);
  }

  /// @inheritdoc IEmissionManager
  function setRewardOracle(
    address reward,
    IEACAggregatorProxy rewardOracle
  ) external override onlyEmissionAdmin(reward) {
    _rewardsController.setRewardOracle(reward, rewardOracle);
  }

  /// @inheritdoc IEmissionManager
  function setDistributionEnd(
    address asset,
    address reward,
    uint32 newDistributionEnd
  ) external override onlyEmissionAdmin(reward) {
    _rewardsController.setDistributionEnd(asset, reward, newDistributionEnd);
  }

  /// @inheritdoc IEmissionManager
  function setEmissionPerSecond(
    address asset,
    address[] calldata rewards,
    uint88[] calldata newEmissionsPerSecond
  ) external override {
    for (uint256 i = 0; i < rewards.length; i++) {
      require(_emissionAdmins[rewards[i]] == msg.sender, 'ONLY_EMISSION_ADMIN');
    }
    _rewardsController.setEmissionPerSecond(asset, rewards, newEmissionsPerSecond);
  }

  /// @inheritdoc IEmissionManager
  function setClaimer(address user, address claimer) external override onlyOwner {
    _rewardsController.setClaimer(user, claimer);
  }

  /// @inheritdoc IEmissionManager
  function setEmissionAdmin(address reward, address admin) external override onlyOwner {
    address oldAdmin = _emissionAdmins[reward];
    _emissionAdmins[reward] = admin;
    emit EmissionAdminUpdated(reward, oldAdmin, admin);
  }

  /// @inheritdoc IEmissionManager
  function setRewardsController(address controller) external override onlyOwner {
    _rewardsController = IRewardsController(controller);
  }

  /// @inheritdoc IEmissionManager
  function getRewardsController() external view override returns (IRewardsController) {
    return _rewardsController;
  }

  /// @inheritdoc IEmissionManager
  function getEmissionAdmin(address reward) external view override returns (address) {
    return _emissionAdmins[reward];
  }
}
