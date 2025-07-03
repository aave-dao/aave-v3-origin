// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {L2PoolInstance} from '../../../contracts/instances/L2PoolInstance.sol';
import {IPoolAddressesProvider} from '../../../contracts/interfaces/IPoolAddressesProvider.sol';
import {IReserveInterestRateStrategy} from '../../../contracts/interfaces/IReserveInterestRateStrategy.sol';
import {AaveV3PoolConfigProcedure} from './AaveV3PoolConfigProcedure.sol';
import {IPool} from '../../../contracts/interfaces/IPool.sol';
import {IErrors} from '../../interfaces/IErrors.sol';
import '../../interfaces/IMarketReportTypes.sol';

contract AaveV3L2PoolProcedure is AaveV3PoolConfigProcedure, IErrors {
  function _deployAaveV3L2Pool(
    address poolAddressesProvider,
    address interestRateStrategy
  ) internal returns (PoolReport memory) {
    if (poolAddressesProvider == address(0)) revert ProviderNotFound();
    if (interestRateStrategy == address(0)) revert InterestRateStrategyNotFound();

    PoolReport memory report;

    report.poolImplementation = _deployL2PoolImpl(poolAddressesProvider, interestRateStrategy);
    report.poolConfiguratorImplementation = _deployPoolConfigurator();

    return report;
  }

  function _deployL2PoolImpl(
    address poolAddressesProvider,
    address interestRateStrategy
  ) internal returns (address) {
    address l2Pool = address(
      new L2PoolInstance(
        IPoolAddressesProvider(poolAddressesProvider),
        IReserveInterestRateStrategy(interestRateStrategy)
      )
    );

    return l2Pool;
  }
}
