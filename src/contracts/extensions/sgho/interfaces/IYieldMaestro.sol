// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IACLManager} from '../../../interfaces/IACLManager.sol';

interface IYieldMaestro {
  // --- Events ---

  /**
   * @dev Emitted when savings are claimed.
   * @param amount The amount of GHO claimed.
   */
  event Claimed(uint256 indexed amount);

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
   * @dev Only caller with FUNDS_ADMIN role can call
   */
  error OnlyFundsAdmin();

  /**
   * @dev Only YieldManager can call
   */
  error OnlyYieldManager();

  /**
   * @dev Only sGHO vault can call
   */
  error OnlyVault();
  
  /**
   * @dev Throws if the contract is not initialized.
   */
  error NotInitialized();

  /**
   * @dev Returns the address of the GHO token.
  */

  function GHO() external view returns (IERC20);

  /**
   * @dev Returns the address of the sGHO (Savings GHO) contract.
   */
  function sGHO() external view returns (address);

  /**
   * @dev Returns the timestamp of the last claim.
   */
  function lastClaimTimestamp() external view returns (uint256);

  /**
   * @dev Returns the target rate (APR * 1e6).
   */
  function targetRate() external view returns (uint256);

  // --- Functions ---

  /**
   * @dev Claims the accumulated savings based on the targetRate and transfers them to the sGHO contract.
   * @return claimed The amount of GHO claimed.
   */
  function claimSavings() external returns (uint256 claimed);

  /**
   * @dev Preview how much would be claimable at the current block timestamp.
   * @return claimable The amount of GHO that can be claimed.
   */
  function previewClaimable() external view returns (uint256 claimable);

  /**
   * @dev Returns the approximate vault APR based on the targetRate.
   * @return The vault APR (targetRate / 1e6).
   */
  function vaultAPR() external view returns (uint256);

  /**
   * @dev Sets the new target rate for savings calculation.
   * Intended to be called only by YieldManager or Admin.
   * @param newRate The new target APR (e.g., 1000 for 10%).
   */
  function setTargetRate(uint256 newRate) external;

  /**
   * @dev Rescues ERC20 tokens mistakenly sent to the contract.
   * Intended to be called only by Admin.
   * @param erc20Token The address of the ERC20 token to rescue.
   * @param to The address to send the rescued tokens to.
   * @param amount The amount of tokens to attempt to rescue.
   */
  function rescueERC20(address erc20Token, address to, uint256 amount) external;

  /**
   * @dev Calculates the currently unclaimed GHO based on time elapsed and target rate.
   * Note: This was public in the original contract but might be internal logic. Included here for completeness if external visibility is desired.
   * @return The amount of unclaimed GHO.
   */
  function _calculateUnclaimed() external view returns (uint256);
}
