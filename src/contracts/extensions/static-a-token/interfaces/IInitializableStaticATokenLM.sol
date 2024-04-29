// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPool} from '../../../interfaces/IPool.sol';
import {IAaveIncentivesController} from '../../../interfaces/IAaveIncentivesController.sol';

/**
 * @title IInitializableStaticATokenLM
 * @notice Interface for the initialize function on StaticATokenLM
 * @author Aave
 **/
interface IInitializableStaticATokenLM {
  /**
   * @dev Emitted when a StaticATokenLM is initialized
   * @param aToken The address of the underlying aToken (aWETH)
   * @param staticATokenName The name of the Static aToken
   * @param staticATokenSymbol The symbol of the Static aToken
   **/
  event Initialized(address indexed aToken, string staticATokenName, string staticATokenSymbol);

  /**
   * @dev Initializes the StaticATokenLM
   * @param aToken The address of the underlying aToken (aWETH)
   * @param staticATokenName The name of the Static aToken
   * @param staticATokenSymbol The symbol of the Static aToken
   */
  function initialize(
    address aToken,
    string calldata staticATokenName,
    string calldata staticATokenSymbol
  ) external;
}
