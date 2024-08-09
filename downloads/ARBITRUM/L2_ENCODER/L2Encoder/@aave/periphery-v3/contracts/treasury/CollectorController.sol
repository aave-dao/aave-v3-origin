// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {Ownable} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol';
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {ICollector} from './interfaces/ICollector.sol';

/**
 * @title CollectorController
 * @notice The CollectorController contracts allows the owner of the contract
           to approve or transfer tokens from the collector proxy contract.
           The admin of the Collector proxy can't be the same as the fundsAdmin address.
           This is needed due the usage of transparent proxy pattern.
 * @author Aave
 **/
contract CollectorController is Ownable {
  ICollector public immutable COLLECTOR;

  /**
   * @dev Constructor setups the ownership of the contract and the collector proxy
   * @param owner The address of the owner of the CollectorController
   * @param collectorProxy The address of the Collector transparent proxy
   */
  constructor(address owner, address collectorProxy) {
    transferOwnership(owner);
    COLLECTOR = ICollector(collectorProxy);
  }

  /**
   * @dev Transfer an amount of tokens to the recipient.
   * @param token The address of the asset
   * @param recipient The address of the entity to transfer the tokens.
   * @param amount The amount to be transferred.
   */
  function approve(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    COLLECTOR.approve(token, recipient, amount);
  }

  /**
   * @dev Transfer an amount of tokens to the recipient.
   * @param token The address of the asset
   * @param recipient The address of the entity to transfer the tokens.
   * @param amount The amount to be transferred.
   */
  function transfer(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    COLLECTOR.transfer(token, recipient, amount);
  }
}
