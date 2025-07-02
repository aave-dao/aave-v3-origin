// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

/**
 * @title IsGHO Interface
 * @notice Interface for the sGHO contract, which is an ERC4626 vault for GHO tokens.
 * @dev This interface combines functionalities from ERC4626 for a tokenized vault,
 * ERC20Permit for gas-less approvals, and includes custom logic for yield generation and administrative roles.
 */
interface IsGHO {
  // --- Custom Errors ---

  /**
   * @notice Thrown when an invalid signature is provided.
   */
  error InvalidSignature();

  /**
   * @notice Thrown when a direct ETH transfer is attempted.
   */
  error NoEthAllowed();

  /**
   * @notice Thrown when a function is called by an address that does not have the FUNDS_ADMIN role.
   */
  error OnlyFundsAdmin();

  /**
   * @notice Thrown when a function is called by an address that does not have the YIELD_MANAGER role.
   */
  error OnlyYieldManager();

  /**
   * @notice Thrown if the contract is not initialized.
   */
  error NotInitialized();

  /**
   * @notice Thrown when an attempt is made to rescue the underlying GHO token.
   */
  error CannotRescueGHO();

  /**
   * @notice Thrown if the target rate is set to a value greater than 50%.
   */
  error RateMustBeLessThan50Percent();

  // --- Events ---

  /**
   * @notice Emitted when the target rate is updated.
   * @param newRate The new target rate.
   */
  event TargetRateUpdated(uint256 newRate);

  // --- State Variables (as view functions) ---

  /**
   * @notice Returns the address of the GHO token used as the underlying asset in the vault.
   * @return The address of the GHO token.
   */
  function gho() external view returns (address);

  /**
   * @notice Returns the chain ID of the network where the contract is deployed.
   * @dev This is used for EIP-712 signature validation to prevent replay attacks across different chains.
   * @return The chain ID.
   */
  function deploymentChainId() external view returns (uint256);

  /**
   * @notice Returns the current yield index, representing the accumulated yield.
   * @dev This index is used to calculate the value of sGHO in terms of GHO.
   * @return The current yield index.
   */
  function yieldIndex() external view returns (uint256);

  /**
   * @notice Returns the current target annual percentage rate (APR) for yield generation.
   * @dev The rate is expressed in basis points (1% = 100).
   * @return The target rate in basis points.
   */
  function targetRate() external view returns (uint256);

  /**
   * @notice Returns the timestamp of the last time the yield index was updated.
   * @return The Unix timestamp of the last update.
   */
  function lastUpdate() external view returns (uint256);

  /**
   * @notice Returns the role identifier for the Funds Admin.
   * @dev This role has permissions to manage funds, such as rescuing tokens.
   * @return The keccak256 hash of "FUNDS_ADMIN_ROLE".
   */
  function FUNDS_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the role identifier for the Yield Manager.
   * @dev This role has permissions to update the target rate.
   * @return The keccak256 hash of "YIELD_MANAGER_ROLE".
   */
  function YIELD_MANAGER_ROLE() external view returns (bytes32);

  // --- Functions ---

  // Note: Standard ERC4626 functions (asset, totalAssets, convertToShares, convertToAssets,
  // maxDeposit, previewDeposit, deposit, maxMint, previewMint, mint, maxWithdraw, previewWithdraw,
  // withdraw, maxRedeem, previewRedeem, redeem) and ERC20 functions (name, symbol, decimals,
  // totalSupply, balanceOf, transfer, allowance, approve, transferFrom) are inherited via IERC4626.

  // Note: Standard ERC20Permit functions (permit, nonces, DOMAIN_SEPARATOR) are inherited via IERC20Permit.

  /**
   * @notice Initializes the sGHO contract.
   * @dev This function can only be called once. It sets up initial roles and configurations.
   * While the function is marked as `payable`, it is designed to reject any attached Ether value.
   */
  function initialize(address gho_, address aclManager_) external payable;

  /**
   * @notice Overload of the standard ERC20Permit `permit` function.
   * @dev This version accepts the v, r, and s components of the signature directly,
   * which can be useful for platforms that do not handle the single `bytes` signature format.
   * @param owner The owner of the tokens.
   * @param spender The address to grant allowance to.
   * @param value The amount of allowance to grant.
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
   * @notice Sets the target rate for yield generation.
   * @dev This function can only be called by an address with the YIELD_MANAGER role.
   * The new rate must be less than 50% (5000 basis points).
   * @param newRate The new target rate in basis points (e.g., 1000 for 10%).
   */
  function setTargetRate(uint256 newRate) external;

  /**
   * @notice Calculates and returns the current vault Annual Percentage Rate (APR).
   * @return The current vault APR, in basis points (1% = 100).
   */
  function vaultAPR() external view returns (uint256);

  /**
   * @notice Rescues ERC20 tokens that have been accidentally sent to this contract.
   * @dev This function can only be called by an address with the FUNDS_ADMIN role.
   * It prevents the rescue of the underlying GHO token to protect the vault's assets.
   * @param erc20Token The address of the ERC20 token to rescue.
   * @param to The address where the rescued tokens will be sent.
   * @param amount The amount of tokens to rescue.
   */
  function rescueERC20(address erc20Token, address to, uint256 amount) external;

  // --- Events ---

  /**
   * @notice Emitted when ERC20 tokens are rescued from the contract.
   * @param caller The address that initiated the rescue operation.
   * @param token The address of the rescued ERC20 token.
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
   * @notice The receive function is implemented to reject direct Ether transfers to the contract.
   */
  receive() external payable;
}
