// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3MiscProcedure} from '../../../contracts/procedures/AaveV3MiscProcedure.sol';
import '../../../interfaces/IMarketReportTypes.sol';

contract AaveV3MiscBatch is AaveV3MiscProcedure {
  MiscReport internal _report;

  constructor(
    bool l2Flag,
    address poolAddressesProvider,
    address sequencerUptimeOracle,
    uint256 gracePeriod
  ) {
    MiscReport memory miscReport = _deploySentinelAndDefaultIR(
      l2Flag,
      poolAddressesProvider,
      sequencerUptimeOracle,
      gracePeriod
    );
    _report.priceOracleSentinel = miscReport.priceOracleSentinel;
    _report.defaultInterestRateStrategy = miscReport.defaultInterestRateStrategy;
  }

  function getMiscReport() external view returns (MiscReport memory) {
    return _report;
  }
}
