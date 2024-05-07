// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolInstance} from '../../../contracts/instances/PoolInstance.sol';
import {IPoolAddressesProvider} from '../../../contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../../contracts/interfaces/IPool.sol';
import {AaveV3PoolConfigProcedure} from './AaveV3PoolConfigProcedure.sol';
import {IErrors} from '../../interfaces/IErrors.sol';
import '../../interfaces/IMarketReportTypes.sol';

contract AaveV3PoolProcedure is AaveV3PoolConfigProcedure, IErrors {
  function _deployAaveV3Pool(address poolAddressesProvider) internal returns (PoolReport memory) {
    if (poolAddressesProvider == address(0)) revert ProviderNotFound();
    PoolReport memory report;

    report.poolImplementation = _deployPoolImpl(poolAddressesProvider);
    report.poolConfiguratorImplementation = _deployPoolConfigurator(poolAddressesProvider);

    return report;
  }

  function _deployPoolImpl(address poolAddressesProvider) internal returns (address) {
    address pool = address(new PoolInstance(IPoolAddressesProvider(poolAddressesProvider)));

    PoolInstance(pool).initialize(IPoolAddressesProvider(poolAddressesProvider));

    return pool;
  }
}
