// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {ITransferStrategyBase} from './ITransferStrategyBase.sol';

/**
 * @title IPullRewardsTransferStrategy
 * @author Aave
 **/
interface IPullRewardsTransferStrategy is ITransferStrategyBase {
  /**
   * @return Address of the rewards vault
   */
  function getRewardsVault() external view returns (address);
}
