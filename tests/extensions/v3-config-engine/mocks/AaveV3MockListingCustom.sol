// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../../../src/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Smart contract for a mock custom listing update, for testing purposes
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV3MockListingCustom is AaveV3Payload {
  address public immutable ASSET_ADDRESS;
  address public immutable ASSET_FEED;

  address public immutable A_TOKEN_IMPL;
  address public immutable V_TOKEN_IMPL;

  constructor(
    address assetAddress,
    address assetFeed,
    address customEngine,
    address aTokenImpl,
    address vTokenImpl
  ) AaveV3Payload(IEngine(customEngine)) {
    ASSET_ADDRESS = assetAddress;
    ASSET_FEED = assetFeed;
    A_TOKEN_IMPL = aTokenImpl;
    V_TOKEN_IMPL = vTokenImpl;
  }

  function newListingsCustom()
    public
    view
    override
    returns (IEngine.ListingWithCustomImpl[] memory)
  {
    IEngine.ListingWithCustomImpl[] memory listingsCustom = new IEngine.ListingWithCustomImpl[](1);

    listingsCustom[0] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: ASSET_ADDRESS,
        assetSymbol: 'PSP',
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
      }),
      IEngine.TokenImplementations({aToken: A_TOKEN_IMPL, vToken: V_TOKEN_IMPL})
    );

    return listingsCustom;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Local', networkAbbreviation: 'Loc'});
  }
}
