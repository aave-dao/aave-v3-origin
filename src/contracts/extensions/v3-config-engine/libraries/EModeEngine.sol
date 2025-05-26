// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {EngineFlags} from '../EngineFlags.sol';
import {DataTypes} from '../../../protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from '../../../protocol/libraries/math/PercentageMath.sol';
import {IAaveV3ConfigEngine as IEngine, IPoolConfigurator, IPool} from '../IAaveV3ConfigEngine.sol';

library EModeEngine {
  using PercentageMath for uint256;
  using SafeCast for uint256;

  error NoAvailableEmodeCategory();

  function executeAssetsEModeUpdate(
    IEngine.EngineConstants calldata engineConstants,
    IEngine.AssetEModeUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    _configAssetsEMode(engineConstants.poolConfigurator, engineConstants.pool, updates);
  }

  function executeEModeCategoriesCreate(
    IEngine.EngineConstants calldata engineConstants,
    IEngine.EModeCategoryCreation[] memory creations
  ) external {
    for (uint256 i; i < creations.length; i++) {
      require(
        keccak256(abi.encode(creations[i].label)) !=
          keccak256(abi.encode(EngineFlags.KEEP_CURRENT_STRING)),
        'INVALID_LABEL'
      );
      uint8 categoryId = _findFirstUnusedEmodeCategory(engineConstants.pool);
      engineConstants.poolConfigurator.setEModeCategory(
        categoryId,
        creations[i].ltv.toUint16(),
        creations[i].liqThreshold.toUint16(),
        // For reference, this is to simplify the interaction with the Aave protocol,
        // as there the definition is as e.g. 105% (5% bonus for liquidators)
        (100_00 + creations[i].liqBonus).toUint16(),
        creations[i].label
      );
      for (uint256 j; j < creations[i].collaterals.length; j++) {
        engineConstants.poolConfigurator.setAssetCollateralInEMode(
          creations[i].collaterals[j],
          categoryId,
          true
        );
      }
      for (uint256 k; k < creations[i].borrowables.length; k++) {
        engineConstants.poolConfigurator.setAssetBorrowableInEMode(
          creations[i].borrowables[k],
          categoryId,
          true
        );
      }
    }
  }

  function executeEModeCategoriesUpdate(
    IEngine.EngineConstants calldata engineConstants,
    IEngine.EModeCategoryUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    _configEModeCategories(engineConstants.poolConfigurator, engineConstants.pool, updates);
  }

  function _configAssetsEMode(
    IPoolConfigurator poolConfigurator,
    IPool pool,
    IEngine.AssetEModeUpdate[] memory updates
  ) internal {
    for (uint256 i = 0; i < updates.length; i++) {
      DataTypes.CollateralConfig memory cfg = pool.getEModeCategoryCollateralConfig(
        updates[i].eModeCategory
      );
      require(cfg.liquidationThreshold != 0, 'INVALID_UPDATE');
      if (updates[i].collateral != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setAssetCollateralInEMode(
          updates[i].asset,
          updates[i].eModeCategory,
          EngineFlags.toBool(updates[i].collateral)
        );
      }
      if (updates[i].borrowable != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setAssetBorrowableInEMode(
          updates[i].asset,
          updates[i].eModeCategory,
          EngineFlags.toBool(updates[i].borrowable)
        );
      }
    }
  }

  function _configEModeCategories(
    IPoolConfigurator poolConfigurator,
    IPool pool,
    IEngine.EModeCategoryUpdate[] memory updates
  ) internal {
    for (uint256 i = 0; i < updates.length; i++) {
      bool atLeastOneKeepCurrent = updates[i].ltv == EngineFlags.KEEP_CURRENT ||
        updates[i].liqThreshold == EngineFlags.KEEP_CURRENT ||
        updates[i].liqBonus == EngineFlags.KEEP_CURRENT ||
        keccak256(abi.encode(updates[i].label)) ==
        keccak256(abi.encode(EngineFlags.KEEP_CURRENT_STRING));

      bool notAllKeepCurrent = updates[i].ltv != EngineFlags.KEEP_CURRENT ||
        updates[i].liqThreshold != EngineFlags.KEEP_CURRENT ||
        updates[i].liqBonus != EngineFlags.KEEP_CURRENT ||
        keccak256(abi.encode(updates[i].label)) !=
        keccak256(abi.encode(EngineFlags.KEEP_CURRENT_STRING));

      DataTypes.CollateralConfig memory cfg = pool.getEModeCategoryCollateralConfig(
        updates[i].eModeCategory
      );
      // should only be able to update existing eModes, not create new ones
      require(cfg.liquidationThreshold != 0, 'INVALID_UPDATE');

      if (notAllKeepCurrent && atLeastOneKeepCurrent) {
        if (updates[i].ltv == EngineFlags.KEEP_CURRENT) {
          updates[i].ltv = cfg.ltv;
        }

        if (updates[i].liqThreshold == EngineFlags.KEEP_CURRENT) {
          updates[i].liqThreshold = cfg.liquidationThreshold;
        }

        if (updates[i].liqBonus == EngineFlags.KEEP_CURRENT) {
          // Subtracting 100_00 to be consistent with the engine as 100_00 gets added while setting the liqBonus
          updates[i].liqBonus = cfg.liquidationBonus - 100_00;
        }

        if (
          keccak256(abi.encode(updates[i].label)) ==
          keccak256(abi.encode(EngineFlags.KEEP_CURRENT_STRING))
        ) {
          updates[i].label = pool.getEModeCategoryLabel(updates[i].eModeCategory);
        }
      }

      if (notAllKeepCurrent) {
        // LT*LB (in %) should never be above 100%, because it means instant undercollateralization
        require(
          updates[i].liqThreshold.percentMul(100_00 + updates[i].liqBonus) <= 100_00,
          'INVALID_LT_LB_RATIO'
        );

        poolConfigurator.setEModeCategory(
          updates[i].eModeCategory,
          updates[i].ltv.toUint16(),
          updates[i].liqThreshold.toUint16(),
          // For reference, this is to simplify the interaction with the Aave protocol,
          // as there the definition is as e.g. 105% (5% bonus for liquidators)
          (100_00 + updates[i].liqBonus).toUint16(),
          updates[i].label
        );
      }
    }
  }

  /**
   * @dev eModes must have a non-zero lt so we select the first that has a zero lt.
   */
  function _findFirstUnusedEmodeCategory(IPool pool) private view returns (uint8) {
    // eMode id 0 is skipped intentially as it is the reserved default
    for (uint8 i = 1; i < 256; i++) {
      if (pool.getEModeCategoryCollateralConfig(i).liquidationThreshold == 0) return i;
    }
    revert NoAvailableEmodeCategory();
  }
}
