// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3HelpersProcedureOne} from '../../../contracts/procedures/AaveV3HelpersProcedureOne.sol';
import '../../../interfaces/IMarketReportTypes.sol';

contract AaveV3HelpersBatchOne is AaveV3HelpersProcedureOne {
  ConfigEngineReport internal _report;

  constructor(
    address poolProxy,
    address poolConfiguratorProxy,
    address defaultInterestRateStrategy,
    address aaveOracle,
    address rewardsController,
    address collector,
    address aTokenImpl,
    address vTokenImpl
  ) {
    _report = _deployConfigEngine(
      poolProxy,
      poolConfiguratorProxy,
      defaultInterestRateStrategy,
      aaveOracle,
      rewardsController,
      collector,
      aTokenImpl,
      vTokenImpl
    );
  }

  function getConfigEngineReport() external view returns (ConfigEngineReport memory) {
    return _report;
  }
}
