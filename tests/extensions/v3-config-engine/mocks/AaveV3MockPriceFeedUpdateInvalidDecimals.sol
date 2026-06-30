// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../../../src/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Smart contract for a mock price feed update with invalid decimals, for testing purposes
 * Tests that PriceFeedEngine properly validates that price feeds must use 8 decimals
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV3MockPriceFeedUpdateInvalidDecimals is AaveV3Payload {
  address public immutable ASSET_ADDRESS;
  address public immutable PRICE_FEED_ADDRESS;

  constructor(
    address assetAddress,
    address priceFeedAddress,
    address customEngine
  ) AaveV3Payload(IEngine(customEngine)) {
    ASSET_ADDRESS = assetAddress;
    PRICE_FEED_ADDRESS = priceFeedAddress;
  }

  function priceFeedsUpdates() public view override returns (IEngine.PriceFeedUpdate[] memory) {
    IEngine.PriceFeedUpdate[] memory updates = new IEngine.PriceFeedUpdate[](1);

    updates[0] = IEngine.PriceFeedUpdate({
      asset: ASSET_ADDRESS,
      priceFeed: PRICE_FEED_ADDRESS // This feed has 18 decimals instead of 8
    });

    return updates;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Local', networkAbbreviation: 'Loc'});
  }
}
