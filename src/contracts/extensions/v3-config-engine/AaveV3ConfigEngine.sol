// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {CapsEngine} from './libraries/CapsEngine.sol';
import {BorrowEngine} from './libraries/BorrowEngine.sol';
import {CollateralEngine} from './libraries/CollateralEngine.sol';
import {RateEngine} from './libraries/RateEngine.sol';
import {PriceFeedEngine} from './libraries/PriceFeedEngine.sol';
import {EModeEngine} from './libraries/EModeEngine.sol';
import {ListingEngine} from './libraries/ListingEngine.sol';
import './IAaveV3ConfigEngine.sol';

/**
 * @dev Helper smart contract abstracting the complexity of changing configurations on Aave v3, simplifying
 * - !!!IMPORTANT!!! This engine MUST BE STATELESS always, as in practise is a library to be used via DELEGATECALL
 * listing flow and parameters updates.
 * - It is planned to be used via delegatecall, by any contract having appropriate permissions to
 * do a listing, or any other granular config
 * Assumptions:
 * - Only one RewardsController for all assets
 * - Only one Collector for all assets
 * @author BGD Labs
 */
contract AaveV3ConfigEngine is IAaveV3ConfigEngine {
  IPool public immutable POOL;
  IPoolConfigurator public immutable POOL_CONFIGURATOR;
  IAaveOracle public immutable ORACLE;
  address public immutable ATOKEN_IMPL;
  address public immutable VTOKEN_IMPL;
  address public immutable REWARDS_CONTROLLER;
  address public immutable COLLECTOR;
  address public immutable DEFAULT_INTEREST_RATE_STRATEGY;

  constructor(address aTokenImpl, address vTokenImpl, EngineConstants memory engineConstants) {
    require(
      address(engineConstants.pool) != address(0) &&
        address(engineConstants.poolConfigurator) != address(0) &&
        address(engineConstants.oracle) != address(0) &&
        engineConstants.rewardsController != address(0) &&
        engineConstants.collector != address(0) &&
        engineConstants.defaultInterestRateStrategy != address(0),
      'ONLY_NONZERO_ENGINE_CONSTANTS'
    );

    require(aTokenImpl != address(0) && vTokenImpl != address(0), 'ONLY_NONZERO_TOKEN_IMPLS');

    ATOKEN_IMPL = aTokenImpl;
    VTOKEN_IMPL = vTokenImpl;
    POOL = engineConstants.pool;
    POOL_CONFIGURATOR = engineConstants.poolConfigurator;
    ORACLE = engineConstants.oracle;
    REWARDS_CONTROLLER = engineConstants.rewardsController;
    COLLECTOR = engineConstants.collector;
    DEFAULT_INTEREST_RATE_STRATEGY = engineConstants.defaultInterestRateStrategy;
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function listAssets(PoolContext calldata context, Listing[] calldata listings) external {
    require(listings.length != 0, 'AT_LEAST_ONE_ASSET_REQUIRED');

    ListingWithCustomImpl[] memory customListings = new ListingWithCustomImpl[](listings.length);
    for (uint256 i = 0; i < listings.length; i++) {
      customListings[i] = ListingWithCustomImpl({
        base: listings[i],
        implementations: TokenImplementations({aToken: ATOKEN_IMPL, vToken: VTOKEN_IMPL})
      });
    }

    listAssetsCustom(context, customListings);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function listAssetsCustom(
    PoolContext calldata context,
    ListingWithCustomImpl[] memory listings
  ) public {
    ListingEngine.executeCustomAssetListing(context, _getEngineConstants(), listings);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateCaps(CapsUpdate[] calldata updates) external {
    CapsEngine.executeCapsUpdate(_getEngineConstants(), updates);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updatePriceFeeds(PriceFeedUpdate[] calldata updates) external {
    PriceFeedEngine.executePriceFeedsUpdate(_getEngineConstants(), updates);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateCollateralSide(CollateralUpdate[] calldata updates) external {
    CollateralEngine.executeCollateralSide(_getEngineConstants(), updates);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateBorrowSide(BorrowUpdate[] calldata updates) external {
    BorrowEngine.executeBorrowSide(_getEngineConstants(), updates);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateRateStrategies(RateStrategyUpdate[] calldata updates) external {
    RateEngine.executeRateStrategiesUpdate(_getEngineConstants(), updates);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function createEModeCategories(EModeCategoryCreation[] calldata creations) external {
    EModeEngine.executeEModeCategoriesCreate(_getEngineConstants(), creations);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateEModeCategories(EModeCategoryUpdate[] calldata updates) external {
    EModeEngine.executeEModeCategoriesUpdate(_getEngineConstants(), updates);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateAssetsEMode(AssetEModeUpdate[] calldata updates) external {
    EModeEngine.executeAssetsEModeUpdate(_getEngineConstants(), updates);
  }

  function _getEngineConstants() internal view returns (EngineConstants memory) {
    return
      EngineConstants({
        pool: POOL,
        poolConfigurator: POOL_CONFIGURATOR,
        defaultInterestRateStrategy: DEFAULT_INTEREST_RATE_STRATEGY,
        oracle: ORACLE,
        rewardsController: REWARDS_CONTROLLER,
        collector: COLLECTOR
      });
  }
}
