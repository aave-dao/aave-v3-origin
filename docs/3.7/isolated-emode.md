# Isolated eMode (Aave v3.7)

## Table of Contents

- [Overview](#overview)
- [Technical Specification](#technical-specification)
- [Developer / Governance Guide](#developer--governance-guide)

---

## Overview

### What?

A new `bool isolated` flag on eMode categories. When `isolated = true`:

- Only assets explicitly listed in the eMode's `collateralBitmap` contribute LTV. All other assets the user has supplied are treated as LTV-zero (they still contribute to the liquidation threshold and health factor, but cannot back new borrows).
- Users with non-eMode collateral enabled cannot enter the isolated eMode — entry is blocked because those assets would become LTV-zero.
- Users already inside an isolated eMode cannot enable non-eMode assets as collateral.

### Why?

In the current version of Aave (v3.6,) eMode categories define a `collateralBitmap` that determines which assets receive the eMode's enhanced LTV/LT parameters. However, assets outside the bitmap still contribute their regular (non-eMode) LTV. This means a user in an "ETH-correlated" eMode could still borrow against non-ETH collateral at the asset's base LTV, defeating the purpose of the eMode's risk isolation.

The workaround in v3.6 is for governance to manually set `ltvzeroBitmap` bits for every non-eMode asset. Even if very explicit and functional, this is operationally burdensome: it requires an LTV0 of multiple assets on listing.

The `isolated` flag solves this by automatically treating all assets outside the `collateralBitmap` as LTV-zero, removing the need for per-asset manual maintenance (but still allowing granularity via LTV0 on e-Mode).

### Effects

1. **Block eMode entry** -- A user with collateral enabled on assets not in the eMode's `collateralBitmap` cannot enter the isolated eMode, because those assets would become LTV-zero, which could leave the user with zero borrowing power while holding collateral (the same validation that exists today for `ltvzeroBitmap` rejects this).

2. **Block collateral enable** -- While a user is in an isolated eMode, calling `setUserUseReserveAsCollateral(asset, true)` for an asset outside the `collateralBitmap` will return `false` from `validateUseAsCollateral`, preventing enablement, because `getUserReserveLtv` returns 0 for that asset.

3. **Admin live-toggle to LTV=0** -- If governance enables `isolated` on an existing live eMode where users already have non-eMode collateral enabled, those users' non-eMode collateral immediately becomes LTV-zero. They cannot take new borrows against it but are not instantly liquidated (liquidation threshold is unaffected). They can unwind by exiting the eMode or withdrawing the LTV-zero assets first.

---

## Technical Specification

### Single-point Change in `getUserReserveLtv`

The main new validation is implemented on `ValidationLogic.getUserReserveLtv()`:

```solidity
function getUserReserveLtv(
  DataTypes.ReserveData storage reserveData,
  DataTypes.EModeCategory storage eModeCategoryData,
  uint8 categoryId
) internal view returns (uint256) {
  // 1. If the asset is in collateralBitmap, use eMode LTV (or 0 if ltvzero)
  if (
    categoryId != 0 &&
    EModeConfiguration.isReserveEnabledOnBitmap(
      eModeCategoryData.collateralBitmap,
      reserveData.id
    )
  ) {
    if (
      EModeConfiguration.isReserveEnabledOnBitmap(
        eModeCategoryData.ltvzeroBitmap,
        reserveData.id
      )
    ) {
      return 0;
    } else {
      return eModeCategoryData.ltv;
    }
  }
  // 2. NEW: If eMode is isolated, non-collateralBitmap assets get LTV=0
  if (categoryId != 0 && eModeCategoryData.isolated) {
    return 0;
  }
  // 3. Otherwise, fall back to the asset's base LTV
  return reserveData.configuration.getLtv();
}
```

Because `getUserReserveLtv` is the single source of truth for an asset's effective LTV in a user's context, this change automatically cascades through:

- `GenericLogic.calculateUserAccountData` -- LTV-zero assets are flagged in the `hasZeroLtvCollateral` return value, reducing the user's aggregate LTV.
- `validateHFAndLtv` -- Borrows against a position with zero aggregate LTV are rejected (`currentLtv != 0` check).
- `validateHFAndLtvzero` -- Withdraw/transfer of non-LTV-zero assets is blocked when LTV-zero collateral exists, forcing users to unwind the LTV-zero assets first.
- `validateSetUserEMode` -- Entry into the eMode is blocked if the user has collateral enabled on assets that would become LTV-zero (the `getUserReserveLtv(...) != 0` check for enabled collateral rejects it).
- `validateUseAsCollateral` -- Enabling an asset as collateral inside an isolated eMode is blocked if the asset is outside the `collateralBitmap` (returns `false` because `getUserReserveLtv` returns 0).

### Interaction with Existing Mechanisms

| Mechanism                                   | Interaction                                                                                                                                                                             |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `collateralBitmap`                          | Assets in the bitmap get eMode LTV. Assets outside get LTV=0 when `isolated=true` (instead of their base LTV).                                                                          |
| `ltvzeroBitmap`                             | Still works as before for assets inside the `collateralBitmap`. The `ltvzeroBitmap` check runs first, so an asset can be in `collateralBitmap` but still get LTV=0 via `ltvzeroBitmap`. |
| `borrowableBitmap`                          | Unaffected. Borrowable assets are orthogonal to collateral LTV.                                                                                                                         |
| Reserve-level isolation mode (debt ceiling) | Orthogonal. Reserve isolation mode restricts which assets can be borrowed, while eMode isolation restricts which collateral contributes LTV.                                            |

### Storage modification

The `bool isolated` field is packed into the first storage slot of the `EModeCategory` struct, alongside `ltv`, `liquidationThreshold`, `liquidationBonus`, and `collateralBitmap`:

```solidity
struct EModeCategory {
  uint16 ltv; // ─┐
  uint16 liquidationThreshold; //  │ slot 0 (23 / 32 bytes)
  uint16 liquidationBonus; //  │
  uint128 collateralBitmap; //  │
  bool isolated; // ─┘ <-- new, packed into slot 0
  string label; //   slot 1 (dynamic)
  uint128 borrowableBitmap; // ─┐ slot 2 (32 / 32 bytes)
  uint128 ltvzeroBitmap; // ─┘
}
```

Since `EModeCategory` is stored in a mapping (`mapping(uint8 => EModeCategory)`), each entry occupies its own storage slots. The `isolated` field occupies a previously unused byte in slot 0 (which had 10 bytes free). This is safe for proxy upgrades:

- Existing eModes will read `isolated = false` by default (zero-initialized), preserving their current non-isolated behavior. The activation proposal of Aave v3.7 can also set `isolated = true` for the e-Modes desired.
- No existing storage slots are shifted or reinterpreted.
- Reading `isolated` incurs no extra SLOAD since it shares a slot with `ltv`, `liquidationThreshold`, `liquidationBonus`, and `collateralBitmap`.

### Changelog

| File                                                                  | Change                                                                                                                                                                                 |
| --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/contracts/protocol/libraries/types/DataTypes.sol`                | Added `bool isolated` to `EModeCategory` and `EModeCategoryBaseConfiguration`                                                                                                          |
| `src/contracts/protocol/libraries/logic/ValidationLogic.sol`          | Added isolated check in `getUserReserveLtv` (2 lines)                                                                                                                                  |
| `src/contracts/interfaces/IPoolConfigurator.sol`                      | Added `isolated` param to `setEModeCategory`; added `setEModeCategoryIsolated(uint8, bool)`; added new `EModeCategoryIsolationChanged` event (existing `EModeCategoryAdded` unchanged) |
| `src/contracts/interfaces/IPool.sol`                                  | Added `configureEModeCategoryIsolated(uint8, bool)` and `getIsEModeCategoryIsolated(uint8)` getter                                                                                     |
| `src/contracts/protocol/pool/Pool.sol`                                | Implemented `getIsEModeCategoryIsolated`, `configureEModeCategoryIsolated`, and updated `configureEModeCategory`                                                                       |
| `src/contracts/protocol/pool/PoolConfigurator.sol`                    | Updated `setEModeCategory` to accept and forward `isolated`; added `setEModeCategoryIsolated` (`onlyRiskOrPoolOrEmergencyAdmins`); emits `EModeCategoryIsolationChanged`               |
| `src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol`   | Added `isolated` to `EModeCategoryCreation` (bool) and `EModeCategoryUpdate` (uint256)                                                                                                 |
| `src/contracts/extensions/v3-config-engine/libraries/EModeEngine.sol` | Passes `isolated` through to `setEModeCategory`; handles `KEEP_CURRENT` pattern                                                                                                        |
| `src/contracts/helpers/UiPoolDataProviderV3.sol`                      | `getEModes()` returns `isolated` field with backwards-compatible try/catch                                                                                                             |

### Compatibility

| Area                                                 | Scope                  | Before (v3.6)                                | After (v3.7)                                                                       |
| ---------------------------------------------------- | ---------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------- |
| `IPoolConfigurator.setEModeCategory`                 | Admin                  | 5 params: `(categoryId, ltv, lt, lb, label)` | 6 params: `(categoryId, ltv, lt, lb, label, isolated)`                             |
| `EModeCategoryAdded` event                           | External (indexers)    | `(categoryId, ltv, lt, lb, oracle, label)`   | Unchanged (backwards compatible)                                                   |
| New `IPoolConfigurator.setEModeCategoryIsolated`     | Admin                  | N/A                                          | `(categoryId, isolated)` — dedicated setter with `onlyRiskOrPoolOrEmergencyAdmins` |
| New `EModeCategoryIsolationChanged` event            | External (indexers)    | N/A                                          | `(categoryId, isolated)` — emitted alongside `EModeCategoryAdded`                  |
| `DataTypes.EModeCategory` struct                     | Internal               | 7 fields                                     | 8 fields (`bool isolated` packed into slot 0)                                      |
| `DataTypes.EModeCategoryBaseConfiguration` struct    | Internal               | 4 fields                                     | 5 fields (`bool isolated` added)                                                   |
| Config engine `EModeCategoryCreation`                | Admin                  | No `isolated` field                          | `bool isolated` field added                                                        |
| Config engine `EModeCategoryUpdate`                  | Admin                  | No `isolated` field                          | `uint256 isolated` field added (supports `KEEP_CURRENT`)                           |
| New `IPool.getIsEModeCategoryIsolated(uint8)` getter | External (integrators) | N/A                                          | Returns whether the eMode category is isolated                                     |
| `UiPoolDataProviderV3.getEModes()`                   | External (integrators) | No `isolated` in response                    | Returns `isolated` field (try/catch for pre-v3.7 compatibility)                    |

---

## Developer / Governance Guide

### When to Use `isolated=true`

Use `isolated=true` when the eMode category should strictly limit collateral to its explicitly listed assets. This is the recommended approach for:

- **Correlated-asset eModes** (e.g., "ETH-correlated", "BTC-correlated") where non-correlated collateral should not contribute borrowing power.
- **eModes with manual `ltvzeroBitmap` maintenance** -- the `isolated` flag replaces this manual process entirely.

Use `isolated=false` (the default) when the eMode should only provide enhanced parameters for listed assets, but users should still be able to borrow against their other collateral at base LTV.

### Creating an isolated eMode via PoolConfigurator

```solidity
poolConfigurator.setEModeCategory(
    1,              // categoryId
    9000,           // ltv (90%)
    9300,           // liquidationThreshold (93%)
    10100,          // liquidationBonus (101%, i.e., 1% bonus)
    "ETH Correlated", // label
    true            // isolated = true
);

// Then configure assets
poolConfigurator.setAssetCollateralInEMode(weth, 1, true);
poolConfigurator.setAssetCollateralInEMode(wstETH, 1, true);
poolConfigurator.setAssetBorrowableInEMode(weth, 1, true);
poolConfigurator.setAssetBorrowableInEMode(wstETH, 1, true);
```

### Toggling isolation on an existing eMode

A dedicated `setEModeCategoryIsolated(uint8, bool)` setter allows toggling the isolation flag without re-specifying all eMode parameters. It uses the `onlyRiskOrPoolOrEmergencyAdmins` modifier, so emergency admins can isolate/un-isolate an eMode without requiring risk or pool admin privileges:

```solidity
// Emergency admin can isolate an eMode
poolConfigurator.setEModeCategoryIsolated(1, true);

// Or remove isolation
poolConfigurator.setEModeCategoryIsolated(1, false);
```

### Creating via Config Engine

#### EModeCategoryCreation (new eMode)

```solidity
function eModeCategoriesCreation()
  public
  pure
  override
  returns (IAaveV3ConfigEngine.EModeCategoryCreation[] memory)
{
  IAaveV3ConfigEngine.EModeCategoryCreation[]
    memory creations = new IAaveV3ConfigEngine.EModeCategoryCreation[](1);

  address[] memory collaterals = new address[](2);
  collaterals[0] = WETH;
  collaterals[1] = wstETH;

  address[] memory borrowables = new address[](2);
  borrowables[0] = WETH;
  borrowables[1] = wstETH;

  creations[0] = IAaveV3ConfigEngine.EModeCategoryCreation({
    ltv: 90_00,
    liqThreshold: 93_00,
    liqBonus: 1_00, // 1% bonus (engine adds 100_00 internally)
    label: "ETH Correlated",
    collaterals: collaterals,
    borrowables: borrowables,
    isolated: true // <-- new field
  });

  return creations;
}
```

#### EModeCategoryUpdate (existing eMode)

The `isolated` field uses `uint256` to support `EngineFlags.KEEP_CURRENT`:

```solidity
function eModeCategoriesUpdate()
  public
  pure
  override
  returns (IAaveV3ConfigEngine.EModeCategoryUpdate[] memory)
{
  IAaveV3ConfigEngine.EModeCategoryUpdate[]
    memory updates = new IAaveV3ConfigEngine.EModeCategoryUpdate[](1);

  updates[0] = IAaveV3ConfigEngine.EModeCategoryUpdate({
    eModeCategory: 1,
    ltv: EngineFlags.KEEP_CURRENT,
    liqThreshold: EngineFlags.KEEP_CURRENT,
    liqBonus: EngineFlags.KEEP_CURRENT,
    label: EngineFlags.KEEP_CURRENT_STRING,
    isolated: EngineFlags.ENABLED // enable isolation on existing eMode
  });

  return updates;
}
```

### User scenarios

#### Scenario A: User enters an isolated eMode with only eMode-listed collateral

User has WETH supplied and enabled as collateral. WETH is in the eMode's `collateralBitmap`.

- `setUserEMode(1)` succeeds.
- WETH receives the eMode LTV (e.g., 90%).
- User can borrow at the enhanced parameters.

#### Scenario B: User tries to enter isolated eMode with non-eMode collateral enabled

User has WETH and LINK supplied, both enabled as collateral. LINK is not in the eMode's `collateralBitmap`.

- `setUserEMode(1)` reverts with `InvalidCollateralInEmode(LINK, 1)`.
- User must first disable LINK as collateral (or withdraw it), then retry.

#### Scenario C: User in isolated eMode tries to enable non-eMode collateral

User is already in isolated eMode 1 with WETH as collateral. User supplies LINK and tries to enable it as collateral.

- `setUserUseReserveAsCollateral(LINK, true)` returns `false` (the collateral is not enabled).
- LINK is supplied but not used as collateral.

#### Scenario D: Governance enables `isolated` on a live eMode with existing users

Users are in eMode 1 (not isolated) with both WETH and LINK as collateral. Governance calls `setEModeCategory(1, ..., isolated: true)`.

- LINK's LTV drops to 0 immediately for all users in eMode 1.
- Health factor is unaffected (liquidation threshold is not changed).
- Users cannot take new borrows backed by LINK collateral.
- Users must withdraw/disable LINK collateral before the LTV-zero collateral (the protocol enforces withdrawing LTV-zero assets first via `validateHFAndLtvzero`).
- Alternatively, users can exit eMode to restore LINK's base LTV.

### Migration strategy

To convert an existing eMode that uses manual `ltvzeroBitmap` management to the `isolated` flag:

1. Enable `isolated` on the eMode via `setEModeCategory` (or config engine update).
2. Clear `ltvzeroBitmap` entries that are now redundant (optional but recommended for clarity). Assets outside the `collateralBitmap` already get LTV=0 from the `isolated` flag.
3. Keep `ltvzeroBitmap` entries for any assets that are inside `collateralBitmap` but should still be LTV-zero (e.g., a temporary freeze of one asset within the eMode). The `ltvzeroBitmap` check takes precedence for assets in `collateralBitmap`.
4. Going forward, new asset listings no longer require corresponding `ltvzeroBitmap` updates for isolated eModes, unless the admin wants to partially LTV0, while allowing some non e-Modes assets to be cross-margin.

### UI Integration

`UiPoolDataProviderV3.getEModes()` returns the `isolated` field in the `EModeCategory` struct for each eMode entry. The field is fetched via `pool.getIsEModeCategoryIsolated(i)` with a try/catch to maintain backwards compatibility with pre-v3.7 pools (defaulting to `false`).

Frontend integrations should:

1. Read the `isolated` field from the eMode data.
2. When `isolated=true`, warn users that only assets in the eMode's collateral list will contribute borrowing power, flagging all others similar as LTV0.
3. When displaying the effective LTV of a user's assets, check whether each asset is in the eMode's `collateralBitmap`; if not and the eMode is isolated, show LTV as 0.
