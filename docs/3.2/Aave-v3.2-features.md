# Features

<br>

## Deprecation of stable debt

Currently, there is no active position with stable rate mode on any Aave instance.
As it is a deprecated feature that will not be used in the future, it is possible to remove all logic related with stable rate mode from the protocol, to increase gas efficiency and decrease code complexity.

<br>

### Changes

#### Core

- Listing of new assets now does no longer instantiate a stable debt token
- It is no longer possible to upgrade stable debt tokens or do any configurator change of the stable rate via the PoolConfigurator
- All Pool functions related with stable rate mode are removed
- Usage of `getUserCurrentDebt()` (before aggregating variable + stable) is now replaced by directly querying only variable.
- Removed getters and setters of stable rate from ReserveConfiguration. The position on the bitmap is deprecated, as as stable rate is already disabled for all assets listed, with 0 value there.
- When borrowing, repaying or flash loaning (keeping debt open), ValidationLogic now enforces that the mode is variable, reverting on stable.
- Removed all logic related with stable rate mode on ValidationLogic.
- Removed deprecated ReserveStableRateBorrowing and StableDebtTokenUpgraded events on `PoolConfigurator`
- **BREAKING**: Modified DefaultReserveInterestRateStrategyV2 to only consider variable on the debt side. Breaking changes for anybody querying the strategy directly.

#### Periphery

- Paraswap adapters change to be consistent with pool borrow dynamics: reverting if trying to enter a stable rate position.
- Config engine (and payloads base) modified to not receive anymore input of stable rate mode, and adapted to the changes on PoolConfigurator.
- AaveProtocolDataProvider adapted to the removal of stable rate, but keeping backwards compatibility.
- UiIncentiveDataProviderV3 removing stable debt tokens data, but keeping interface compatible (returning 0 values)
- Modifications on UIPoolDataProvider to remove stable debt related logic, but keeping compatibility (returning 0 values).
- WrappedTokenGatewayV3 do not have borrowRate parameter on borrow and repay methods anymore

<br>

### Migration guide

For anyone directly integrating with the InterestRateStrategy the method `calculateInterestRates` will no longer return the stable rate and therefore usage must be adjusted.

```diff
function calculateInterestRates(
  DataTypes.CalculateInterestRatesParams memory params
- ) external view returns (uint256, uint256, uint256);
+ ) external view returns (uint256, uint256);
```

<br>

## Liquid eModes

The new Liquid eMode feature of Aave v3.2 removes the previous constraint: **an asset listed on Aave can be eligible for different eModes, and then it only depends on the user to choose which eMode he wants to enter to.**

For example, with liquid eModes, a possible configuration not doable before would be:

- eMode 1, with wstETH, weETH and WETH.
- eMode 2, with wstETH and WETH.
- eMode 3, with weETH and WETH.
- eMode 4, with WETH and GHO.

So then, user A holding the wstETH and weETH collaterals, could borrow WETH at high LTV.
User B holding only wstETH could borrow WETH at high (but different) LTV.
User C holding only weETH could similarly borrow WETH at a different LTV than the previous two eModes.
User D could have a position with WETH collateral and GHO borrowings.

This doesn’t stop there, as more sophisticated configuration strategies could be adopted, like:

- eMode for only WETH and stablecoins.
- eMode for onboarding less mature LSTs, without requiring them being together with all major LSTs.

**For extra configuration flexibility, liquid eModes also allow now to flag an asset as only borrowable, only collateral, or both, in the context of an eMode.**
For example, in a hypothetic eMode with only wstETH and WETH, the normal configuration would be wstETH as only collateral and WETH as only borrowable, fully focusing on the wstETH leverage use-case.

<br>

### Borrowable in eMode

This feature allows configuring which assets can be borrowed in a certain eMode via a bitmask.

- When an eMode is created no assets can be borrowed per default. Each asset has to be allowed independently.
- If an asset `borrowable` is disabled after someone has borrowed that asset, the position will remain intact, but borrow exposure cannot be increased.
- If a position has something borrowed that is not `borrowable` on eMode the position has to be repaid before being able to enter the eMode
- For an asset to be borrowable in eMode it must be borrowable outside eMode as well

<br>

### Collateral in eModes

This feature allows configuring an asset to be collateral in a specified eMode via a bitmap.

- When an eMode is created no asset can be collateral per default. Each asset has to be added explicitly.
- If an asset is no eMode collateral it can still be collateral (just not with eMode LT/LTV/LB).
- For an asset to be collateral in eMode, it must be collateral outside eMode as well.

<br>

### Removal of the eMode oracle

The eMode oracle has never been used and there is no intention do enable one in the future.
Therefore to save some gas on storage packing, the eMode oracle has been removed.

Note: The methods to alter configuration do not validate for an asset / eMode to exist.
This is to stay consistent with the current methods on `PoolConfigurator`, as there are multiple layers of security/risk procedures on updates to not create any issues.

<br>

### Properties/rules

#### General eMode rules

- Positions can use **any** collateral while being in an eMode. The eMode LT/LTV will only apply for the ones listed as eModeCollateral for that specific eMode, while the others will use their non-eMode LT/LTV
- You can only borrow assets that are borrowable in your specific eMode`*`.
- When being liquidated (and any Health Factor calculation) the eMode LT/LB will only apply to your eMode collaterals.
- eMode = 0 is a special case, being reserved as "no eMode". No eMode rules are applied on eMode `0`.
- For an asset to be borrowable in eMode it must be borrowable outside eMode as well.
- For an asset to be collateral in eMode it must be collateral outside of eMode as well.

