// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPool} from '../../../../contracts/interfaces/IPool.sol';
import {IAaveOracle} from '../../../../contracts/interfaces/IAaveOracle.sol';

interface IStataOracle {
  /**
   * @return The pool used for fetching the rate on the aggregator oracle
   */
  function POOL() external view returns (IPool);

  /**
   * @return The aave oracle used for fetching the price of the underlying
   */
  function AAVE_ORACLE() external view returns (IAaveOracle);

  /**
   * @notice Returns the prices of an asset address
   * @param asset The asset address
   * @return The prices of the given asset
   */
  function getAssetPrice(address asset) external view returns (uint256);

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
}
