// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {ITransferStrategyBase} from '../interfaces/ITransferStrategyBase.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';

/**
 * @title TransferStrategyStorage
 * @author Aave
 **/
abstract contract TransferStrategyBase is ITransferStrategyBase {
  using GPv2SafeERC20 for IERC20;

  address internal immutable INCENTIVES_CONTROLLER;
  address internal immutable REWARDS_ADMIN;

  constructor(address incentivesController, address rewardsAdmin) {
    INCENTIVES_CONTROLLER = incentivesController;
    REWARDS_ADMIN = rewardsAdmin;
  }

  /**
   * @dev Modifier for incentives controller only functions
   */
  modifier onlyIncentivesController() {
    require(INCENTIVES_CONTROLLER == msg.sender, CallerNotIncentivesController());
    _;
  }

  /**
   * @dev Modifier for reward admin only functions
   */
  modifier onlyRewardsAdmin() {
    require(msg.sender == REWARDS_ADMIN, OnlyRewardsAdmin());
    _;
  }

  /// @inheritdoc ITransferStrategyBase
  function getIncentivesController() external view override returns (address) {
    return INCENTIVES_CONTROLLER;
  }

  /// @inheritdoc ITransferStrategyBase
  function getRewardsAdmin() external view override returns (address) {
    return REWARDS_ADMIN;
  }

  /// @inheritdoc ITransferStrategyBase
  function performTransfer(
    address to,
    address reward,
    uint256 amount
  ) external virtual returns (bool);

  /// @inheritdoc ITransferStrategyBase
  function emergencyWithdrawal(
    address token,
    address to,
    uint256 amount
  ) external onlyRewardsAdmin {
    IERC20(token).safeTransfer(to, amount);

    emit EmergencyWithdrawal(msg.sender, token, to, amount);
  }
}
