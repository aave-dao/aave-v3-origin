// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

interface IRevenueSplitterErrors {
  error InvalidPercentSplit();
}

interface IRevenueSplitter is IRevenueSplitterErrors {
  function splitRevenue(IERC20[] memory tokens) external;

  function RECIPIENT_A() external view returns (address);

  function RECIPIENT_B() external view returns (address);

  function SPLIT_PERCENTAGE_RECIPIENT_A() external view returns (uint16);
}
