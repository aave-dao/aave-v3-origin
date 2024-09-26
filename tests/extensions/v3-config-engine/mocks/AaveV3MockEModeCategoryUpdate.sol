// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../../../src/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Smart contract for a mock emode category update, to be able to test
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @dev Inheriting directly from AaveV3Payload for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3MockEModeCategoryUpdate is AaveV3Payload {
  constructor(address customEngine) AaveV3Payload(IEngine(customEngine)) {}

  function eModeCategoriesUpdates()
    public
    pure
    override
    returns (IEngine.EModeCategoryUpdate[] memory)
  {
    IEngine.EModeCategoryUpdate[] memory eModeUpdates = new IEngine.EModeCategoryUpdate[](1);

    eModeUpdates[0] = IEngine.EModeCategoryUpdate({
      eModeCategory: 1,
      ltv: 97_40,
      liqThreshold: 97_60,
      liqBonus: 1_50,
      label: 'ETH Correlated'
    });

    return eModeUpdates;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Polygon', networkAbbreviation: 'Pol'});
  }
}

/**
 * @dev Smart contract for a mock emode category update, to be able to test
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @dev Inheriting directly from AaveV3Payload for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3MockEModeCategoryUpdateEdgeBonus is AaveV3Payload {
  constructor(address customEngine) AaveV3Payload(IEngine(customEngine)) {}

  function eModeCategoriesUpdates()
    public
    pure
    override
    returns (IEngine.EModeCategoryUpdate[] memory)
  {
    IEngine.EModeCategoryUpdate[] memory eModeUpdates = new IEngine.EModeCategoryUpdate[](1);

    eModeUpdates[0] = IEngine.EModeCategoryUpdate({
      eModeCategory: 1,
      ltv: 97_40,
      liqThreshold: 97_60,
      liqBonus: 2_50,
      label: EngineFlags.KEEP_CURRENT_STRING
    });

    return eModeUpdates;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Local', networkAbbreviation: 'Loc'});
  }
}
