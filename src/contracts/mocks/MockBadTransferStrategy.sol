// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ITransferStrategyBase} from '../rewards/interfaces/ITransferStrategyBase.sol';
import {TransferStrategyBase} from '../rewards/transfer-strategies/TransferStrategyBase.sol';
import {GPv2SafeERC20} from '../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';

/**
 * @title MockBadTransferStrategy
 * @notice Transfer strategy that always return false at performTransfer and does noop.
 * @author Aave
 **/
contract MockBadTransferStrategy is TransferStrategyBase {
  using GPv2SafeERC20 for IERC20;

  // Added storage variable to prevent warnings at compilation for performTransfer
  uint256 ignoreWarning;

  constructor(
    address incentivesController,
    address rewardsAdmin
  ) TransferStrategyBase(incentivesController, rewardsAdmin) {}

  /// @inheritdoc TransferStrategyBase
  function performTransfer(
    address,
    address,
    uint256
  ) external override onlyIncentivesController returns (bool) {
    ignoreWarning = 1;
    return false;
  }
}