`*` There is the theoretic possibility that a borrowable asset becomes unborrowable due to governance intervention. In this case, the position stays intact, but the exposure can no longer be increased.

#### Enter/switch/leave an eMode

For a user to be able to enter/switch an eMode:

- The health factor of the user must be >= 1 after the switch.
- All borrowed assets must be borrowable in the new eMode.
- Leaving an eMode (switching to eMode 0) is possible as long as the health factor after leaving would not drop below 1.

<br>

### Changelog

#### Core

- When entering an eMode the Health Factor now is always validated. Before, there was a skip on `0 -> n` as it was assumed that eMode LT would always be higher than non-eMode LT for all assets, which is not a constraint anymore.
- eMode creation no longer validates that all assets have LT < eMode LT as the enforcement is not necessary.
- `Pool.getEModeCategoryData` is deprecated and might be removed in a future version.
- `Pool.getEModeCategoryData().eModeOracle` will always return `address(0)`
- On `ValidationLogic.validateBorrow`, it is ensured that the asset is borrowable in the user's current eMode.
- On `ValidationLogic.validateSetUserEmode` it is ensured that the user is only borrowing assets that are borrowable in a given eMode.
- **BREAKING**: `AaveProtocolDataProvider.getReserveEModeCategory` was removed as as there no longer is a `1:1` relation between assets and eModes.
- **BREAKING**: The event `EModeAssetCategoryChanged ` will no longer be emitted, because its values would be misleading. Therefore `AssetCollateralInEModeChanged` and `AssetBorrowableInEModeChanged` have been introduced.
- **BREAKING**: `reserveConfig.getEModeCategory()` will return the current eMode, but will no longer be updated and is flagged deprecated.

#### Periphery

- `UiPoolDataProvider` has been altered to no longer return the eMode per asset, but exposes a new method to get all eModes.
- `ConfigEngine` eMode creation has been altered to no longer accept an eMode priceOracle.
- `ConfigEngine` listings have been altered to no longer accept an eModeCategory.
- `ConfigEngine.updateAssetsEMode` has been altered to accept a `borrowable/collateral` flag.

<br>

### Migration guide

For existing users, the upgrade is 100% backwards compatible and no migration or similar is required.
Entering and leaving an eMode still works via `setUserEMode(categoryId)` and `getUserEMode(address user)` like in previous versions of the protocol.

#### Indexers

As collateral/borrowable flags are newly introduced, two new events are being emitted instead of the current `EModeAssetCategoryChanged`:

- `event AssetCollateralInEModeChanged(address indexed asset, uint8 categoryId, bool collateral);`
- `event AssetBorrowableInEModeChanged(address indexed asset, uint8 categoryId, bool borrowable);`

**Note**: As part of the migration proposal, these new events will be emitted for all existing eModes & assets, so that by only listening to the new events the full state can be derived.

#### Getters

In aave 3.1 all eMode parameters were exposed via a single `getEModeCategoryData` getter.
When checking existing integrations, we noticed that in most cases this approach is suboptimal, given that users only rely on a subset of the data.
Therefore in addition to the **deprecated** `getEModeCategoryData` getter there are now independent getters for the respective values:

- `getEModeCategoryCollateralConfig(categoryId)`, returning the eMode ltv,lt,lb
- `getEModeCategoryLabel(categoryId)`, returning the eMode label
- `getEModeCategoryCollateralBitmap(categoryId)`, returning the collateral bitmap
- `getEModeCategoryBorrowableBitmap(categoryId)`, returning the borrowable bitmap

#### Identifying eModes for an asset

In the previous version of the eModes feature it was possible to query a reserve configuration to receive its unique eMode.
This is no longer possible as there can be multiple eModes assigned to an asset.

To identify eModes of a selected asset, there is multiple options:

- onchain one can iterate trough eModes and select the "correct one" based on your application specific needs.

```sol
for (uint8 i = 1; i < 255; i++) {
    DataTypes.CollateralConfig memory cfg = pool.getEModeCategoryCollateralConfig(i);
    // check if it is an active eMode
    if (cfg.liquidationThreshold != 0) {
        EModeConfiguration.isReserveEnabledOnBitmap(pool.getEModeCategoryCollateralBitmap(i), someReserveIndex);
        EModeConfiguration.isReserveEnabledOnBitmap(pool.getEModeCategoryBorrowableBitmap(i), someReserveIndex);
    }
}
```

- an offchain system could listen to `AssetCollateralInEModeChanged` & `AssetBorrowableInEModeChanged` events and feed the onchain contract with an desired categoryId

#### Deprecations

- `getEModeCategoryData` was deprecated and might be removed in a future version. Use `getEModeCategoryCollateralConfig`, `getEModeCategoryLabel`, `getEModeCategoryCollateralBitmap` & `getEModeCategoryBorrowableBitmap` instead.
- `getReserveDataExtended` was deprecated and might be removed in a future version. Use `getReserveData` & `getLiquidationGracePeriod` instead.
