# Aave v3.7 Changelog

## Core Contracts

### Pool

- Removed `dropReserve()`. Reserve removal is no longer supported at the pool level. See [drop-reserve-removal.md](drop-reserve-removal.md).
- Removed `priceOracleSentinel` from execution parameters (`ExecuteLiquidationCallParams`, `ExecuteBorrowParams`). See [sentinel-removal.md](sentinel-removal.md).
- Removed `resetIsolationModeTotalDebt()`. The `isolationModeTotalDebt` field in `ReserveData` is deprecated and returns 0 in view functions. See [mode-removal.md](mode-removal.md).
- `liquidationCall` no longer updates isolation mode debt counters. See [mode-removal.md](mode-removal.md).
- Added `configureEModeCategoryIsolated(uint8 id, bool isolated)` and `getIsEModeCategoryIsolated(uint8 id)` for the new isolated eMode feature. See [isolated-emode.md](isolated-emode.md).
- `PoolInstance`: `POOL_REVISION` bumped from 10 to 11.

### PoolConfigurator

- Removed `dropReserve()`. See [drop-reserve-removal.md](drop-reserve-removal.md).
- Removed `setDebtCeiling()`, `setSiloedBorrowing()`, and `setBorrowableInIsolation()` — isolation mode and siloed borrowing have been removed. See [mode-removal.md](mode-removal.md).
- Removed `getConfiguratorLogic()` — `ConfiguratorLogic` is now an internal library, no longer deployed separately.
- `setEModeCategory` now takes an additional `bool isolated` parameter. Added `setEModeCategoryIsolated(uint8 categoryId, bool isolated)` for updating the flag independently.
- Config engine libraries are now inlined (no longer use `delegatecall`).
- `PoolConfiguratorInstance`: `CONFIGURATOR_REVISION` bumped from 7 to 8.

### LiquidationLogic

- **Deterministic rounding**: `percentMul`/`percentDiv` calls in `_calculateAvailableCollateralToLiquidate` now use explicit rounding direction (`percentMulFloor`, `percentDivFloor`, `percentMulCeil`, `percentDivCeil`). The close-factor computation in `executeLiquidationCall` still uses the half-up `percentMul`.
- **Improved `hasNoCollateralLeft` detection**: The check now uses scaled balance consumption (matching the actual `rayDivCeil` rounding of burn/transfer operations) instead of comparing base-currency values. This prevents stranded debt when ceil rounding depletes a position or when a few-wei leftover rounds to $0 in base currency. See [liquidation-rounding.md](liquidation-rounding.md).
- Removed the 4th return value (`collateralToLiquidateInBaseCurrency`) from `_calculateAvailableCollateralToLiquidate`.
- Removed isolation mode debt ceiling updates from the liquidation flow.
- Added `borrowerScaledCollateralBalance` to `LiquidationCallLocalVars` (single SLOAD, reused for the scaled consumption check).

### ValidationLogic

- Removed `MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD` (sentinel-related). See [sentinel-removal.md](sentinel-removal.md).
- Removed `priceOracleSentinel` parameter from `validateLiquidationCall` and `validateBorrow`. See [sentinel-removal.md](sentinel-removal.md).
- Removed `validateAutomaticUseAsCollateral`. Simplified `validateUseAsCollateral` to no longer require `reservesList` parameter.
- Removed `validateDropReserve`.
- Removed siloed borrowing validation checks from `validateBorrow`.

## Periphery

### AaveV3ConfigEngine

- Config engine libraries (`BorrowEngine`, `CapsEngine`, `CollateralEngine`, `EModeEngine`, `ListingEngine`, `PriceFeedEngine`, `RateEngine`) are now internal libraries called directly instead of via `delegatecall`. Removed `EngineLibraries` struct and per-engine address getters from `IAaveV3ConfigEngine`.
- Removed isolation mode and siloed borrowing parameters: `borrowableInIsolation`, `withSiloedBorrowing` from `Listing`/`BorrowUpdate`; `debtCeiling` from `Listing`/`CollateralUpdate`.
- Added `isolated` field to `EModeCategoryUpdate` and `EModeCategoryCreation`.

### LiquidationDataProvider

- Aligned rounding with `LiquidationLogic`: `percentMulFloor`, `percentDivFloor`, `percentMulCeil` in the same positions as the core contract.
- `debtBalanceInBaseCurrency` now uses `MathUtils.mulDivCeil` (matching `LiquidationLogic`).
- `debtLeftoverInBaseCurrency` in `_adjustAmountsForGoodLeftovers` now uses `MathUtils.mulDivCeil` (matching the dust check in `LiquidationLogic`).
- Removed sentinel-related logic from `_canLiquidateThisHealthFactor`.

### UiPoolDataProviderV3

- `isSiloedBorrowing` and `debtCeiling` / `debtCeilingDecimals` fields are now hardcoded to `false` / `0` for backward compatibility (dynamic lookups removed).
- Added `isolated` field to eMode category data.

### UiIncentiveDataProviderV3

- Fixed bug: vToken incentive user data was incorrectly using `aTokenIncentiveController` instead of `vTokenIncentiveController`.

### AaveProtocolDataProvider

- `getDebtCeiling`, `getSiloedBorrowing` now return hardcoded defaults (`0` / `false`) for backward compatibility. `getDebtCeilingDecimals` unchanged (was already pure).

## Libraries

