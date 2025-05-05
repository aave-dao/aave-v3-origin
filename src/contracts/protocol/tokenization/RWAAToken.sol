// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Errors} from 'src/contracts/protocol/libraries/helpers/Errors.sol';
import {AToken} from 'src/contracts/protocol/tokenization/AToken.sol';
import {IAToken} from 'src/contracts/interfaces/IAToken.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';

abstract contract RWAAToken is AToken {
  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   * @param name The name of the token
   * @param symbol The symbol of the token
   */
  constructor(
    IPool pool,
    string memory name,
    string memory symbol
  ) AToken(pool, name, symbol) {
    // Intentionally left blank
  }

  /// @inheritdoc IAToken
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  /**
   * @notice Transfers the aTokens between two users. Validates the transfer
   * (ie checks for valid HF after the transfer) if required
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   * @param validate True if the transfer needs to be validated, false otherwise
   */
   // todo: is pool admin fine, or we want to add a new permission?
  function _transfer(address from, address to, uint256 amount, bool validate) internal virtual override onlyPoolAdmin {
    super._transfer(from, to, amount, validate);
  }
}