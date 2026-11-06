# Aave v3.8 Changelog

v3.8 is a surgical upgrade focused on defense in depth. It adds a transient reentrancy guard across the Pool. No features are added or removed and no function signatures change. The storage layout is untouched, the guard keeps its flag in transient storage.

## Core Contracts

### Pool

- Added a transient reentrancy guard (`nonReentrant`) on state-changing entry points as defense in depth.
- `flashLoan` and `flashLoanSimple` check the guard without taking it, so actions remain reachable from inside a flashloan callback.
- `rescueTokens` checks the guard without taking it, because rescuing aTokens held by the Pool calls `aToken.transfer`, which enters the guarded `finalizeTransfer`.
- `eliminateReserveDeficit` is guarded, with the check ahead of `onlyUmbrella`.
- `PoolInstance`: `POOL_REVISION` bumped from 11 to 12.

## Build

- `evm_version` moves from `shanghai` to `cancun`, required for `TSTORE`. This applies to the whole repository, so contracts outside the Pool compile to different bytecode even where their source is unchanged. Chains without Cancun cannot run v3.8.
