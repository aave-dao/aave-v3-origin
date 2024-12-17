# Aave v3.3 features properties

Formal properties in natural language of the 3.3 features.

## Properties

### 1. Deficit Management

- The deficit of all reserves should initially be zero, even if bad debt was created before the protocol upgrade.
- Deficits are tracked within the `reserve.deficit` and accumulate over the curse of multiple deficit creations.
- Deficits can only be reduced by burning a claim, and thus reducing the protocols obligations in `reserve.deficit`.
- The burning of claims can be performed via `pool.eliminateReserveDeficit()`. In case of assets having virtual accounting enabled, aTokens will be burned. In case of virtual accounting being disabled, the underlying will be disposed of.
- The burning of claims can only be performed by a permissioned `UMBRELLA` entity registered on the `PoolAddressesProvider`.
- The `pool.eliminateReserveDeficit()` requires for the `UMBRELLA` entity to never have any debt.
- claims can only be burned trough `pool.eliminateReserveDeficit()` up to the current obligations stored in `reserve.deficit`.
- A deficit should be created as the result of a liquidation. A liquidation only creates a deficit if the users total collateral across all reserves being zero in the base currency, while the total debt across all reserves remains non-zero in the base currency as the result of the liquidation.
- Edge case: when liquidating yourself with `receiveAToken=true`, it is possible that bad debt is created although after the liquidation the user will end up with the liquidated, non-zero collateral.
- Whenever a deficit is created as a result of a liquidation, the user's excess debt should be burned and accounted for as deficit.
- Deficit added during the liquidation can't be more than the user's debt
- Deficit can only be created and eliminated for an `active` reserve.
- Edge case: deficit can be created and eliminated even is a reserve is `paused` in case it is not the main liquidated asset. Both actions don't affect a user negatively, and preventing the burning of bad debt on paused reserves could create overhead for the protocol.
- For the interest rate calculation, deficit is treated equally as the unbacked parameter, given that it should be reducing utilisation.

### 2. Liquidation mechanics

- A liquidation can only be performed once a users health-factor drops below 1.
- A maximum of `totalUserDebt * CLOSE_FACTOR` can be liquidated in a single liquidation, while the upper bound is further restrained by the available collateral, liquidationBonus and protocolFee.
- The **default** `CLOSE_FACTOR` is defined as `DEFAULT_LIQUIDATION_CLOSE_FACTOR` and limits the liquidation to 50% of the users todal debt.
- When liquidating a position, the liquidation must either:
  - liquidate a full debt position **or**
  - liquidate a full collateral position **or**
  - leave at least a value of `MIN_LEFTOVER_BASE` on both collateral and debt side
  - Edge case: when liquidating yourself with `receiveAToken=true`, it is possible that a position <`MIN_LEFTOVER_BASE` is created as a result of a liquidation.

There are certain mutually inclusive conditions which increases the `CLOSE_FACTOR` to 100%:

- when a users health-factor drops `<=0.95` **or**
- if the users total value of the debt position to be liquidated is below `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD`
- if the users total value of the collateral position to be liquidated is below `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD`
