// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3L2PoolProcedure} from '../../../contracts/procedures/AaveV3L2PoolProcedure.sol';
import '../../../interfaces/IPoolReport.sol';

contract AaveV3L2PoolBatch is AaveV3L2PoolProcedure, IPoolReport {
  PoolReport internal _poolReport;

  constructor(address poolAddressesProvider, address interestRateStrategy) {
    _poolReport = _deployAaveV3L2Pool(poolAddressesProvider, interestRateStrategy);
  }

  function getPoolReport() external view returns (PoolReport memory) {
    return _poolReport;
  }
}
