// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

/**
 * This contract adds a single slot gap
 * The slot is required to account for the now deprecated Initializable.
 * The new version of Initializable uses erc7201, so it no longer occupies the first slot.
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/proxy/utils/Initializable.sol#L60
 */
contract DeprecationGap {
  uint256 internal __deprecated;
}
