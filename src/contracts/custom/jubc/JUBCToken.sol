// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {GhoToken} from 'gho-origin/gho/GhoToken.sol';

/**
 * @title AIEN Token (ZaiBots AI Economic Nation)
 * @notice GHO-based stablecoin with custom branding
 */
contract JUBCToken is GhoToken {
  constructor(address admin) GhoToken(admin) {
    name = string('ZaiBots AI Economic Nation');
    symbol = string('AIEN');
  }
}
