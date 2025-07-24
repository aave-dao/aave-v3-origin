// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ICreditDelegationToken
 * @author Aave
 * @notice Defines the basic interface for a token supporting credit delegation.
 */
interface ICreditDelegationToken {
  /**
   * @dev Emitted on `approveDelegation` and `borrowAllowance
   * @param fromUser The address of the delegator
   * @param toUser The address of the delegatee
   * @param asset The address of the delegated asset
   * @param amount The amount being delegated
   */
  event BorrowAllowanceDelegated(
    address indexed fromUser,
    address indexed toUser,
    address indexed asset,
    uint256 amount
  );

  /**
   * @dev Indicates a failure with the `spender`’s `allowance`. Used in borrowing.
   * @param spender Address that may be allowed to operate on tokens without being their owner.
   * @param allowance Amount of tokens a `spender` is allowed to operate with.
   * @param needed Minimum amount required to perform a transfer.
   */
  error InsufficientBorrowAllowance(address spender, uint256 allowance, uint256 needed);

  /**
   * @notice Delegates borrowing power to a user on the specific debt token.
   * Delegation will still respect the liquidation constraints (even if delegated, a
   * delegatee cannot force a delegator HF to go below 1)
   * @param delegatee The address receiving the delegated borrowing power
   * @param amount The maximum amount being delegated.
   */
  function approveDelegation(address delegatee, uint256 amount) external;

  /**
   * @notice Returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return The current allowance of `toUser`
   */
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

  /**
   * @notice Delegates borrowing power to a user on the specific debt token via ERC712 signature
   * @param delegator The delegator of the credit
   * @param delegatee The delegatee that can use the credit
   * @param value The amount to be delegated
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v The V signature param
   * @param s The S signature param
   * @param r The R signature param
   */
  function delegationWithSig(
    address delegator,
    address delegatee,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}
