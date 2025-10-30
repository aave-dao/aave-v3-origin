// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @dev minimal interface for the Llama Risk RWA Oracle parameter registry
interface IParameterRegistry {
  function assetExists(address asset) external view returns (bool);

  function getParametersForAsset(
    address asset
  )
    external
    view
    returns (
      uint64 maxExpectedApy,
      uint32 upperBoundTolerance,
      uint32 lowerBoundTolerance,
      uint32 maxDiscount,
      uint80 lookbackWindowSize,
      bool isUpperBoundEnabled,
      bool isLowerBoundEnabled,
      bool isActionTakingEnabled
    );

  function getLookbackData(
    address asset
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getOracle(address asset) external view returns (address);

  function owner() external view returns (address);

  function updater() external view returns (address);
}
