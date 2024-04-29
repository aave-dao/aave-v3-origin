// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../../../src/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Smart contract for a mock price feed update, to be able to test
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @dev Inheriting directly from AaveV3Payload for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3MockPriceFeedUpdate is AaveV3Payload {
  address public immutable ASSET_ADDRESS;
  address public immutable ASSET_FEED;

  constructor(
    address assetAddress,
    address feed,
    address customEngine
  ) AaveV3Payload(IEngine(customEngine)) {
    ASSET_ADDRESS = assetAddress;
    ASSET_FEED = feed;
  }

  function priceFeedsUpdates() public view override returns (IEngine.PriceFeedUpdate[] memory) {
    IEngine.PriceFeedUpdate[] memory priceFeedsUpdate = new IEngine.PriceFeedUpdate[](1);

    priceFeedsUpdate[0] = IEngine.PriceFeedUpdate({asset: ASSET_ADDRESS, priceFeed: ASSET_FEED});

    return priceFeedsUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Local', networkAbbreviation: 'Loc'});
  }
}
