// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IAaveIncentivesController} from '../../../interfaces/IAaveIncentivesController.sol';
import {IPool} from '../../../interfaces/IPool.sol';
import {IncentivizedERC20} from './IncentivizedERC20.sol';

/**
 * @title MintableIncentivizedERC20
 * @author Aave
 * @notice Implements mint and burn functions for IncentivizedERC20
 */
abstract contract MintableIncentivizedERC20 is IncentivizedERC20 {
  /**
   * @dev Constructor.
   * @param pool The reference to the main Pool contract
   * @param name The name of the token
   * @param symbol The symbol of the token
   * @param decimals The number of decimals of the token
   * @param rewardsController The address of the rewards controller contract
   */
  constructor(
    IPool pool,
    string memory name,
    string memory symbol,
    uint8 decimals,
    address rewardsController
  ) IncentivizedERC20(pool, name, symbol, decimals, rewardsController) {
    // Intentionally left blank
  }

  /**
   * @notice Mints tokens to an account and apply incentives if defined
   * @param account The address receiving tokens
   * @param amount The amount of tokens to mint
   */
  function _mint(address account, uint120 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply + amount;

    uint120 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance + amount;

    if (address(REWARDS_CONTROLLER) != address(0)) {
      REWARDS_CONTROLLER.handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  /**
   * @notice Burns tokens from an account and apply incentives if defined
   * @param account The account whose tokens are burnt
   * @param amount The amount of tokens to burn
   */
  function _burn(address account, uint120 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply - amount;

    uint120 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance - amount;

    if (address(REWARDS_CONTROLLER) != address(0)) {
      REWARDS_CONTROLLER.handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }
}
