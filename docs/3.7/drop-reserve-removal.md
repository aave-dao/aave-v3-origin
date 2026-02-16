# Aave v3.7: `dropReserve` removal

## What?

Aave v3.7 removes the `dropReserve` functionality from the Pool and PoolConfigurator contracts. This includes:

### Removed functions

**From IPool:**

- `dropReserve(address asset)`

**From IPoolConfigurator:**

- `dropReserve(address asset)`

### Removed validation

**From ValidationLogic:**

- `validateDropReserve(mapping, DataTypes.ReserveData, address)` -- validated that supply, debt, and accrued treasury were all zero before allowing a reserve to be dropped

### Removed errors

- `UnderlyingClaimableRightsNotZero` -- checked that aToken supply and accruedToTreasury were zero
- `VariableDebtSupplyNotZero` -- checked that variable debt supply was zero

### Removed event

- `ReserveDropped(address asset)`

## Why?

### Conditions are never met in practice

The `dropReserve` function required that a reserve had:

1. Zero variable debt supply
2. Zero aToken supply
3. Zero accrued treasury fees

In practice, these conditions are never simultaneously met on a live deployment.
Once a reserve is listed and has seen any activity, dust is transferred to the `DustBin`, where it cannot be easily retrieved.

### Ecosystem dependencies on reserve IDs

Even if the conditions were met, dropping a reserve would be dangerous. The Aave ecosystem has numerous external contracts and integrations that rely on hardcoded reserve IDs:

- eMode bitmaps (`collateralBitmap`, `borrowableBitmap`, `ltvzeroBitmap`) reference reserves by their numeric ID
- `UserConfiguration` bitmaps encode supply/borrow state per reserve ID -- there have been bugs in the past where ids were flags were not correctly removed, which could lead to problems
- Off-chain indexers and subgraphs track reserves by ID
- External protocols and aggregators may cache or hardcode reserve IDs

Dropping a reserve frees its ID slot in the `_reservesList` mapping, which means a subsequently listed reserve could reuse the same ID. This would silently break any integration that assumed a given ID always maps to the same asset. The previous `dropReserve` implementation even acknowledged this risk in its NatSpec: _"Does not reset eMode flags, which must be considered when reusing the same reserve id for a different reserve."_

### Signaling intent

Rather than keeping dead code that could be accidentally or incorrectly invoked, removing `dropReserve` explicitly signals that this feature will not be used without a thorough prior analysis of ecosystem impact and a purpose-built migration plan.

## Effects

### No impact on existing deployments

- No reserve has ever been dropped on any production Aave v3 deployment. The feature removal is purely preventive
- Reducing the attack surface and maintenance burden.
