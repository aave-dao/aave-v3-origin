// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC20Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/interfaces/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

import {IRewardsController} from '../../rewards/interfaces/IRewardsController.sol';
import {IERC20AaveLM} from './interfaces/IERC20AaveLM.sol';

/**
 * @title ERC20AaveLMUpgradeable.sol
 * @notice Wrapper smart contract that supports tracking and claiming liquidity mining rewards from the Aave system
 * @dev ERC20 extension, so ERC20 initialization should be done by the children contract/s
 * @author BGD labs
 */
abstract contract ERC20AaveLMUpgradeable is ERC20Upgradeable, IERC20AaveLM {
  using SafeCast for uint256;

  /// @custom:storage-location erc7201:aave-dao.storage.ERC20AaveLM
  struct ERC20AaveLMStorage {
    address _referenceAsset; // a/v token to track rewards on INCENTIVES_CONTROLLER
    address[] _rewardTokens;
    mapping(address reward => RewardIndexCache cache) _startIndex;
    mapping(address user => mapping(address reward => UserRewardsData cache)) _userRewardsData;
  }

  // keccak256(abi.encode(uint256(keccak256("aave-dao.storage.ERC20AaveLM")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant ERC20AaveLMStorageLocation =
    0x4fad66563f105be0bff96185c9058c4934b504d3ba15ca31e86294f0b01fd200;

  function _getERC20AaveLMStorage() private pure returns (ERC20AaveLMStorage storage $) {
    assembly {
      $.slot := ERC20AaveLMStorageLocation
    }
  }

  IRewardsController public immutable INCENTIVES_CONTROLLER;

  constructor(IRewardsController rewardsController) {
    if (address(rewardsController) == address(0)) {
      revert ZeroIncentivesControllerIsForbidden();
    }
    INCENTIVES_CONTROLLER = rewardsController;
  }

  function __ERC20AaveLM_init(address referenceAsset_) internal onlyInitializing {
    __ERC20AaveLM_init_unchained(referenceAsset_);
  }

  function __ERC20AaveLM_init_unchained(address referenceAsset_) internal onlyInitializing {
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    $._referenceAsset = referenceAsset_;

    if (INCENTIVES_CONTROLLER != IRewardsController(address(0))) {
      refreshRewardTokens();
    }
  }

  ///@inheritdoc IERC20AaveLM
  function claimRewardsOnBehalf(
    address onBehalfOf,
    address receiver,
    address[] memory rewards
  ) external {
    address msgSender = _msgSender();
    if (msgSender != onBehalfOf && msgSender != INCENTIVES_CONTROLLER.getClaimer(onBehalfOf)) {
      revert InvalidClaimer(msgSender);
    }

    _claimRewardsOnBehalf(onBehalfOf, receiver, rewards);
  }

  ///@inheritdoc IERC20AaveLM
  function claimRewards(address receiver, address[] memory rewards) external {
    _claimRewardsOnBehalf(_msgSender(), receiver, rewards);
  }

  ///@inheritdoc IERC20AaveLM
  function claimRewardsToSelf(address[] memory rewards) external {
    _claimRewardsOnBehalf(_msgSender(), _msgSender(), rewards);
  }

  ///@inheritdoc IERC20AaveLM
  function refreshRewardTokens() public override {
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    address[] memory rewards = INCENTIVES_CONTROLLER.getRewardsByAsset($._referenceAsset);
    for (uint256 i = 0; i < rewards.length; i++) {
      _registerRewardToken(rewards[i]);
    }
  }

  ///@inheritdoc IERC20AaveLM
  function collectAndUpdateRewards(address reward) public returns (uint256) {
    if (reward == address(0)) {
      return 0;
    }

    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    address[] memory assets = new address[](1);
    assets[0] = address($._referenceAsset);

    return INCENTIVES_CONTROLLER.claimRewards(assets, type(uint256).max, address(this), reward);
  }

  ///@inheritdoc IERC20AaveLM
  function isRegisteredRewardToken(address reward) public view override returns (bool) {
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    return $._startIndex[reward].isRegistered;
  }

  ///@inheritdoc IERC20AaveLM
  function getCurrentRewardsIndex(address reward) public view returns (uint256) {
    if (address(reward) == address(0)) {
      return 0;
    }
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    (, uint256 nextIndex) = INCENTIVES_CONTROLLER.getAssetIndex($._referenceAsset, reward);
    return nextIndex;
  }

  ///@inheritdoc IERC20AaveLM
  function getTotalClaimableRewards(address reward) external view returns (uint256) {
    if (reward == address(0)) {
      return 0;
    }

    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    address[] memory assets = new address[](1);
    assets[0] = $._referenceAsset;
    uint256 freshRewards = INCENTIVES_CONTROLLER.getUserRewards(assets, address(this), reward);
    return IERC20(reward).balanceOf(address(this)) + freshRewards;
  }

  ///@inheritdoc IERC20AaveLM
  function getClaimableRewards(address user, address reward) external view returns (uint256) {
    return _getClaimableRewards(user, reward, balanceOf(user), getCurrentRewardsIndex(reward));
  }

  ///@inheritdoc IERC20AaveLM
  function getUnclaimedRewards(address user, address reward) external view returns (uint256) {
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    return $._userRewardsData[user][reward].unclaimedRewards;
  }

  ///@inheritdoc IERC20AaveLM
  function getReferenceAsset() external view returns (address) {
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    return $._referenceAsset;
  }

  ///@inheritdoc IERC20AaveLM
  function rewardTokens() external view returns (address[] memory) {
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    return $._rewardTokens;
  }

  /**
   * @notice Updates rewards for senders and receiver in a transfer (not updating rewards for address(0))
   * @param from The address of the sender of tokens
   * @param to The address of the receiver of tokens
   */
  function _update(address from, address to, uint256 amount) internal virtual override {
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    for (uint256 i = 0; i < $._rewardTokens.length; i++) {
      address rewardToken = address($._rewardTokens[i]);
      uint256 rewardsIndex = getCurrentRewardsIndex(rewardToken);
      if (from != address(0)) {
        _updateUser(from, rewardsIndex, rewardToken);
      }
      if (to != address(0) && from != to) {
        _updateUser(to, rewardsIndex, rewardToken);
      }
    }
    super._update(from, to, amount);
  }

  /**
   * @notice Adding the pending rewards to the unclaimed for specific user and updating user index
   * @param user The address of the user to update
   * @param currentRewardsIndex The current rewardIndex
   * @param rewardToken The address of the reward token
   */
  function _updateUser(address user, uint256 currentRewardsIndex, address rewardToken) internal {
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    uint256 balance = balanceOf(user);
    if (balance > 0) {
      $._userRewardsData[user][rewardToken].unclaimedRewards = _getClaimableRewards(
        user,
        rewardToken,
        balance,
        currentRewardsIndex
      ).toUint128();
    }
    $._userRewardsData[user][rewardToken].rewardsIndexOnLastInteraction = currentRewardsIndex
      .toUint128();
  }

  /**
   * @notice Compute the pending in asset decimals. Pending is the amount to add (not yet unclaimed) rewards in asset decimals.
   * @param balance The balance of the user
   * @param rewardsIndexOnLastInteraction The index which was on the last interaction of the user
   * @param currentRewardsIndex The current rewards index in the system
   * @return The amount of pending rewards in asset decimals
   */
  function _getPendingRewards(
    uint256 balance,
    uint256 rewardsIndexOnLastInteraction,
    uint256 currentRewardsIndex
  ) internal view returns (uint256) {
    if (balance == 0) {
      return 0;
    }
    return (balance * (currentRewardsIndex - rewardsIndexOnLastInteraction)) / 10 ** decimals();
  }

  /**
   * @notice Compute the claimable rewards for a user
   * @param user The address of the user
   * @param reward The address of the reward
   * @param balance The balance of the user in asset decimals
   * @param currentRewardsIndex The current rewards index
   * @return The total rewards that can be claimed by the user (if `fresh` flag true, after updating rewards)
   */
  function _getClaimableRewards(
    address user,
    address reward,
    uint256 balance,
    uint256 currentRewardsIndex
  ) internal view returns (uint256) {
    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    RewardIndexCache memory rewardsIndexCache = $._startIndex[reward];
    if (!rewardsIndexCache.isRegistered) {
      revert RewardNotInitialized(reward);
    }

    UserRewardsData memory currentUserRewardsData = $._userRewardsData[user][reward];
    return
      currentUserRewardsData.unclaimedRewards +
      _getPendingRewards(
        balance,
        currentUserRewardsData.rewardsIndexOnLastInteraction == 0
          ? rewardsIndexCache.lastUpdatedIndex
          : currentUserRewardsData.rewardsIndexOnLastInteraction,
        currentRewardsIndex
      );
  }

  /**
   * @notice Claim rewards on behalf of a user and send them to a receiver
   * @param onBehalfOf The address to claim on behalf of
   * @param rewards The addresses of the rewards
   * @param receiver The address to receive the rewards
   */
  function _claimRewardsOnBehalf(
    address onBehalfOf,
    address receiver,
    address[] memory rewards
  ) internal virtual {
    for (uint256 i = 0; i < rewards.length; i++) {
      if (address(rewards[i]) == address(0)) {
        continue;
      }
      uint256 currentRewardsIndex = getCurrentRewardsIndex(rewards[i]);
      uint256 balance = balanceOf(onBehalfOf);
      uint256 userReward = _getClaimableRewards(
        onBehalfOf,
        rewards[i],
        balance,
        currentRewardsIndex
      );
      uint256 totalRewardTokenBalance = IERC20(rewards[i]).balanceOf(address(this));
      uint256 unclaimedReward = 0;

      if (userReward > totalRewardTokenBalance) {
        totalRewardTokenBalance += collectAndUpdateRewards(address(rewards[i]));
      }

      if (userReward > totalRewardTokenBalance) {
        unclaimedReward = userReward - totalRewardTokenBalance;
        userReward = totalRewardTokenBalance;
      }
      if (userReward > 0) {
        ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
        $._userRewardsData[onBehalfOf][rewards[i]].unclaimedRewards = unclaimedReward.toUint128();
        $
        ._userRewardsData[onBehalfOf][rewards[i]]
          .rewardsIndexOnLastInteraction = currentRewardsIndex.toUint128();
        SafeERC20.safeTransfer(IERC20(rewards[i]), receiver, userReward);
      }
    }
  }

  /**
   * @notice Initializes a new rewardToken
   * @param reward The reward token to be registered
   */
  function _registerRewardToken(address reward) internal {
    if (isRegisteredRewardToken(reward)) return;
    uint256 startIndex = getCurrentRewardsIndex(reward);

    ERC20AaveLMStorage storage $ = _getERC20AaveLMStorage();
    $._rewardTokens.push(reward);
    $._startIndex[reward] = RewardIndexCache(true, startIndex.toUint248());

    emit RewardTokenRegistered(reward, startIndex);
  }
}
