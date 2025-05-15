// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IRwaAToken
 * @author Aave
 * @notice Defines the basic interface for an RwaAToken.
 */
interface IRwaAToken {
  /**
   * @notice Permits are not supported for RWA aTokens.
   * @dev Reverts if called.
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Approvals are not supported for RWA aTokens.
   * @dev Reverts if called.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @notice Allowances are not supported for RWA aTokens.
   * @dev Reverts if called.
   */
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

  /**
   * @notice Allowances are not supported for RWA aTokens.
   * @dev Reverts if called.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

  /**
   * @notice Transfers are not supported for RWA aTokens.
   * @dev Reverts if called.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @notice Transfers are not supported for RWA aTokens.
   * @dev Reverts if called.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @notice Transfers are not supported in liquidations.
   * @dev Reverts if called.
   */
  function transferOnLiquidation(address from, address to, uint256 value) external;

  /**
   * @notice Transfers an amount of aTokens between two users.
   * @dev It checks for valid HF after the tranfer.
   * @dev Only callable by transfer role admin.
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param amount The amount to be transferred.
   * @return True if the transfer was successful, false otherwise.
   */
  function authorizedTransfer(address from, address to, uint256 amount) external returns (bool);

  /**
   * @notice Returns the identifier of the AuthorizedATokenTransfer role
   * @return The id of the AuthorizedATokenTransfer role
   */
  function AUTHORIZED_ATOKEN_TRANSFER_ROLE() external pure returns (bytes32);
}
