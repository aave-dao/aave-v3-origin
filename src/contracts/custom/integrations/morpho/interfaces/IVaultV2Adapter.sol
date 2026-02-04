// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title IVaultV2Adapter
 * @notice Interface for Morpho Vault V2 adapters
 * @dev Adapters hold positions and implement realAssets() for NAV calculation
 */
interface IVaultV2Adapter {
  event Allocated(uint256 assets, bytes data);
  event Deallocated(uint256 assets, bytes data);

  function allocate(
    bytes memory data,
    uint256 assets,
    bytes4 selector,
    address caller
  ) external returns (bytes32[] memory ids, int256 delta);

  function deallocate(
    bytes memory data,
    uint256 assets,
    bytes4 selector,
    address caller
  ) external returns (bytes32[] memory ids, int256 delta);

  function realAssets() external view returns (uint256);
  function ids() external view returns (bytes32[] memory);
  function vault() external view returns (address);
  function asset() external view returns (address);
}
