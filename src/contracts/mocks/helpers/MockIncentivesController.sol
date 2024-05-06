// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IAaveIncentivesController} from '../../interfaces/IAaveIncentivesController.sol';

contract MockIncentivesController is IAaveIncentivesController {
  function handleAction(address, uint256, uint256) external override {}
}
