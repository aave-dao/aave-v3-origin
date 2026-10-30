// SPDX-License-Identifier: LicenseRef-BUSL
pragma solidity ^0.8.0;

import {DeployAaveV3MarketBatchedBase} from './misc/DeployAaveV3MarketBatchedBase.sol';

import {DefaultMarketInput} from '../src/deployments/inputs/DefaultMarketInput.sol';

contract Default is DeployAaveV3MarketBatchedBase, DefaultMarketInput {}
