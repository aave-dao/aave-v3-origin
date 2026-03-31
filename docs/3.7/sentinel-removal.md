# PriceOracleSentinel removal (Aave v3.7)

## Table of contents

- [Overview](#overview)
- [Technical Specification](#technical-specification)
- [Developer / Governance Guide](#developer--governance-guide)

---

## Overview

### What?

The `PriceOracleSentinel` and `SequencerOracle` contracts are removed entirely. These contracts were used on L2 deployments to check whether the L2 sequencer was online and enforced a grace period after recovery:

- **Borrows** were blocked while the sequencer was down or the grace period had not elapsed (`isBorrowAllowed()`).
- **Liquidations** were blocked under the same conditions (`isLiquidationAllowed()`), with a special exception: liquidations were always permitted when a position's health factor fell below `MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD` (0.95), regardless of sentinel status.

Both checks are removed. Borrows and liquidations now proceed without sequencer uptime gating.

### Why?

Historically, sequencer uptime detection on L2s has been ad-hoc -- each network has different mechanisms and reliability characteristics for reporting sequencer status. This lack of a standardized, reliable uptime signal led to infrastructure differences across deployments/chains, which led to false positives.

These false positives can, in the worst case, lead to the following problems:

- **Blocked liquidations** allowed unhealthy positions to deteriorate further, increasing protocol risk during the exact moments when liquidations were most needed.
- **Blocked borrows** prevented normal user activity during periods where price feeds were functioning correctly, creating unnecessary friction.
- **The 0.95 HF carve-out** was a workaround acknowledging that blocking liquidations is dangerous, but it only covered severely undercollateralized positions and can be problematic in high LT scenarios.

### Effects

1. **Borrows** -- No longer gated by sequencer status. Borrows succeed as long as standard validations pass (active, not frozen, not paused, sufficient collateral, within caps).

2. **Liquidations** -- No longer gated by sequencer status. Liquidations succeed whenever health factor < 1.0 and the liquidation grace period has elapsed. The `MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD` constant (0.95 HF) is removed from `ValidationLogic` as it was only needed for the sentinel bypass carve-out.

3. **Gas savings** -- Removing the sentinel check eliminates an external call to `PoolAddressesProvider.getPriceOracleSentinel()` and a potential further external call to `PriceOracleSentinel.isBorrowAllowed()` / `isLiquidationAllowed()` (which itself calls `SequencerOracle.latestRoundData()`). This saves gas on every borrow and liquidation.

---

## Technical specification

### Deleted contracts

| Contract                                            | Description                                                                                       |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `src/contracts/misc/PriceOracleSentinel.sol`        | Checked sequencer uptime + grace period; exposed `isBorrowAllowed()` and `isLiquidationAllowed()` |
| `src/contracts/oracle/SequencerOracle.sol`          | Mock/wrapper for the L2 sequencer uptime feed (`latestRoundData()`)                               |
| `src/contracts/interfaces/IPriceOracleSentinel.sol` | Interface for `PriceOracleSentinel`                                                               |
| `src/contracts/interfaces/ISequencerOracle.sol`     | Interface for `SequencerOracle`                                                                   |

### Validation logic changes

**`ValidationLogic.validateBorrow`** -- Removed the sentinel check:

```diff
- require(
-   params.priceOracleSentinel == address(0) ||
-     IPriceOracleSentinel(params.priceOracleSentinel).isBorrowAllowed(),
-   Errors.PriceOracleSentinelCheckFailed()
- );
```

**`ValidationLogic.validateLiquidationCall`** -- Removed the sentinel check (which had a special bypass for HF < 0.95):

```diff
- require(
-   params.priceOracleSentinel == address(0) ||
-     params.healthFactor < MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
-     IPriceOracleSentinel(params.priceOracleSentinel).isLiquidationAllowed(),
-   Errors.PriceOracleSentinelCheckFailed()
- );
```

### Parameter removal

The `priceOracleSentinel` address was threaded through several structs and call sites. All references are removed:

| Struct                                    | Removed Field                 |
| ----------------------------------------- | ----------------------------- |
| `DataTypes.ExecuteBorrowParams`           | `address priceOracleSentinel` |
| `DataTypes.ExecuteLiquidationCallParams`  | `address priceOracleSentinel` |
| `DataTypes.ValidateBorrowParams`          | `address priceOracleSentinel` |
| `DataTypes.ValidateLiquidationCallParams` | `address priceOracleSentinel` |

**`Pool.sol`** no longer calls `ADDRESSES_PROVIDER.getPriceOracleSentinel()` in `borrow()` or `liquidationCall()`.

### PoolAddressesProvider

As the pool is not upgradable, the sentinel was kept to keep the codebase between deployments consistent.

### Helper Changes

**`LiquidationDataProvider._canLiquidateThisHealthFactor`** -- Simplified from a `view` function (that read the sentinel from `ADDRESSES_PROVIDER`) to a `pure` function:

```diff
- function _canLiquidateThisHealthFactor(uint256 healthFactor) private view returns (bool) {
-   address priceOracleSentinel = ADDRESSES_PROVIDER.getPriceOracleSentinel();
-   if (healthFactor >= ValidationLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD) {
-     return false;
-   }
-   if (
-     priceOracleSentinel != address(0) &&
-     healthFactor >= ValidationLogic.MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD &&
-     !IPriceOracleSentinel(priceOracleSentinel).isLiquidationAllowed()
-   ) {
-     return false;
-   }
-   return true;
- }

+ function _canLiquidateThisHealthFactor(uint256 healthFactor) private pure returns (bool) {
+   return healthFactor < ValidationLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
+ }
```

### Removed Error

| Error                                   | Description                                                |
| --------------------------------------- | ---------------------------------------------------------- |
| `Errors.PriceOracleSentinelCheckFailed` | Was reverted when sentinel blocked a borrow or liquidation |

### Changelog

| File                                                          | Change                                                                                                                                                  |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/contracts/misc/PriceOracleSentinel.sol`                  | Deleted                                                                                                                                                 |
| `src/contracts/oracle/SequencerOracle.sol`                    | Deleted                                                                                                                                                 |
| `src/contracts/interfaces/IPriceOracleSentinel.sol`           | Deleted                                                                                                                                                 |
| `src/contracts/interfaces/ISequencerOracle.sol`               | Deleted                                                                                                                                                 |
| `src/contracts/protocol/libraries/logic/ValidationLogic.sol`  | Removed sentinel checks in `validateBorrow` and `validateLiquidationCall`; removed `IPriceOracleSentinel` import                                        |
| `src/contracts/protocol/libraries/logic/BorrowLogic.sol`      | Removed `priceOracleSentinel` from `ValidateBorrowParams` construction                                                                                  |
| `src/contracts/protocol/libraries/logic/LiquidationLogic.sol` | Removed `priceOracleSentinel` from `ValidateLiquidationCallParams` construction                                                                         |
| `src/contracts/protocol/libraries/types/DataTypes.sol`        | Removed `priceOracleSentinel` field from `ExecuteBorrowParams`, `ExecuteLiquidationCallParams`, `ValidateBorrowParams`, `ValidateLiquidationCallParams` |
| `src/contracts/protocol/libraries/helpers/Errors.sol`         | Removed `PriceOracleSentinelCheckFailed`                                                                                                                |
| `src/contracts/protocol/pool/Pool.sol`                        | Removed `ADDRESSES_PROVIDER.getPriceOracleSentinel()` calls in `borrow()` and `liquidationCall()`                                                       |
| `src/contracts/helpers/LiquidationDataProvider.sol`           | Simplified `_canLiquidateThisHealthFactor` to pure function; removed `IPriceOracleSentinel` import                                                      |

### Compatibility

| Area                                   | Before (v3.6)                              | After (v3.7)        |
| -------------------------------------- | ------------------------------------------ | ------------------- |
| `PriceOracleSentinelUpdated` event     | Emitted on sentinel change                 | Removed             |
| `PriceOracleSentinelCheckFailed` error | Reverted on blocked borrow/liquidation     | Removed             |
| Borrow validation                      | Checks sentinel if configured              | No sentinel check   |
| Liquidation validation                 | Checks sentinel (bypass at HF < 0.95)      | No sentinel check   |
| `LiquidationDataProvider`              | Reads sentinel for liquidation eligibility | Pure HF < 1.0 check |

---

## Migration

The `PRICE_ORACLE_SENTINEL` key in `PoolAddressesProvider` is stored in a simple mapping. After the upgrade, the getter and setter are removed from the interface, but the stored address remains inert in storage -- it is never read. No explicit cleanup is required, though governance may choose to call `setPriceOracleSentinel(address(0))` on the old implementation before upgrading for clarity.

### Integrator Notes

- **Off-chain liquidation bots**: Remove any `isLiquidationAllowed()` pre-checks before calling `liquidationCall()`. Liquidations are now gated only by health factor and liquidation grace period.
- **Off-chain borrow integrations**: Remove any `isBorrowAllowed()` pre-checks. Borrows are now gated only by standard reserve and user validations.
- **Frontends**: Remove any UI warnings related to sequencer uptime or sentinel status. The `getPriceOracleSentinel()` getter no longer exists on the new interface.
- **Subgraphs/Indexers**: Remove handlers for the `PriceOracleSentinelUpdated` event.
