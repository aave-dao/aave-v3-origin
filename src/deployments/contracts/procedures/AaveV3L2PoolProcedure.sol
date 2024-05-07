// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {L2PoolInstance} from '../../../contracts/instances/L2PoolInstance.sol';
import {IPoolAddressesProvider} from '../../../contracts/interfaces/IPoolAddressesProvider.sol';
import {AaveV3PoolConfigProcedure} from './AaveV3PoolConfigProcedure.sol';
import {IPool} from '../../../contracts/interfaces/IPool.sol';
import {IErrors} from '../../interfaces/IErrors.sol';
import '../../interfaces/IMarketReportTypes.sol';

contract AaveV3L2PoolProcedure is AaveV3PoolConfigProcedure, IErrors {
  function _deployAaveV3L2Pool(address poolAddressesProvider) internal returns (PoolReport memory) {
    if (poolAddressesProvider == address(0)) revert ProviderNotFound();

    PoolReport memory report;

    report.poolImplementation = _deployL2PoolImpl(poolAddressesProvider);
    report.poolConfiguratorImplementation = _deployPoolConfigurator(poolAddressesProvider);

    return report;
  }

  function _deployL2PoolImpl(address poolAddressesProvider) internal returns (address) {
    address l2Pool = address(new L2PoolInstance(IPoolAddressesProvider(poolAddressesProvider)));

    L2PoolInstance(l2Pool).initialize(IPoolAddressesProvider(poolAddressesProvider));

    return l2Pool;
  }
}
