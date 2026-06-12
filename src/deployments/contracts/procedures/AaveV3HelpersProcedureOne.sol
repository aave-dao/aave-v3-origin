// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ConfigEngineReport} from '../../interfaces/IMarketReportTypes.sol';
import {AaveV3ConfigEngine, IAaveV3ConfigEngine} from '../../../contracts/extensions/v3-config-engine/AaveV3ConfigEngine.sol';
import {IPool} from '../../../contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from '../../../contracts/interfaces/IPoolConfigurator.sol';
import {IAaveOracle} from '../../../contracts/interfaces/IAaveOracle.sol';

contract AaveV3HelpersProcedureOne {
  function _deployConfigEngine(
    address pool,
    address poolConfigurator,
    address defaultInterestRateStrategy,
    address aaveOracle,
    address rewardsController,
    address collector,
    address aTokenImpl,
    address vTokenImpl
  ) internal returns (ConfigEngineReport memory configEngineReport) {
    IAaveV3ConfigEngine.EngineConstants memory engineConstants = IAaveV3ConfigEngine
      .EngineConstants({
        pool: IPool(pool),
        poolConfigurator: IPoolConfigurator(poolConfigurator),
        defaultInterestRateStrategy: defaultInterestRateStrategy,
        oracle: IAaveOracle(aaveOracle),
        rewardsController: rewardsController,
        collector: collector
      });

    configEngineReport.configEngine = address(
      new AaveV3ConfigEngine(aTokenImpl, vTokenImpl, engineConstants)
    );
    return configEngineReport;
  }
}
