// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMarketReportTypes.sol';

interface IMarketReportStorage {
  event Deployment(MarketReport report);

  function getMarketReport() external view returns (MarketReport memory);
}
