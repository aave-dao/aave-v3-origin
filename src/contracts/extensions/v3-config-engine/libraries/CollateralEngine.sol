// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {DataTypes} from '../../../protocol/libraries/types/DataTypes.sol';
import {ReserveConfiguration} from '../../../protocol/libraries/configuration/ReserveConfiguration.sol';
import {IAaveV3ConfigEngine as IEngine, IPoolConfigurator, IPool} from '../IAaveV3ConfigEngine.sol';
import {PercentageMath} from '../../../protocol/libraries/math/PercentageMath.sol';
import {EngineFlags} from '../EngineFlags.sol';

library CollateralEngine {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using PercentageMath for uint256;

  function executeCollateralSide(
    IEngine.EngineConstants calldata engineConstants,
    IEngine.CollateralUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    _configCollateralSide(engineConstants.poolConfigurator, engineConstants.pool, updates);
  }

  function _configCollateralSide(
    IPoolConfigurator poolConfigurator,
    IPool pool,
    IEngine.CollateralUpdate[] memory updates
  ) internal {
    for (uint256 i = 0; i < updates.length; i++) {
      if (updates[i].liqThreshold != 0) {
        bool notAllKeepCurrent = updates[i].ltv != EngineFlags.KEEP_CURRENT ||
          updates[i].liqThreshold != EngineFlags.KEEP_CURRENT ||
          updates[i].liqBonus != EngineFlags.KEEP_CURRENT;

        bool atLeastOneKeepCurrent = updates[i].ltv == EngineFlags.KEEP_CURRENT ||
          updates[i].liqThreshold == EngineFlags.KEEP_CURRENT ||
          updates[i].liqBonus == EngineFlags.KEEP_CURRENT;

        if (notAllKeepCurrent && atLeastOneKeepCurrent) {
          DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(
            updates[i].asset
          );
          (
            uint256 currentLtv,
            uint256 currentLiqThreshold,
            uint256 currentLiqBonus,
            ,

          ) = configuration.getParams();

          if (updates[i].ltv == EngineFlags.KEEP_CURRENT) {
            updates[i].ltv = currentLtv;
          }

          if (updates[i].liqThreshold == EngineFlags.KEEP_CURRENT) {
            updates[i].liqThreshold = currentLiqThreshold;
          }

          if (updates[i].liqBonus == EngineFlags.KEEP_CURRENT) {
            // Subtracting 100_00 to be consistent with the engine as 100_00 gets added while setting the liqBonus
            updates[i].liqBonus = currentLiqBonus - 100_00;
          }
        }

        if (notAllKeepCurrent) {
          // LT*LB (in %) should never be above 100%, because it means instant undercollateralization
          require(
            updates[i].liqThreshold.percentMul(100_00 + updates[i].liqBonus) <= 100_00,
            'INVALID_LT_LB_RATIO'
          );

          poolConfigurator.configureReserveAsCollateral(
            updates[i].asset,
            updates[i].ltv,
            updates[i].liqThreshold,
            // For reference, this is to simplify the interaction with the Aave protocol,
            // as there the definition is as e.g. 105% (5% bonus for liquidators)
            100_00 + updates[i].liqBonus
          );
        }

        if (updates[i].liqProtocolFee != EngineFlags.KEEP_CURRENT) {
          require(updates[i].liqProtocolFee < 100_00, 'INVALID_LIQ_PROTOCOL_FEE');
          poolConfigurator.setLiquidationProtocolFee(updates[i].asset, updates[i].liqProtocolFee);
        }

        if (updates[i].debtCeiling != EngineFlags.KEEP_CURRENT) {
          // For reference, this is to simplify the interactions with the Aave protocol,
          // as there the definition is with 2 decimals. We don't see any reason to set
          // a debt ceiling involving .something USD, so we simply don't allow to do it
          poolConfigurator.setDebtCeiling(updates[i].asset, updates[i].debtCeiling * 100);
        }
      }
    }
  }
}
