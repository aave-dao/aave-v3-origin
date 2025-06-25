// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {AccessControl} from '../dependencies/openzeppelin/contracts/AccessControl.sol';
import {IRwaAToken} from '../interfaces/IRwaAToken.sol';
import {IRwaATokenManager} from '../interfaces/IRwaATokenManager.sol';

/**
 * @title RwaATokenManager
 * @author Aave
 * @notice Implementation of the RWA aToken Manager, allowing transfer permissions to be granted individually for each RWA aToken.
 * @dev Requires the ATokenAdmin role on the Aave V3 Pool.
 */
contract RwaATokenManager is AccessControl, IRwaATokenManager {
  /// @inheritdoc IRwaATokenManager
  bytes32 public constant override AUTHORIZED_TRANSFER_ROLE = keccak256('AUTHORIZED_TRANSFER');

  /**
   * @dev Constructor
   * @param owner The address of the default admin role
   */
  constructor(address owner) {
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
  }

  /// @inheritdoc IRwaATokenManager
  function grantAuthorizedTransferRole(address aToken, address account) external override {
    grantRole(getAuthorizedTransferRole(aToken), account);
  }

  /// @inheritdoc IRwaATokenManager
  function revokeAuthorizedTransferRole(address aToken, address account) external override {
    revokeRole(getAuthorizedTransferRole(aToken), account);
  }

  /// @inheritdoc IRwaATokenManager
  function transferRwaAToken(
    address aToken,
    address from,
    address to,
    uint256 amount
  ) external override onlyRole(getAuthorizedTransferRole(aToken)) returns (bool) {
    bool result = IRwaAToken(aToken).authorizedTransfer(from, to, amount);
    emit TransferRwaAToken(msg.sender, aToken, from, to, amount);
    return result;
  }

  /// @inheritdoc IRwaATokenManager
  function hasAuthorizedTransferRole(
    address aToken,
    address account
  ) external view override returns (bool) {
    return hasRole(getAuthorizedTransferRole(aToken), account);
  }

  /// @inheritdoc IRwaATokenManager
  function getAuthorizedTransferRole(address aToken) public pure override returns (bytes32) {
    return keccak256(abi.encode(AUTHORIZED_TRANSFER_ROLE, aToken));
  }
}
