// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Address} from 'openzeppelin-contracts/contracts/utils/Address.sol';
import {WadRayMath} from '../../protocol/libraries/math/WadRayMath.sol';
import {IAaveV3ConfigEngine as IEngine} from './IAaveV3ConfigEngine.sol';
import {EngineFlags} from './EngineFlags.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 configs update.
 * - !!!IMPORTANT!!! This payload inheriting AaveV3Payload MUST BE STATELESS always
 * - Assumes this contract has the right permissions
 * - Connected to a IAaveV3ConfigEngine engine contact, which abstract the complexities of
 *   interaction with the Aave protocol.
 * - At the moment covering:
 *   - Listings of new assets on the pool.
 *   - Listings of new assets on the pool with custom token impl.
 *   - Updates of caps (supply cap, borrow cap).
 *   - Updates of price feeds
 *   - Updates of interest rate strategies
 *   - Updates of borrow parameters (flashloanable, borrowableInIsolation, withSiloedBorrowing, reserveFactor)
 *   - Updates of collateral parameters (ltv, liq threshold, liq bonus, liq protocol fee, debt ceiling)
 *   - Updates of emode category parameters (ltv, liq threshold, liq bonus, price source, label)
 *   - Updates of emode category of assets (e-mode id)
 * @author BGD Labs
 */
abstract contract AaveV3Payload {
  using Address for address;

  IEngine public immutable CONFIG_ENGINE;

  constructor(IEngine engine) {
    CONFIG_ENGINE = engine;
  }

  /// @dev to be overriden on the child if any extra logic is needed pre-listing
  function _preExecute() internal virtual {}

  /// @dev to be overriden on the child if any extra logic is needed post-listing
  function _postExecute() internal virtual {}

  function execute() external {
    _preExecute();

    IEngine.Listing[] memory listings = newListings();
    IEngine.ListingWithCustomImpl[] memory listingsCustom = newListingsCustom();
    IEngine.EModeCategoryUpdate[] memory eModeCategories = eModeCategoriesUpdates();
    IEngine.AssetEModeUpdate[] memory assetsEModes = assetsEModeUpdates();
    IEngine.EModeCategoryCreation[] memory newEmodes = eModeCategoryCreations();
    IEngine.CollateralUpdate[] memory collaterals = collateralsUpdates();
    IEngine.BorrowUpdate[] memory borrows = borrowsUpdates();
    IEngine.RateStrategyUpdate[] memory rates = rateStrategiesUpdates();
    IEngine.PriceFeedUpdate[] memory priceFeeds = priceFeedsUpdates();
    IEngine.CapsUpdate[] memory caps = capsUpdates();

    if (listings.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.listAssets.selector, getPoolContext(), listings)
      );
    }

    if (listingsCustom.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(
          CONFIG_ENGINE.listAssetsCustom.selector,
          getPoolContext(),
          listingsCustom
        )
      );
    }

    if (eModeCategories.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateEModeCategories.selector, eModeCategories)
      );
    }

    if (assetsEModes.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateAssetsEMode.selector, assetsEModes)
      );
    }

    if (newEmodes.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.createEModeCategories.selector, newEmodes)
      );
    }

    if (borrows.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateBorrowSide.selector, borrows)
      );
    }

    if (collaterals.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateCollateralSide.selector, collaterals)
      );
    }

    if (rates.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateRateStrategies.selector, rates)
      );
    }

    if (priceFeeds.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updatePriceFeeds.selector, priceFeeds)
      );
    }

    if (caps.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateCaps.selector, caps)
      );
    }

    _postExecute();
  }

  /** @dev Converts basis points to RAY units
   * e.g. 10_00 (10.00%) will return 100000000000000000000000000
   */
  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * WadRayMath.RAY) / 10_000;
  }

  /// @dev to be defined in the child with a list of new assets to list
  function newListings() public view virtual returns (IEngine.Listing[] memory) {}

  /// @dev to be defined in the child with a list of new assets to list (with custom a/v/s tokens implementations)
  function newListingsCustom()
    public
    view
    virtual
    returns (IEngine.ListingWithCustomImpl[] memory)
  {}

  /// @dev to be defined in the child with a list of caps to update
  function capsUpdates() public view virtual returns (IEngine.CapsUpdate[] memory) {}

  /// @dev to be defined in the child with a list of collaterals' params to update
  function collateralsUpdates() public view virtual returns (IEngine.CollateralUpdate[] memory) {}

  /// @dev to be defined in the child with a list of borrows' params to update
  function borrowsUpdates() public view virtual returns (IEngine.BorrowUpdate[] memory) {}

  /// @dev to be defined in the child with a list of priceFeeds to update
  function priceFeedsUpdates() public view virtual returns (IEngine.PriceFeedUpdate[] memory) {}

  /// @dev to be defined in the child with a list of eMode categories to create
  function eModeCategoryCreations()
    public
    view
    virtual
    returns (IEngine.EModeCategoryCreation[] memory)
  {}

  /// @dev to be defined in the child with a list of eMode categories to update
  function eModeCategoriesUpdates()
    public
    view
    virtual
    returns (IEngine.EModeCategoryUpdate[] memory)
  {}

  /// @dev to be defined in the child with a list of assets for which eMode collateral to update
  function assetsEModeUpdates() public view virtual returns (IEngine.AssetEModeUpdate[] memory) {}

  /// @dev to be defined in the child with a list of set of parameters of rate strategies
  function rateStrategiesUpdates()
    public
    view
    virtual
    returns (IEngine.RateStrategyUpdate[] memory)
  {}

  /// @dev the lack of support for immutable strings kinds of forces for this
  /// Besides that, it can actually be useful being able to change the naming, but remote
  function getPoolContext() public view virtual returns (IEngine.PoolContext memory);
}
