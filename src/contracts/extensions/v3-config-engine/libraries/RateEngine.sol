// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IDefaultInterestRateStrategyV2} from '../../../interfaces/IDefaultInterestRateStrategyV2.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {EngineFlags} from '../EngineFlags.sol';
import {IAaveV3ConfigEngine as IEngine, IPoolConfigurator} from '../IAaveV3ConfigEngine.sol';

library RateEngine {
  using SafeCast for uint256;

  function executeRateStrategiesUpdate(
    IEngine.EngineConstants calldata engineConstants,
    IEngine.RateStrategyUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    (address[] memory ids, IEngine.InterestRateInputData[] memory rates) = _unpackRatesUpdate(
      updates
    );

    _configRateStrategies(
      IDefaultInterestRateStrategyV2(engineConstants.defaultInterestRateStrategy),
      engineConstants.poolConfigurator,
      ids,
      rates
    );
  }

  function _configRateStrategies(
    IDefaultInterestRateStrategyV2 rateStrategy,
    IPoolConfigurator poolConfigurator,
    address[] memory ids,
    IEngine.InterestRateInputData[] memory strategiesParams
  ) internal {
    for (uint256 i = 0; i < strategiesParams.length; i++) {
      address asset = ids[i];
      IEngine.InterestRateInputData memory strategyParams = strategiesParams[i];

      bool atLeastOneKeepCurrent = strategyParams.optimalUsageRatio == EngineFlags.KEEP_CURRENT ||
        strategyParams.baseVariableBorrowRate == EngineFlags.KEEP_CURRENT ||
        strategyParams.variableRateSlope1 == EngineFlags.KEEP_CURRENT ||
        strategyParams.variableRateSlope2 == EngineFlags.KEEP_CURRENT;

      if (atLeastOneKeepCurrent) {
        IDefaultInterestRateStrategyV2.InterestRateData
          memory currentStrategyData = IDefaultInterestRateStrategyV2(rateStrategy)
            .getInterestRateDataBps(asset);

        if (strategyParams.variableRateSlope1 == EngineFlags.KEEP_CURRENT) {
          strategyParams.variableRateSlope1 = currentStrategyData.variableRateSlope1;
        }

        if (strategyParams.variableRateSlope2 == EngineFlags.KEEP_CURRENT) {
          strategyParams.variableRateSlope2 = currentStrategyData.variableRateSlope2;
        }

        if (strategyParams.optimalUsageRatio == EngineFlags.KEEP_CURRENT) {
          strategyParams.optimalUsageRatio = currentStrategyData.optimalUsageRatio;
        }

        if (strategyParams.baseVariableBorrowRate == EngineFlags.KEEP_CURRENT) {
          strategyParams.baseVariableBorrowRate = currentStrategyData.baseVariableBorrowRate;
        }
      }

      poolConfigurator.setReserveInterestRateData(
        asset,
        abi.encode(
          IDefaultInterestRateStrategyV2.InterestRateData({
            optimalUsageRatio: strategyParams.optimalUsageRatio.toUint16(),
            baseVariableBorrowRate: strategyParams.baseVariableBorrowRate.toUint32(),
            variableRateSlope1: strategyParams.variableRateSlope1.toUint32(),
            variableRateSlope2: strategyParams.variableRateSlope2.toUint32()
          })
        )
      );
    }
  }

  function _unpackRatesUpdate(
    IEngine.RateStrategyUpdate[] memory updates
  ) internal pure returns (address[] memory, IEngine.InterestRateInputData[] memory) {
    address[] memory ids = new address[](updates.length);
    IEngine.InterestRateInputData[] memory rates = new IEngine.InterestRateInputData[](
      updates.length
    );

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      rates[i] = updates[i].params;
    }
    return (ids, rates);
  }
}
