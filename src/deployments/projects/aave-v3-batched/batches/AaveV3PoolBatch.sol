// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3PoolProcedure} from '../../../contracts/procedures/AaveV3PoolProcedure.sol';
import {IPoolReport} from '../../../interfaces/IPoolReport.sol';

import '../../../interfaces/IMarketReportTypes.sol';

contract AaveV3PoolBatch is AaveV3PoolProcedure, IPoolReport {
  PoolReport internal _poolReport;

  constructor(address poolAddressesProvider, address interestRateStrategy) {
    _poolReport = _deployAaveV3Pool(poolAddressesProvider, interestRateStrategy);
  }

  function getPoolReport() external view returns (PoolReport memory) {
    return _poolReport;
  }
}
