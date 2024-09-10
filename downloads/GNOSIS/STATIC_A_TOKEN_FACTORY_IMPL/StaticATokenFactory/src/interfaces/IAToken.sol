// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {IAaveIncentivesController} from '../../lib/aave-helpers/lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IAaveIncentivesController.sol';

interface IAToken {
  function POOL() external view returns (address);

  function getIncentivesController() external view returns (address);

  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
   * @return The scaled total supply
   */
  function scaledTotalSupply() external view returns (uint256);
}
