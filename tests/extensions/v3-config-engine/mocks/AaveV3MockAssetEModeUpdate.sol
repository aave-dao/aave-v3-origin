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
  address public immutable ASSET_2_ADDRESS;

  constructor(
    address assetAddress,
    address asset2Address,
    address customEngine
  ) AaveV3Payload(IEngine(customEngine)) {
    ASSET_ADDRESS = assetAddress;
    ASSET_2_ADDRESS = asset2Address;
  }

  function assetsEModeUpdates() public view override returns (IEngine.AssetEModeUpdate[] memory) {
    IEngine.AssetEModeUpdate[] memory eModeUpdate = new IEngine.AssetEModeUpdate[](2);

    eModeUpdate[0] = IEngine.AssetEModeUpdate({
      asset: ASSET_ADDRESS,
      eModeCategory: 1,
      collateral: EngineFlags.DISABLED,
      borrowable: EngineFlags.ENABLED
    });
    eModeUpdate[1] = IEngine.AssetEModeUpdate({
      asset: ASSET_2_ADDRESS,
      eModeCategory: 1,
      collateral: EngineFlags.ENABLED,
      borrowable: EngineFlags.KEEP_CURRENT
    });

    return eModeUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Local', networkAbbreviation: 'Loc'});
  }
}
