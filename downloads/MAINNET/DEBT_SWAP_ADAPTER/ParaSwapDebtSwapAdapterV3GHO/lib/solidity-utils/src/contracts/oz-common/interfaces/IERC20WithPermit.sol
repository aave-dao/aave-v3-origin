// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from './IERC20.sol';
import {IERC20Permit} from './draft-IERC20Permit.sol';

interface IERC20WithPermit is IERC20, IERC20Permit {}
