// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../interfaces/IMarketReportStorage.sol';

abstract contract MarketReportStorage is IMarketReportStorage {
  MarketReport internal _marketReport;
}
