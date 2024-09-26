// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {IRevenueSplitter} from './IRevenueSplitter.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {PercentageMath} from '../protocol/libraries/math/PercentageMath.sol';
import {ReentrancyGuard} from '../dependencies/openzeppelin/ReentrancyGuard.sol';

/**
 * @title RevenueSplitter
 * @author Catapulta
 * @dev This periphery contract is responsible for splitting funds between two recipients.
 *      Replace COLLECTOR in ATokens or Debt Tokens with RevenueSplitter, and them set COLLECTORs as recipients.
 */
contract RevenueSplitter is IRevenueSplitter, ReentrancyGuard {
  using GPv2SafeERC20 for IERC20;
  using PercentageMath for uint256;

  address payable public immutable RECIPIENT_A;
  address payable public immutable RECIPIENT_B;

  uint16 public immutable SPLIT_PERCENTAGE_RECIPIENT_A;

  constructor(address recipientA, address recipientB, uint16 splitPercentageRecipientA) {
    if (
      splitPercentageRecipientA == 0 ||
      splitPercentageRecipientA >= PercentageMath.PERCENTAGE_FACTOR
    ) {
      revert InvalidPercentSplit();
    }
    RECIPIENT_A = payable(recipientA);
    RECIPIENT_B = payable(recipientB);
    SPLIT_PERCENTAGE_RECIPIENT_A = splitPercentageRecipientA;
  }

  /// @inheritdoc IRevenueSplitter
  function splitRevenue(IERC20[] memory tokens) external nonReentrant {
    for (uint8 x; x < tokens.length; ++x) {
      uint256 balance = tokens[x].balanceOf(address(this));

      if (balance == 0) {
        continue;
      }

      uint256 amount_A = balance.percentMul(SPLIT_PERCENTAGE_RECIPIENT_A);
      uint256 amount_B = balance - amount_A;

      tokens[x].safeTransfer(RECIPIENT_A, amount_A);
      tokens[x].safeTransfer(RECIPIENT_B, amount_B);
    }
  }

  /// @inheritdoc IRevenueSplitter
  function splitNativeRevenue() external nonReentrant {
    uint256 balance = address(this).balance;

    if (balance == 0) {
      return;
    }

    uint256 amount_A = balance.percentMul(SPLIT_PERCENTAGE_RECIPIENT_A);
    uint256 amount_B = balance - amount_A;

    // Do not revert if fails to send to RECIPIENT_A or RECIPIENT_B, to prevent one recipient from blocking the other
    // if recipient does not accept native currency via fallback function or receive.
    // This can also be used as a manual recovery mechanism in case of an account does not support receiving native currency.
    RECIPIENT_A.call{value: amount_A}('');
    RECIPIENT_B.call{value: amount_B}('');
  }

  receive() external payable {}
}
