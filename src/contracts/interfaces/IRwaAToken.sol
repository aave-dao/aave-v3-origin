// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IRwaAToken
 * @author Aave
 * @notice Defines the basic interface for an RwaAToken.
 */
interface IRwaAToken {
  /**
   * @dev Emitted during the authorizedTransfer action
   * @param caller The address performing the authorized transfer
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param amount The amount being transferred
   */
  event AuthorizedTransfer(
    address indexed caller,
    address indexed from,
    address indexed to,
    uint256 amount
  );

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
   * @notice Not supported for RWA aTokens.
   * @dev Reverts if called.
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @notice Transfers are not supported in liquidations.
   * @dev Reverts if called.
   */
  function transferOnLiquidation(address from, address to, uint256 value) external;

  /**
   * @notice Transfers of the underlying asset are not supported for RWA aTokens.
   * @dev Reverts if called.
   */
  function transferUnderlyingTo(address target, uint256 amount) external;

  /**
   * @notice Transfers an amount of aTokens between two users.
   * @dev It checks for valid HF after the tranfer.
   * @dev Only callable by aToken admin.
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param amount The amount to be transferred.
   * @return True if the transfer was successful, false otherwise.
   */
  function authorizedTransfer(address from, address to, uint256 amount) external returns (bool);

  /**
   * @notice Mints `amount` aTokens to `user`.
   * @dev onBehalfOf must match the caller.
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted aTokens
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address caller,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @notice Returns the identifier of the ATokenAdmin role
   * @return The id of the ATokenAdmin role
   */
  function ATOKEN_ADMIN_ROLE() external pure returns (bytes32);
}
