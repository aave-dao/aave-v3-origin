// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IERC4626StataToken} from './IERC4626StataToken.sol';
import {IERC20AaveLM} from './IERC20AaveLM.sol';

interface IStataTokenV2 is IERC4626, IERC20Permit, IERC4626StataToken, IERC20AaveLM {
  /**
   * @notice Checks if the passed actor is permissioned emergency admin.
   * @param actor The reward to claim
   * @return bool signaling if actor can pause the vault.
   */
  function canPause(address actor) external view returns (bool);

  /**
   * @notice Pauses/unpauses all system's operations
   * @param paused boolean determining if the token should be paused or unpaused
   */
  function setPaused(bool paused) external;
}
