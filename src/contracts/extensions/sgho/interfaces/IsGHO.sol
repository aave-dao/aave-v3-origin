// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

/**
 * @title IsGHO Interface
 * @dev Interface for the sGHO contract, combining ERC4626, ERC20Permit, and custom logic.
 */
interface IsGHO {
  // --- Custom Errors ---

  /**
   * @dev Invalid signature.
   */
  error InvalidSignature();

  /**
   * @dev Thrown when a direct ETH transfer is attempted.
   */
  error NoEthAllowed();

  /**
   * @dev Only caller with FUNDS_ADMIN role can call
   */
  error OnlyFundsAdmin();

  /**
   * @dev Only YieldManager can call
   */
  error OnlyYieldManager();

  /**
   * @dev Throws if the contract is not initialized.
   */
  error NotInitialized();

  /**
   * @dev Throws if the GHO token is being rescued.
   */
  error CannotRescueGHO();
  
  // --- State Variables (as view functions) ---

  /**
   * @dev Returns the address of the underlying GHO token used by the vault.
   */
  function gho() external view returns (address);

  /**
   * @dev Returns the chain ID where the contract was deployed. Used for EIP-712 signature validation.
   */
  function deploymentChainId() external view returns (uint256);

  /**
   * @dev Returns the EIP-712 version string.
   */
  function VERSION() external view returns (string memory);

  /**
   * @dev Returns the current yield index.
   */
  function yieldIndex() external view returns (uint256);

  /**
   * @dev Returns the current target rate.
   */
  function targetRate() external view returns (uint256);

  /**
   * @dev Returns the last update timestamp.
   */
  function lastUpdate() external view returns (uint256);

  /**
   * @dev Returns the FUNDS_ADMIN role identifier.
   */
  function FUNDS_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @dev Returns the YIELD_MANAGER role identifier.
   */
  function YIELD_MANAGER_ROLE() external view returns (bytes32);

  /**
   * @dev Returns the permit typehash.
   */
  function PERMIT_TYPEHASH() external view returns (bytes32);

  // --- Functions ---

  // Note: Standard ERC4626 functions (asset, totalAssets, convertToShares, convertToAssets,
  // maxDeposit, previewDeposit, deposit, maxMint, previewMint, mint, maxWithdraw, previewWithdraw,
  // withdraw, maxRedeem, previewRedeem, redeem) and ERC20 functions (name, symbol, decimals,
  // totalSupply, balanceOf, transfer, allowance, approve, transferFrom) are inherited via IERC4626.

  // Note: Standard ERC20Permit functions (permit, nonces, DOMAIN_SEPARATOR) are inherited via IERC20Permit.

  /**
   * @dev Initialize the contract.
   */
  function initialize() external payable;

  /**
   * @dev Overload of the standard permit function to accept v, r, s signature components directly.
   * @param owner The owner of the tokens.
   * @param spender The address to grant allowance to.
   * @param value The amount of allowance.
   * @param deadline The timestamp after which the permit is invalid.
   * @param v The recovery ID of the signature.
   * @param r The R component of the signature.
   * @param s The S component of the signature.
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
   * @dev Set the target rate for yield generation.
   * @param newRate The new target rate in basis points (e.g., 1000 = 10%).
   */
  function setTargetRate(uint256 newRate) external;

  /**
   * @dev Get the vault APR.
   * @return The current vault APR.
   */
  function vaultAPR() external view returns (uint256);

  /**
   * @dev Rescue ERC20 tokens from the contract.
   * @param erc20Token The address of the ERC20 token to rescue.
   * @param to The recipient address.
   * @param amount The amount to rescue.
   */
  function rescueERC20(address erc20Token, address to, uint256 amount) external;

  // --- Events ---

  /**
   * @dev Emitted when ERC20 tokens are rescued from the contract.
   * @param caller The address initiating the rescue.
   * @param token The address of the ERC20 token rescued.
   * @param to The recipient address of the rescued tokens.
   * @param amount The amount of tokens rescued.
   */
  event ERC20Rescued(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /**
   * @dev Receive function to reject direct Ether transfers.
   */
  receive() external payable;
}
