// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {AggregatorInterface} from '../dependencies/chainlink/AggregatorInterface.sol';
import {IEmissionManager} from './interfaces/IEmissionManager.sol';
import {ITransferStrategyBase} from './interfaces/ITransferStrategyBase.sol';
import {IRewardsController} from './interfaces/IRewardsController.sol';
import {RewardsDataTypes} from './libraries/RewardsDataTypes.sol';

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
    AggregatorInterface rewardOracle
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
