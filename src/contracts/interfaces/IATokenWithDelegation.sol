// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAToken} from './IAToken.sol';
import {IBaseDelegation} from '../protocol/tokenization/delegation/interfaces/IBaseDelegation.sol';

/**
 * @notice Interface for an AToken with delegation capabilities.
 * @dev Extends the IAToken interface to add functions for delegating voting and proposition power.
 */
interface IATokenWithDelegation is IAToken, IBaseDelegation {}
