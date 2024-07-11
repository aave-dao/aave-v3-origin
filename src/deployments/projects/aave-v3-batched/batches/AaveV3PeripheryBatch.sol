// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3TreasuryProcedure} from '../../../contracts/procedures/AaveV3TreasuryProcedure.sol';
import {AaveV3OracleProcedure} from '../../../contracts/procedures/AaveV3OracleProcedure.sol';
import {AaveV3IncentiveProcedure} from '../../../contracts/procedures/AaveV3IncentiveProcedure.sol';
import {AaveV3DefaultRateStrategyProcedure} from '../../../contracts/procedures/AaveV3DefaultRateStrategyProcedure.sol';
import '../../../interfaces/IMarketReportTypes.sol';

contract AaveV3PeripheryBatch is
  AaveV3TreasuryProcedure,
  AaveV3OracleProcedure,
  AaveV3IncentiveProcedure
{
  PeripheryReport internal _report;

  constructor(
    address poolAdmin,
    MarketConfig memory config,
    address poolAddressesProvider,
    address setupBatch
  ) {
    TreasuryReport memory treasuryReport = _deployAaveV3Treasury(
      poolAdmin,
      config.proxyAdmin,
      config.salt
    );
    _report.aaveOracle = _deployAaveOracle(config.oracleDecimals, poolAddressesProvider);
    _report.proxyAdmin = treasuryReport.proxyAdmin;
    _report.treasury = treasuryReport.treasury;
    _report.treasuryImplementation = treasuryReport.treasuryImplementation;

    (_report.emissionManager, _report.rewardsControllerImplementation) = _deployIncentives(
      setupBatch
    );
  }

  function getPeripheryReport() external view returns (PeripheryReport memory) {
    return _report;
  }
}
