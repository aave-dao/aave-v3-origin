// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRevenueSplitter} from './IRevenueSplitter.sol';
import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from 'aave-v3-core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {PercentageMath} from 'aave-v3-core/contracts/protocol/libraries/math/PercentageMath.sol';

/**
 * @title RevenueSplitter
 * @author Catapulta
 * @dev This periphery contract is responsible for splitting funds between two recipients.
 *      Replace COLLECTOR in ATokens or Debt Tokens with RevenueSplitter, and them set COLLECTORs as recipients.
 */
contract RevenueSplitter is IRevenueSplitter {
  using GPv2SafeERC20 for IERC20;
  using PercentageMath for uint256;

  address public immutable RECIPIENT_A;
  address public immutable RECIPIENT_B;

  uint16 public immutable SPLIT_PERCENTAGE_RECIPIENT_A;

  constructor(address recipientA, address recipientB, uint16 splitPercentageRecipientA) {
    if (
      splitPercentageRecipientA == 0 ||
      splitPercentageRecipientA >= PercentageMath.PERCENTAGE_FACTOR
    ) {
      revert InvalidPercentSplit();
    }
    RECIPIENT_A = recipientA;
    RECIPIENT_B = recipientB;
    SPLIT_PERCENTAGE_RECIPIENT_A = splitPercentageRecipientA;
  }

  /// @inheritdoc IRevenueSplitter
  function splitRevenue(IERC20[] memory tokens) external {
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
}
