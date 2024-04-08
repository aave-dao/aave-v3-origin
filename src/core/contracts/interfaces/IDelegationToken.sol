// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDelegationToken
 * @author Aave
 * @notice Implements an interface for tokens with delegation COMP/UNI compatible
 */
interface IDelegationToken {
  /**
   * @notice Delegate voting power to a delegatee
   * @param delegatee The address of the delegatee
   */
  function delegate(address delegatee) external;
}
