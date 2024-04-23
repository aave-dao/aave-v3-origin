// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {Vm} from 'forge-std/Vm.sol';
import {Create2Utils} from '../../src/deployments/contracts/utilities/Create2Utils.sol';
import {AaveV3ConfigEngine} from 'aave-v3-periphery/contracts/v3-config-engine/AaveV3ConfigEngine.sol';
import {IAaveV3ConfigEngine} from 'aave-v3-periphery/contracts/v3-config-engine/IAaveV3ConfigEngine.sol';
import {IPoolAddressesProvider} from '../../src/core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../src/core/contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from '../../src/core/contracts/interfaces/IPoolConfigurator.sol';
import {IAaveOracle} from '../../src/core/contracts/interfaces/IAaveOracle.sol';
import {CapsEngine} from 'aave-v3-periphery/contracts/v3-config-engine/libraries/CapsEngine.sol';
import {BorrowEngine} from 'aave-v3-periphery/contracts/v3-config-engine/libraries/BorrowEngine.sol';
import {CollateralEngine} from 'aave-v3-periphery/contracts/v3-config-engine/libraries/CollateralEngine.sol';
import {RateEngine} from 'aave-v3-periphery/contracts/v3-config-engine/libraries/RateEngine.sol';
import {PriceFeedEngine} from 'aave-v3-periphery/contracts/v3-config-engine/libraries/PriceFeedEngine.sol';
import {EModeEngine} from 'aave-v3-periphery/contracts/v3-config-engine/libraries/EModeEngine.sol';
import {ListingEngine} from 'aave-v3-periphery/contracts/v3-config-engine/libraries/ListingEngine.sol';

library ConfigEngineDeployer {
  function deployEngine(Vm vm, MarketReport memory report) internal returns (address) {
    // Etch the create2 factory in the local env
    vm.etch(
      0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7,
      hex'7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3'
    );
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
        pool: IPool(report.poolProxy),
        poolConfigurator: IPoolConfigurator(report.poolConfiguratorProxy),
        defaultInterestRateStrategy: report.defaultInterestRateStrategyV2,
        oracle: IAaveOracle(report.aaveOracle),
        rewardsController: report.rewardsControllerProxy,
        collector: report.treasury
      });

    return
      address(
        new AaveV3ConfigEngine(
          report.aToken,
          report.variableDebtToken,
          engineConstants,
          engineLibraries
        )
      );
  }
}
