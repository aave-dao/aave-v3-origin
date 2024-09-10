// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {DataTypes} from '../lib/aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {Errors} from '../lib/aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import {ConfiguratorInputTypes} from '../lib/aave-v3-core/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {IPoolAddressesProvider} from '../lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IAToken} from '../lib/aave-v3-core/contracts/interfaces/IAToken.sol';
import {IPool} from '../lib/aave-v3-core/contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from '../lib/aave-v3-core/contracts/interfaces/IPoolConfigurator.sol';
import {IPriceOracleGetter} from '../lib/aave-v3-core/contracts/interfaces/IPriceOracleGetter.sol';
import {IAaveOracle} from '../lib/aave-v3-core/contracts/interfaces/IAaveOracle.sol';
import {IACLManager as BasicIACLManager} from '../lib/aave-v3-core/contracts/interfaces/IACLManager.sol';
import {IPoolDataProvider} from '../lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';
import {IDefaultInterestRateStrategy} from '../lib/aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol';
import {IReserveInterestRateStrategy} from '../lib/aave-v3-core/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {IPoolDataProvider as IAaveProtocolDataProvider} from '../lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';
import {AggregatorInterface} from '../lib/aave-v3-core/contracts/dependencies/chainlink/AggregatorInterface.sol';

interface IACLManager is BasicIACLManager {
  function hasRole(bytes32 role, address account) external view returns (bool);

  function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);

  function renounceRole(bytes32 role, address account) external;

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;
}
