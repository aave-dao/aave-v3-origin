// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {Address} from 'openzeppelin-contracts/contracts/utils/Address.sol';
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
  using Address for address;

  IPool public immutable POOL;
  IPoolConfigurator public immutable POOL_CONFIGURATOR;
  IAaveOracle public immutable ORACLE;
  address public immutable ATOKEN_IMPL;
  address public immutable VTOKEN_IMPL;
  address public immutable REWARDS_CONTROLLER;
  address public immutable COLLECTOR;
  address public immutable DEFAULT_INTEREST_RATE_STRATEGY;

  address public immutable BORROW_ENGINE;
  address public immutable CAPS_ENGINE;
  address public immutable COLLATERAL_ENGINE;
  address public immutable EMODE_ENGINE;
  address public immutable LISTING_ENGINE;
  address public immutable PRICE_FEED_ENGINE;
  address public immutable RATE_ENGINE;

  /**
   * @dev Constructor.
   * @param aTokenImpl The address of default aToken implementation.
   * @param vTokenImpl The address of default variable debt token implementation.
   * @param engineConstants The struct containing all the engine constants.
   * @param engineLibraries The struct containing the addresses of stateless libraries containing the engine logic.
   */
  constructor(
    address aTokenImpl,
    address vTokenImpl,
    EngineConstants memory engineConstants,
    EngineLibraries memory engineLibraries
  ) {
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

    require(
      engineLibraries.borrowEngine != address(0) &&
        engineLibraries.capsEngine != address(0) &&
        engineLibraries.listingEngine != address(0) &&
        engineLibraries.priceFeedEngine != address(0) &&
        engineLibraries.rateEngine != address(0),
      'ONLY_NONZERO_ENGINE_LIBRARIES'
    );

    ATOKEN_IMPL = aTokenImpl;
    VTOKEN_IMPL = vTokenImpl;
    POOL = engineConstants.pool;
    POOL_CONFIGURATOR = engineConstants.poolConfigurator;
    ORACLE = engineConstants.oracle;
    REWARDS_CONTROLLER = engineConstants.rewardsController;
    COLLECTOR = engineConstants.collector;
    DEFAULT_INTEREST_RATE_STRATEGY = engineConstants.defaultInterestRateStrategy;
    BORROW_ENGINE = engineLibraries.borrowEngine;
    CAPS_ENGINE = engineLibraries.capsEngine;
    COLLATERAL_ENGINE = engineLibraries.collateralEngine;
    EMODE_ENGINE = engineLibraries.eModeEngine;
    LISTING_ENGINE = engineLibraries.listingEngine;
    PRICE_FEED_ENGINE = engineLibraries.priceFeedEngine;
    RATE_ENGINE = engineLibraries.rateEngine;
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
    LISTING_ENGINE.functionDelegateCall(
      abi.encodeWithSelector(
        ListingEngine.executeCustomAssetListing.selector,
        context,
        _getEngineConstants(),
        _getEngineLibraries(),
        listings
      )
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateCaps(CapsUpdate[] calldata updates) external {
    CAPS_ENGINE.functionDelegateCall(
      abi.encodeWithSelector(CapsEngine.executeCapsUpdate.selector, _getEngineConstants(), updates)
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updatePriceFeeds(PriceFeedUpdate[] calldata updates) external {
    PRICE_FEED_ENGINE.functionDelegateCall(
      abi.encodeWithSelector(
        PriceFeedEngine.executePriceFeedsUpdate.selector,
        _getEngineConstants(),
        updates
      )
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateCollateralSide(CollateralUpdate[] calldata updates) external {
    COLLATERAL_ENGINE.functionDelegateCall(
      abi.encodeWithSelector(
        CollateralEngine.executeCollateralSide.selector,
        _getEngineConstants(),
        updates
      )
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateBorrowSide(BorrowUpdate[] calldata updates) external {
    BORROW_ENGINE.functionDelegateCall(
      abi.encodeWithSelector(
        BorrowEngine.executeBorrowSide.selector,
        _getEngineConstants(),
        updates
      )
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateRateStrategies(RateStrategyUpdate[] calldata updates) external {
    RATE_ENGINE.functionDelegateCall(
      abi.encodeWithSelector(
        RateEngine.executeRateStrategiesUpdate.selector,
        _getEngineConstants(),
        updates
      )
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function createEModeCategories(EModeCategoryCreation[] calldata creations) external {
    EMODE_ENGINE.functionDelegateCall(
      abi.encodeWithSelector(
        EModeEngine.executeEModeCategoriesCreate.selector,
        _getEngineConstants(),
        creations
      )
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateEModeCategories(EModeCategoryUpdate[] calldata updates) external {
    EMODE_ENGINE.functionDelegateCall(
      abi.encodeWithSelector(
        EModeEngine.executeEModeCategoriesUpdate.selector,
        _getEngineConstants(),
        updates
      )
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateAssetsEMode(AssetEModeUpdate[] calldata updates) external {
    EMODE_ENGINE.functionDelegateCall(
      abi.encodeWithSelector(
        EModeEngine.executeAssetsEModeUpdate.selector,
        _getEngineConstants(),
        updates
      )
    );
  }

  function _getEngineLibraries() internal view returns (EngineLibraries memory) {
    return
      EngineLibraries({
        listingEngine: LISTING_ENGINE,
        eModeEngine: EMODE_ENGINE,
        borrowEngine: BORROW_ENGINE,
        collateralEngine: COLLATERAL_ENGINE,
        priceFeedEngine: PRICE_FEED_ENGINE,
        rateEngine: RATE_ENGINE,
        capsEngine: CAPS_ENGINE
      });
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
