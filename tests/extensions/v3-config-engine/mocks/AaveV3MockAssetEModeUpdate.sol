// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../../../src/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Smart contract for a mock asset e-mode update, for testing purposes
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV3MockAssetEModeUpdate is AaveV3Payload {
  address public immutable ASSET_ADDRESS;

  constructor(address assetAddress, address customEngine) AaveV3Payload(IEngine(customEngine)) {
    ASSET_ADDRESS = assetAddress;
  }

  function eModeCollateralUpdates()
    public
    view
    override
    returns (IEngine.EModeCollateralUpdate[] memory)
  {
    IEngine.EModeCollateralUpdate[] memory eModeUpdate = new IEngine.EModeCollateralUpdate[](1);

    eModeUpdate[0] = IEngine.EModeCollateralUpdate({
      asset: ASSET_ADDRESS,
      eModeCategory: 1,
      enabled: true
    });

    return eModeUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Local', networkAbbreviation: 'Loc'});
  }
}
