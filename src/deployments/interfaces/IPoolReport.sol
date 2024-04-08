// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMarketReportTypes.sol';

interface IPoolReport {
  function getPoolReport() external view returns (PoolReport memory);
}
