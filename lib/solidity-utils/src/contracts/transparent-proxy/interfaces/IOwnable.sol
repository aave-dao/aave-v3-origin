// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOwnable {
  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * @param newOwner address of the new owner.
   * Can only be called by the current owner.
   **/
  function transferOwnership(address newOwner) external;

  /**
   * @dev Returns the address of the current owner.
   **/
  function owner() external view returns (address);
}
