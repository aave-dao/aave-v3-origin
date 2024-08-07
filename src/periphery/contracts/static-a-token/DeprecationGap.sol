// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

/**
 * This contract adds a single slot gap
 * The slot is required to account for the now deprecated initializable
 */
contract DeprecationGap {
  uint256 internal __gap;
}
