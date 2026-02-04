// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title IVerifierFeeManager
 * @notice Interface for Chainlink Data Streams fee manager
 */
interface IVerifierFeeManager {
  struct Asset {
    address assetAddress;
    uint256 amount;
  }

  function getFeeAndReward(
    address subscriber,
    bytes memory report,
    address quoteAddress
  ) external returns (Asset memory, Asset memory, uint256);

  function i_linkAddress() external view returns (address);
  function i_rewardManager() external view returns (address);
}
