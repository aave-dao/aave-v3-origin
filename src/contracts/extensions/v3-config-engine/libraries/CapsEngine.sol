// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {EngineFlags} from '../EngineFlags.sol';
import {IAaveV3ConfigEngine as IEngine, IPoolConfigurator} from '../IAaveV3ConfigEngine.sol';

library CapsEngine {
  function executeCapsUpdate(
    IEngine.EngineConstants calldata engineConstants,
    IEngine.CapsUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    _configureCaps(engineConstants.poolConfigurator, updates);
  }

  function _configureCaps(
    IPoolConfigurator poolConfigurator,
    IEngine.CapsUpdate[] memory caps
  ) internal {
    for (uint256 i = 0; i < caps.length; i++) {
      if (caps[i].supplyCap != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setSupplyCap(caps[i].asset, caps[i].supplyCap);
      }

      if (caps[i].borrowCap != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setBorrowCap(caps[i].asset, caps[i].borrowCap);
      }
    }
  }
}
