# Aave v3.7: Isolation Mode & Siloed Borrowing Removal

## What?

Aave v3.7 removes two risk management features that were introduced in earlier versions:

1. **Isolation Mode** - Restricted users to a single collateral asset with a debt ceiling and limited borrowable assets
2. **Siloed Borrowing** - Prevented users from borrowing multiple assets if one was marked as siloed

### Removed Functions

**From IPool:**

- `resetIsolationModeTotalDebt(address asset)`

**From IPoolConfigurator:**

- `setDebtCeiling(address asset, uint256 newDebtCeiling)`
- `setSiloedBorrowing(address asset, bool siloed)`
- `setBorrowableInIsolation(address asset, bool borrowable)`

**From Configuration Libraries:**

- `ReserveConfiguration.setDebtCeiling()` / `getDebtCeiling()`
- `ReserveConfiguration.setBorrowableInIsolation()` / `getBorrowableInIsolation()`
- `ReserveConfiguration.setSiloedBorrowing()` / `getSiloedBorrowing()`
- `UserConfiguration.getIsolationModeState()`
- `UserConfiguration.getSiloedBorrowingState()`

**Removed Events:**

- `IsolationModeTotalDebtUpdated`
- `DebtCeilingChanged`
- `SiloedBorrowingChanged`
- `BorrowableInIsolationChanged`

**Removed Errors:**

- `DebtCeilingExceeded`
- `InvalidDebtCeiling`
- `DebtCeilingNotZero`
- `AssetNotBorrowableInIsolation`
- `SiloedBorrowingViolation`

**Renamed Errors:**

- `UserInIsolationModeOrLtvZero` → `UserHasAssetWithZeroLtv`

**Removed Library:**

- `IsolationModeLogic.sol` (entire library deleted)

### Config Engine Changes

Removed fields from structs:

- `Listing`: `borrowableInIsolation`, `withSiloedBorrowing`, `debtCeiling`
- `CollateralUpdate`: `debtCeiling`
- `BorrowUpdate`: `borrowableInIsolation`, `withSiloedBorrowing`

## Why?

### Limited Adoption

Both features saw minimal usage:

- **Siloed Borrowing**: Never actively used in production
- **Isolation Mode**: Very few assets configured with debt ceilings

### Superseded by v3.6 Improvements

The v3.6 upgrade introduced more flexible alternatives:

**Borrow Isolation (Siloed Borrowing) → Specialized eModes:**

- eModes in v3.6 can restrict which assets are borrowable within a specific efficiency mode
- More flexible than siloed borrowing as it allows controlled multi-asset borrowing
- Better composability with existing risk parameters

**Collateral Isolation → Specialized eModes with eMode-specific LTV0:**

- v3.6 introduced eMode-specific `ltv0` rules via `ltvZeroBitmap`
- Can make an asset collateral _only_ within a specific eMode
- Can apply `ltv0` rules (withdrawal ordering, no collateral enabling) selectively
- Debt exposure can be managed via supply/borrow caps per asset

### Reduced Complexity

- Removal of ~600 lines of code from src/
- Simplified validation logic in borrow, repay, supply, and liquidation flows
- Reduced attack surface
- Easier to audit and maintain

### Gas Savings

Measurable gas improvements across all operations:

- Borrow: ~1,200-2,300 gas saved
- Repay: ~3,200-7,200 gas saved
- Supply (first): ~5,500 gas saved
- `getReserveData`: ~2,100 gas saved

## Effects

### Minimal Impact

**Isolation Mode (Debt Ceiling):**

- All assets that previously had debt ceilings are already `ltv = 0`
- No active isolated positions exist in production deployments
- The `isolationModeTotalDebt` tracking was unused
- **Effect**: None - feature was already effectively disabled

**Siloed Borrowing:**

- Never enabled on any production asset
- No active siloed borrow positions exist
- **Effect**: None - feature was never used

### Breaking Changes for Integrators

Non of this is **breaking** as DataProviders still provide the old disabled values.

**Frontends:**

- Remove UI elements showing isolation mode status
- Remove warnings about siloed borrowing
- `getReserveData().isolationModeTotalDebt` now returns `0`
- `getSiloedBorrowing()` now returns `false`

**Indexers/Subgraphs:**

- Remove handlers for deleted events
- Deprecate isolation mode fields in schema

### Storage Compatibility

Storage layout preserved for upgrade safety:

- Bit 61 (borrowableInIsolation): Marked unused
- Bit 62 (siloedBorrowing): Marked unused
- Bits 212-251 (debtCeiling): Marked unused
- `isolationModeTotalDebt`: Marked deprecated

This ensures seamless upgrades from v3.6 to v3.7.

## Migration

### Upgrade Process

1. **Clean Up Configurations:**

   ```solidity
   // For any reserve with debt ceiling or siloed borrowing (if any):
   poolConfigurator.setDebtCeiling(asset, 0);
   poolConfigurator.setSiloedBorrowing(asset, false);
   poolConfigurator.setBorrowableInIsolation(asset, false);
   ```

---

## Summary

**What's Removed:** Isolation mode (debt ceilings, collateral restrictions) and siloed borrowing (exclusive borrowing restrictions)

**Why:** Superseded by v3.6 specialized eModes; never actively used; reduces complexity and gas costs

**Impact:** None for users (features unused / removed gracefully);