- **IsolationModeLogic**: Deleted entirely. Isolation mode debt ceiling tracking is removed.
- **BorrowLogic**: Removed isolation mode debt ceiling updates from `executeBorrow` and `executeRepay`.
- **SupplyLogic**: Callers updated from `validateAutomaticUseAsCollateral` to `validateUseAsCollateral`. Removed `reservesList` parameter from supply/transfer validation paths.
- **PoolLogic**: Removed `executeDropReserve` and `executeResetIsolationModeTotalDebt`.
- **FlashLoanLogic**: Removed `priceOracleSentinel` from borrow params construction.
- **GenericLogic**: Added `@dev` legacy comment on `reserveAddress != address(0)` checks explaining they guard against gaps left by the removed `dropReserve` feature.
- **ReserveConfiguration**: Removed `getDebtCeiling`, `setDebtCeiling`, `DEBT_CEILING_MASK`, `DEBT_CEILING_DECIMALS`, `MAX_VALID_DEBT_CEILING`. Removed `getSiloedBorrowing`, `setSiloedBorrowing`, `SILOED_BORROWING_MASK`. Removed `getBorrowableInIsolation`, `setBorrowableInIsolation`, `BORROWABLE_IN_ISOLATION_MASK`.
- **UserConfiguration**: Removed `getIsolationModeState`, `getSiloedBorrowingState`.
- **PercentageMath**: Added `percentDivFloor` function (`percentMulFloor`, `percentMulCeil`, `percentDivCeil` already existed).
- **DataTypes**: Deprecated `debtCeiling` bits in `ReserveConfigurationMap` (getter/setter removed, bits marked `DEPRECATED`). Removed `priceOracleSentinel` from `ExecuteLiquidationCallParams`, `ExecuteBorrowParams`, `ValidateBorrowParams`, and `ValidateLiquidationCallParams`. Added `borrowerScaledCollateralBalance` to `LiquidationCallLocalVars`. Added `isolated` flag to `EModeCategory`.
- **ConfiguratorLogic**: Functions changed from `external` to `internal` (library is no longer deployed separately).
- **Errors**: Removed `DebtCeilingExceeded`, `UnderlyingClaimableRightsNotZero`, `VariableDebtSupplyNotZero`, `PriceOracleSentinelCheckFailed`, `AssetNotBorrowableInIsolation`, `InvalidDebtCeiling`, `DebtCeilingNotZero`, `SiloedBorrowingViolation`. Renamed `UserInIsolationModeOrLtvZero` → `UserHasAssetWithZeroLtv`. Added `MustNotLeaveDust`.

## Interfaces

- **IPriceOracleSentinel**: Deleted.
- **ISequencerOracle**: Deleted.
- **IPool**: Removed `dropReserve`, `resetIsolationModeTotalDebt`, `IsolationModeTotalDebtUpdated` event. Added `configureEModeCategoryIsolated`, `getIsEModeCategoryIsolated`.
- **IPoolConfigurator**: Removed `dropReserve`, `setDebtCeiling`, `setSiloedBorrowing`, `setBorrowableInIsolation`, `getConfiguratorLogic`. Removed events `ReserveDropped`, `DebtCeilingChanged`, `SiloedBorrowingChanged`, `BorrowableInIsolationChanged`. Removed dead event `BridgeProtocolFeeUpdated` (was never emitted). `setEModeCategory` now takes an additional `bool isolated` parameter. Added `setEModeCategoryIsolated` and `EModeCategoryIsolationChanged` event.
- **IPoolDataProvider**: `getDebtCeiling`, `getDebtCeilingDecimals`, `getSiloedBorrowing` deprecated via NatSpec (kept for backward compatibility, return hardcoded defaults).
- **IDefaultInterestRateStrategyV2**: NatSpec fixes (missing `@notice` prefixes, description correction).

## Mocks

- `MockPoolInherited`: Removed `dropReserve` override.
- `SequencerOracle`: Deleted.

## Deleted Contracts

- `PriceOracleSentinel`
- `SequencerOracle` (mock)
- `IsolationModeLogic`
- `IPriceOracleSentinel`
- `ISequencerOracle`

## Deployments

- `AaveV3MiscBatch` / `AaveV3MiscProcedure`: Removed `PriceOracleSentinel` deployment.
- `AaveV3SetupBatch` / `AaveV3SetupProcedure`: Removed `priceOracleSentinel` parameter from `setupAaveV3Market`.
- `AaveV3BatchOrchestration`: Removed sentinel from orchestration flow. Removed `l2SequencerUptimeFeed` and `l2PriceOracleSentinelGracePeriod` from `_deployMisc`.
- `AaveV3LibrariesBatch1`: Removed `ConfiguratorLogic` from library deployment (now inlined).
- `AaveV3HelpersProcedureOne`: Removed config engine sub-library deployments (`ListingEngine`, `EModeEngine`, `BorrowEngine`, `CollateralEngine`, `PriceFeedEngine`, `RateEngine`, `CapsEngine`) and `EngineLibraries` parameter from `AaveV3ConfigEngine` constructor.
- `IMarketReportTypes`: Removed `priceOracleSentinel` from `MarketReport`. Removed `configuratorLogic` from `LibrariesReport`. Removed `l2SequencerUptimeFeed` and `l2PriceOracleSentinelGracePeriod` from `MarketConfig`. Removed config engine sub-library addresses from `ConfigEngineReport`.
- `MetadataReporter`: Removed `priceOracleSentinel` and `configuratorLogic` from JSON report serialization.
- `FfiUtils`: Updated `_getBorrowLibraryAddress` to parse `BorrowLogic` instead of `ConfiguratorLogic` from `.env`.
