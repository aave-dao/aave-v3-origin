// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

interface IRevenueSplitterErrors {
  error InvalidPercentSplit();
}

interface IRevenueSplitter is IRevenueSplitterErrors {
  /// @notice Split token balances in RevenueSplitter and transfer between two recipients
  /// @param tokens List of tokens to check balance and split amounts
  function splitRevenue(IERC20[] memory tokens) external;

  /// @notice Split native currency in RevenueSplitter and transfer between two recipients
  function splitNativeRevenue() external;

  function RECIPIENT_A() external view returns (address payable);

  function RECIPIENT_B() external view returns (address payable);

  /// @dev Percentage of the split that goes to RECIPIENT_A, the diff goes to RECIPIENT_B, from 1 to 99_99
  function SPLIT_PERCENTAGE_RECIPIENT_A() external view returns (uint16);
}
