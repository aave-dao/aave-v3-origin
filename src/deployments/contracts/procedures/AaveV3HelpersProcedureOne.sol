// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Create2Utils} from '../utilities/Create2Utils.sol';
import {ConfigEngineReport} from '../../interfaces/IMarketReportTypes.sol';
import {AaveV3ConfigEngine, IAaveV3ConfigEngine, CapsEngine, BorrowEngine, CollateralEngine, RateEngine, PriceFeedEngine, EModeEngine, ListingEngine} from '../../../contracts/extensions/v3-config-engine/AaveV3ConfigEngine.sol';
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
    IAaveV3ConfigEngine.EngineLibraries memory engineLibraries = IAaveV3ConfigEngine
      .EngineLibraries({
        listingEngine: Create2Utils._create2Deploy('v1', type(ListingEngine).creationCode),
        eModeEngine: Create2Utils._create2Deploy('v1', type(EModeEngine).creationCode),
        borrowEngine: Create2Utils._create2Deploy('v1', type(BorrowEngine).creationCode),
        collateralEngine: Create2Utils._create2Deploy('v1', type(CollateralEngine).creationCode),
        priceFeedEngine: Create2Utils._create2Deploy('v1', type(PriceFeedEngine).creationCode),
        rateEngine: Create2Utils._create2Deploy('v1', type(RateEngine).creationCode),
        capsEngine: Create2Utils._create2Deploy('v1', type(CapsEngine).creationCode)
      });

    IAaveV3ConfigEngine.EngineConstants memory engineConstants = IAaveV3ConfigEngine
      .EngineConstants({
        pool: IPool(pool),
        poolConfigurator: IPoolConfigurator(poolConfigurator),
        defaultInterestRateStrategy: defaultInterestRateStrategy,
        oracle: IAaveOracle(aaveOracle),
        rewardsController: rewardsController,
        collector: collector
      });

    configEngineReport.listingEngine = engineLibraries.listingEngine;
    configEngineReport.eModeEngine = engineLibraries.eModeEngine;
    configEngineReport.borrowEngine = engineLibraries.borrowEngine;
    configEngineReport.collateralEngine = engineLibraries.collateralEngine;
    configEngineReport.priceFeedEngine = engineLibraries.priceFeedEngine;
    configEngineReport.rateEngine = engineLibraries.rateEngine;
    configEngineReport.capsEngine = engineLibraries.capsEngine;

    configEngineReport.configEngine = address(
      new AaveV3ConfigEngine(aTokenImpl, vTokenImpl, engineConstants, engineLibraries)
    );
    return configEngineReport;
  }
}
