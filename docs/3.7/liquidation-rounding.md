# Liquidation rounding improvements

## Motivation

Prior to this change, three computations inside `_calculateAvailableCollateralToLiquidate` used half-up rounding (`percentMul`, `percentDiv`). Half-up rounding is non-deterministic in which party it favors: depending on the remainder, it rounds toward the liquidator or toward the protocol. A sophisticated liquidator can choose a precise `debtToCover` value to systematically land the rounding in their favor across all three sites.

The fix replaces all three with explicit floor/ceil variants so that rounding is deterministic and never exploitable by the liquidator.

---

## Change 1: `maxCollateralToLiquidate`

The total collateral seized from the borrower for a given debt amount (before splitting into liquidator share + protocol fee).

```diff
- vars.maxCollateralToLiquidate = vars.baseCollateral.percentMul(liquidationBonus);
+ vars.maxCollateralToLiquidate = vars.baseCollateral.percentMulFloor(liquidationBonus);
```

**Rationale:** This is the total collateral removed from the borrower's position. Floor rounding means the borrower loses at most the exact entitled amount, never more. This is consistent with the ERC-4626 principle of rounding against the party initiating the action (the liquidator). It also marginally improves the borrower's post-liquidation health factor, reducing bad debt risk.

Note that this does not directly benefit the protocol's fee revenue — both the liquidator's share and the protocol fee are derived from this amount, so both are marginally smaller. The benefit is to the borrower's solvency.

**Effect:** Up to 1 wei less total collateral seized per liquidation; borrower retains marginally more collateral.

---

## Change 2: `bonusCollateral` (base portion via `percentDiv`)

The bonus is derived by subtracting the "base" (pre-bonus) collateral from the total collateral amount. The base is computed by dividing the collateral amount by the liquidation bonus.

```diff
  vars.bonusCollateral =
    vars.collateralAmount -
-   vars.collateralAmount.percentDiv(liquidationBonus);
+   vars.collateralAmount.percentDivFloor(liquidationBonus);
```

**Rationale:** Given a fixed `collateralAmount` (already determined by Change 1), this controls how the collateral is split between the liquidator and the protocol fee. Floor rounding on the base portion minimizes it, which maximizes `bonusCollateral`. A larger bonus means a larger protocol fee (computed in Change 3), shifting the split in favor of the protocol and against the liquidator.

**Effect:** Up to 1 wei more bonus attributed, leading to a marginally larger protocol fee at the liquidator's expense.

---

## Change 3: `liquidationProtocolFee`

The protocol's cut of the liquidation bonus.

```diff
- vars.liquidationProtocolFee = vars.bonusCollateral.percentMul(
+ vars.liquidationProtocolFee = vars.bonusCollateral.percentMulCeil(
    vars.liquidationProtocolFeePercentage
  );
```

**Rationale:** The protocol fee is revenue for the protocol. Ceil rounding ensures the protocol receives at least its entitled share; the liquidator absorbs the rounding loss.

**Effect:** Up to 1 wei more protocol fee per liquidation.

---

## Summary

| Computation                | Before                 | After             | Rounding | Benefits                                      |
| -------------------------- | ---------------------- | ----------------- | -------- | --------------------------------------------- |
| `maxCollateralToLiquidate` | `percentMul` (half-up) | `percentMulFloor` | Floor    | Borrower (retains more collateral, better HF) |
| base portion for bonus     | `percentDiv` (half-up) | `percentDivFloor` | Floor    | Protocol fee (larger bonus, larger fee)       |
| `liquidationProtocolFee`   | `percentMul` (half-up) | `percentMulCeil`  | Ceil     | Protocol fee (fee rounded up)                 |

In all three cases the liquidator is the party that absorbs the rounding loss. All other rounding in the liquidation flow was already deterministically favorable and remains unchanged.
