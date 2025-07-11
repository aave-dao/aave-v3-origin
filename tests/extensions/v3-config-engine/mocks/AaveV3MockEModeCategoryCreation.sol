// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../../../src/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Smart contract for a mock emode category update, to be able to test
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @dev Inheriting directly from AaveV3Payload for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3MockEModeCategoryCreation is AaveV3Payload {
  address immutable COLLATERAL_ONE;
  address immutable COLLATERAL_TWO;

  address immutable BORROWABLE_ONE;
  address immutable BORROWABLE_TWO;

  constructor(
    address collateral1,
    address collateral2,
    address borrowable1,
    address borrowable2,
    address customEngine
  ) AaveV3Payload(IEngine(customEngine)) {
    COLLATERAL_ONE = collateral1;
    COLLATERAL_TWO = collateral2;
    BORROWABLE_ONE = borrowable1;
    BORROWABLE_TWO = borrowable2;
  }

  function eModeCategoryCreations()
    public
    view
    override
    returns (IEngine.EModeCategoryCreation[] memory)
  {
    IEngine.EModeCategoryCreation[] memory eModeUpdates = new IEngine.EModeCategoryCreation[](2);
    address[] memory empty = new address[](0);

    eModeUpdates[0] = IEngine.EModeCategoryCreation({
      ltv: 50_00,
      liqThreshold: 60_00,
      liqBonus: 1_00,
      label: 'No assets',
      borrowables: empty,
      collaterals: empty
    });

    address[] memory collaterals = new address[](2);
    address[] memory borrowables = new address[](2);
    collaterals[0] = COLLATERAL_ONE;
    collaterals[1] = COLLATERAL_TWO;
    borrowables[0] = BORROWABLE_ONE;
    borrowables[1] = BORROWABLE_TWO;

    eModeUpdates[1] = IEngine.EModeCategoryCreation({
      ltv: 97_40,
      liqThreshold: 97_60,
      liqBonus: 1_50,
      label: 'Test',
      borrowables: borrowables,
      collaterals: collaterals
    });

    return eModeUpdates;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Polygon', networkAbbreviation: 'Pol'});
  }
}
