// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import {IWithGuardian} from './interfaces/IWithGuardian.sol';
import {Ownable} from '../oz-common/Ownable.sol';

abstract contract OwnableWithGuardian is Ownable, IWithGuardian {
  address private _guardian;

  constructor() {
    _updateGuardian(_msgSender());
  }

  modifier onlyGuardian() {
    _checkGuardian();
    _;
  }

  modifier onlyOwnerOrGuardian() {
    _checkOwnerOrGuardian();
    _;
  }

  function guardian() public view override returns (address) {
    return _guardian;
  }

  /// @inheritdoc IWithGuardian
  function updateGuardian(address newGuardian) external override onlyOwnerOrGuardian {
    _updateGuardian(newGuardian);
  }

  /**
   * @dev method to update the guardian
   * @param newGuardian the new guardian address
   */
  function _updateGuardian(address newGuardian) internal {
    address oldGuardian = _guardian;
    _guardian = newGuardian;
    emit GuardianUpdated(oldGuardian, newGuardian);
  }

  function _checkGuardian() internal view {
    require(guardian() == _msgSender(), 'ONLY_BY_GUARDIAN');
  }

  function _checkOwnerOrGuardian() internal view {
    require(_msgSender() == owner() || _msgSender() == guardian(), 'ONLY_BY_OWNER_OR_GUARDIAN');
  }
}
