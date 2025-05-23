// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {DeployAaveV3MarketBatchedBase} from './misc/DeployAaveV3MarketBatchedBase.sol';

import {MainnetInput} from '../src/deployments/inputs/MainnetInput.sol';

contract Default is DeployAaveV3MarketBatchedBase, MainnetInput {}
