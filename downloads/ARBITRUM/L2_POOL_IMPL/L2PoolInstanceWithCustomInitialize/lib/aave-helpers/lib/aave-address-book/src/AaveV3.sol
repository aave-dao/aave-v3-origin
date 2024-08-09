// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {DataTypes} from '../../../../aave-v3-origin/src/core/contracts/protocol/libraries/types/DataTypes.sol';
import {Errors} from '../../../../aave-v3-origin/src/core//contracts/protocol/libraries/helpers/Errors.sol';
import {IPoolAddressesProvider} from '../../../../aave-v3-origin/src/core//contracts/interfaces/IPoolAddressesProvider.sol';
import {IAToken} from '../../../../aave-v3-origin/src/core//contracts/interfaces/IAToken.sol';
import {IPool} from '../../../../aave-v3-origin/src/core//contracts/interfaces/IPool.sol';
import {IPriceOracleGetter} from '../../../../aave-v3-origin/src/core//contracts/interfaces/IPriceOracleGetter.sol';
import {IACLManager as BasicIACLManager} from '../../../../aave-v3-origin/src/core//contracts/interfaces/IACLManager.sol';
import {IReserveInterestRateStrategy} from '../../../../aave-v3-origin/src/core//contracts/interfaces/IReserveInterestRateStrategy.sol';

interface IACLManager is BasicIACLManager {
  function hasRole(bytes32 role, address account) external view returns (bool);

  function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);

  function renounceRole(bytes32 role, address account) external;

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;
}
