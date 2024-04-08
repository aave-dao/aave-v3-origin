// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IStakedToken} from '../interfaces/IStakedToken.sol';
import {ITransferStrategyBase} from './ITransferStrategyBase.sol';

/**
 * @title IStakedTokenTransferStrategy
 * @author Aave
 **/
interface IStakedTokenTransferStrategy is ITransferStrategyBase {
  /**
   * @dev Perform a MAX_UINT approval of AAVE to the Staked Aave contract.
   */
  function renewApproval() external;

  /**
   * @dev Drop approval of AAVE to the Staked Aave contract in case of emergency.
   */
  function dropApproval() external;

  /**
   * @return Staked Token contract address
   */
  function getStakeContract() external view returns (address);

  /**
   * @return Underlying token address from the stake contract
   */
  function getUnderlyingToken() external view returns (address);
}
