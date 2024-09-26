// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../../../src/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Smart contract for a mock listing, to be able to test without having a v3 instance on Local
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @dev Inheriting directly from AaveV3Payload for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3MockListing is AaveV3Payload {
  address public immutable ASSET_ADDRESS;
  address public immutable ASSET_FEED;

  constructor(
    address assetAddress,
    address assetFeed,
    address customEngine
  ) AaveV3Payload(IEngine(customEngine)) {
    ASSET_ADDRESS = assetAddress;
    ASSET_FEED = assetFeed;
  }

  function newListings() public view override returns (IEngine.Listing[] memory) {
    IEngine.Listing[] memory listings = new IEngine.Listing[](1);

    listings[0] = IEngine.Listing({
      asset: ASSET_ADDRESS,
      assetSymbol: '1INCH',
      priceFeed: ASSET_FEED,
      rateStrategyParams: IEngine.InterestRateInputData({
        optimalUsageRatio: 80_00,
        baseVariableBorrowRate: 25, // 0.25%
        variableRateSlope1: 3_00,
        variableRateSlope2: 75_00
      }),
      enabledToBorrow: EngineFlags.ENABLED,
      borrowableInIsolation: EngineFlags.DISABLED,
      withSiloedBorrowing: EngineFlags.DISABLED,
      flashloanable: EngineFlags.DISABLED,
      ltv: 82_50,
      liqThreshold: 86_00,
      liqBonus: 5_00,
      reserveFactor: 10_00,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      liqProtocolFee: 10_00
    });

    return listings;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Local', networkAbbreviation: 'Loc'});
  }
}
