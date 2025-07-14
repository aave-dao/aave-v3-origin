// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {DeployAaveV3MarketBatchedBase} from './misc/DeployAaveV3MarketBatchedBase.sol';

import {HorizonInput} from '../src/deployments/inputs/HorizonInput.sol';

contract Default is DeployAaveV3MarketBatchedBase, HorizonInput {}
