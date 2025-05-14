## Aave v3.4 features

Aave v3.4 is an upgrade to be applied on top of Aave 3.3.
The focus on this release is on **UX improvements** and **code simplification** while at the same time preparing the protocol for an upcoming 3.5 that is already well in progress.

## Features

### GHO alignment

The Aave-GHO integration currently relies on various special cases, which make reasoning about the protocol harder than it should be.
This special cases range from inconsistencies in balance handling, different management of debt accrual, the inability to flashloan to the discount model applied on top.

With the introduction of [Umbrella](https://governance.aave.com/t/bgd-aave-safety-module-umbrella/18366) and the [`GHODirectMinter`](https://github.com/bgd-labs/GHODirectMinter) it is time to deprecate the current implementation and to align it with the rest of the protocol.

**aGHO**

`aGHO` on the current Aave Core instance is a special implementation that has very little in common with other `aTokens`. Its main purpose is to trigger various hooks on actions.
These inconsistencies materialize in a different utilization model, the inability to flashloan GHO and other minor quirks.

**vGHO**

`vGHO` while working similar to a usual `vToken` also has some special mechanics which lead to complications and have been the source of various bugs. In contrast to usual `vTokens` the debt does not accrue as interest on the `aToken` (as `aToken` `totalSupply` is always `0`), but instead accrues only on the `vToken` and is collected on repayment. This is done in order to support the discount model, but when analyzing onchain data, it became apparent that only a very small userbase ever made use of the GHO discount. Therefore, we think it is rational to drop it.

If a discount model is still desired, it could still be achieved on top via rewards.
One option could be to use Merkle (e.g. via merit) if the goal is to only reward GHO borrowers.
Another option could be to simply distribute GHO rewards to all stkAAVE users.

---

Therefore, what we propose is to align GHO on core with GHO on prime.
In practice that means that GHO will work exactly as every other ERC20 listed on Aave, with the caveat that the supply is directly minted to the protocol.
Opposed to GHO on prime:

- The IR should be static (as it currently is)
- The supply cap should be set, so that no user can supply GHO

With this alignment, various complexities and special cases from the protocol are permanently removed:

- All reserves will have virtual accounting enabled
- Burning bad debt no longer relies on special logic that discounts protocol fee in some special cases
- GHO flashloans are enabled, eliminating the need for custom adapters, and in most cases making the flash-mint obsolete
- Debt now directly accrues to the treasury as `aTokens`, not only on repayment improving the treasury accounting
- `balanceOf(user) == scaledBalanceOf(user) / normalizedDebt` (like on every other reserve)
- Umbrella does no longer need special handling for GHO

This alignment comes with a huge reduction in code complexity, and gas consumption, paving the way for faster and less complicated iteration on the protocol & integrations.

### Multicall

Being able to batch multiple transactions has been a frequently requested feature on the aave protocol.
This functionality can greatly improve ux as it allows users to e.g. supply & enable an eMode & borrow in a single transaction.
In addition to that being able to permit a separate entity to execute transactions on my behalf opens new use-cases & the possibility of transaction subsidies.
Therefore Aave v3.4 ships with multicall support.

### Position manager

When talking to various integrators after the release of Aave v3.2 it became apparent that one important ux feature that is currently missing is the ability for contracts to:

- enable/disable a collateral
- enter/switch an eMode

on behalf of a user. Therefore Aave 3.4 introduces the concept of "positionManagers" - addresses that can perform `setUserUseReserveAsCollateralOnBehalfOf & setUserEModeOnBehalfOf` once given approval by a user.
The user can give & revoke an approval by calling `approvePositionManager(address manager, bool approve)`. A position manager can renounce the role by calling `renouncePositionManagerRole(address user)`. All methods are noops in case the current state is already the desired state.

### Removal of "unbacked"

Unbacked supply was part of a feature called `Portals` on the original aave-v3 release post.
Eventually the feature was never used, but occupies an important amount of contract size while also costing gas on most transactions.
Therefore, in this version of the protocol we decided to drop the feature to make room for other improvements.

The feature might be added back in a future iteration if a use-case emerges and/or code-size becomes less of a concern(e.g. via Fusaka/eof).

### Immutable Interest Strategy on Pool implementation

While all reserves **already** share the same `interestRateStrategy`, in Aave v3.3 the strategy was defined per reserve which led to one unnecessary sload per touched reserve(s).
Therefore, in Aave v3.4 one immutable variable `RESERVE_INTEREST_RATE_STRATEGY` was added to the `Pool` contract. It will be used as an IR address for each reserve in Aave v3.4.
This variable will be set in the constructor of the implementation contract.

### Immutable rewardsController on AToken / VariableDebtToken implementation

While all reserves **already** share the same `incentivesController`, in Aave v3.3 the `incentivesController` was defined in a state per token, which leads to unnecessary `sloads` per touched reserve(s).
Therefore, in Aave v3.4 one immutable variable `REWARDS_CONTROLLER` was introduced on the `IncentivizedERC20` base class.
This variable will be set in the constructor of the implementation contract.

### Immutable Pool on ProtocolDataProvider

A new immutable variable `POOL` was added at the `AaveProtocolDataProvider` contract. All external calls to `ADDRESSES_PROVIDER.getPool()` were replaced with an access to the immutable variable.
This results in meaningful gas savings across the board.

### Immutable Treasury on aToken

Currently, the treasury on each `aToken` is stored in storage, although it is the same for each `aToken` - even across pools.
This causes unnecessary storage reads on liquidations and `mintToTreasury`.
Therefore, in Aave 3.4 the treasury was moved to an immutable, which reduces gas cost on these methods.

### Errors

Aave has historically used `error codes` opposed to `Error` signatures, because there was a preference for `require(cond, error)` which did not support signatures.
As on Aave v3.4 the codebase was upgraded to solc 8.27, `require(cond, Error())` is now supported.
This greatly improves UX, as explorers and simulations now show helpful errors opposed to cryptic numeric Error codes.
At the same time, the change results in minor gas & codesize savings across the board.

While this change could be **breaking** for anyone relying on exact error codes, it is important to note that:

- Every single Aave release since v3.0 had breaking changes in regards to error emission (either due to new Errors or the order of Errors)
- We checked all the major integrations and did not find a single example of people relying on exact error codes

### Token Storage & implementation alignment

Currently there are 3 different versions of the `aToken` deployed:

- the main one you can find on this repository
- a [custom version](https://etherscan.io/address/0xF6D2224916DDFbbab6e6bd0D1B7034f4Ae0CaB18) for UNI token voting delegation
- a custom one for aAAVE that can be found [here](https://github.com/bgd-labs/aave-a-token-with-delegation)

In the previous version the [implementation](https://etherscan.io/address/0x21714092d90c7265f52fdfdae068ec11a23c6248) of [UNI aToken](https://etherscan.io/address/0xF6D2224916DDFbbab6e6bd0D1B7034f4Ae0CaB18) has a function `delegateUnderlyingTo` for the `Pool` admin that allows to delegate voting power of `aToken` suppliers to some delegatee. Delegating the suppliers UNI token to the AAVE DAO or similar is debatable and the feature has never been used. Therefore in Aave 3.4 the implementation will be changed to a default one and the function will be removed.

In order to remove code complexity between aAAVE and other `aTokens`, the storage layout between the versions was aligned.
In practice this means that on `ScaledBalanceTokenBase` the `.balance` storage was changed from 128 to 120 bits. For Aave this storage change is perfectly fine given the following rational:

- the protocol works with `uint256` and has no assumptions about the token storage **already**
- the `uint120` storage was audited for the case of AAVE, but the same artificial limitation can be applied for all tokens given that `2^120 ~= 10^36`, still accepts values that exceed what could ever be required
- the "freed" `8` bits are at the end of the current balance and always `0` (except for aAAve where the occupy delegation related storage)
- the storage is not directly exposed on the token (no interface change)

The implementation for aAAVE was upgraded in line with the other tokens: [ATokenWithDelegation diff](./appendix/ATokenWithDelegation.diff), [BaseDelegation diff](./appendix/BaseDelegation.diff).

### Misc improvements

- Gas usage of `executeUseReserveAsCollateral` was greatly reduced by optimizing storage access
- Gas usage improved by shuffling `virtualUnderlyingBalance` into the position of pre 3.4 `unbacked`
- Minor codestyle improvements on `executeRepay`
- Usage of imported events from the interface contracts instead of redeclarations
- Skip unnecessary calculations on a subset of transfers
- Self-liquidation is now forbidden. While this is a breaking change, it's unlikely to affect anyone, as there are essentially no onchain traces of people relying on this functionality.
- `SafeCast` was upgraded from openzeppelin v4 to v5. The main difference is the usage of error signatures, reducing the codesize of various contracts.
- `VersionedInitializable` now bricks the initializer on the implementation, so implementations no longer have to be initialized in order to prevent malicious initialization.
- Now all fees from flash-loans are sent to the `RESERVE_TREASURY_ADDRESS` in the form of the underlying token. Also, the function `FLASHLOAN_PREMIUM_TO_PROTOCOL` in the `Pool` contract now always returns `100_00` value.
- Improved the accuracy and gas consumption of the `calculateCompoundedInterest` function without changing the formula. Inside calculations of the `second_term` and `third_term` variables now at first the function performs multiplications by `exp` and then divides by `SECONDS_PER_YEAR`. Previously it was the other way around, first there was division, then multiplication.
- Replaced the use of the `ecrecover` function call with the OpenZeppelin's `ECDSA.recover` function call.

## Changelog

Solc was upgraded from `8.20` to `8.27`

- `Pool` contract:
  - Now has the second argument `IReserveInterestRateStrategy interestRateStrategy` in the constructor. It is a default IR contract that will be used for each reserve in the system.
  - Function `getReserveData` now doesn't read the `interestRateStrategyAddress` field from the `ReserveData` structure from the storage, now it reads the `RESERVE_INTEREST_RATE_STRATEGY` immutable variable.
  - Function `initReserve` that is called by the `PoolConfigurator` contract in the process of a new reserve token initialization:
    - Removed input argument `address interestRateStrategyAddress` because each reserve has the same IR contract
  - Removed the setter function `setReserveInterestRateStrategyAddress`. There is no need in this function from now on.
  - Removed `mintUnbacked`, `backUnbacked` and `getBridgeLogic`
  - Implements openzeppelin `Multicall, ERC2771Context`
  - The function `FLASHLOAN_PREMIUM_TO_PROTOCOL` now always returns `100_00` value.
  - The function `updateFlashloanPremiums` is renamed to the `updateFlashloanPremium` function and now accepts only one argument - only total flash-loan premium.
- `PoolInstance` contract:
  - Changed the `POOL_REVISION` public constant value from `6` to `7`.
- `AaveProtocolDataProvider` contract:
  - Made some minor gas optimizations in the `getInterestRateStrategyAddress` function.
  - `getIsVirtualAccActive` is deprecated and always returns true.
  - Added a new immutable variable `POOL` into the contract and in the `IPoolDataProvider` interface too
- `ReserveLogic` library:
  - In the function `updateInterestRatesAndVirtualBalance` the variable `interestRateStrategyAddress` is now read from the `RESERVE_INTEREST_RATE_STRATEGY` immutable variable instead of the storage.
- `ConfiguratorLogic` library:
  - Function `executeInitReserve` that is called inside of the `PoolConfigurator` contract in the process of a new reserve token initialization:
    - The variable `interestRateStrategyAddress` now is taken from return values of the `initReserve` function in the `Pool` contract. Previously it was taken from the `InitReserveInput` structure that was passed by a caller, but now this structure doesn't have this field (this structure was changed too).
- `PoolConfigurator` contract:
  - Function `setReserveInterestRateStrategyAddress` was deleted because now every reserve in the system has the same IR contract.
  - Function `initReserves` that accepts an array of `InitReserveInput` structs, no longer has a `interestRateStrategyAddress` field.
  - Removed `setUnbackedMintCap` as unbacked is no longer a thing.
- `ReserveDataLegacy` and `ReserveData` structures:
  - Field `interestRateStrategyAddress` is new deprecated.
- `InitReserveInput` structure:
  - Removed the `interestRateStrategyAddress` field because each reserve in the system has the same IR contract.
- `AToken` & `VariableDebtToken`:
  - The `IncentivizedERC20` token base now exposes a new `REWARDS_CONTROLLER`, while also maintaining `getIncentivesController` for backwards compatibility.
  - `setIncentivesController` was removed as the incentives controller is no longer mutable,
  - The initialize no longer accepts a `incentivesController`, but the constructor now accepts a `rewardsController`
  - `handleRepayment` was removed as it was only required for GHO and is now a noop
  - The `aToken` receives a public `TREASURY` immutable
  - The initialize no longer accepts a `treasury`
- `LiquidationLogic` contract:
  - rename "user" was renamed to "borrower", to increase the precision on the wording.
  - [BREAKING]: self-liquidation is no longer allowed
- `PoolLogic` contract:
  - The `PoolLogic` contract was extended with two methods `executeSyncIndexesState` & `executeSyncRatesState`, which simply replicate what was previously on the Pool itself. This is done to free some code-space on the pool itself.
- `FlashLoanLogic` library:
  - Now all fees from flash-loans are sent to the `RESERVE_TREASURY_ADDRESS`.
- `MathUtils` library:
  - The `calculateCompoundedInterest` function was improved to be more accurate and gas efficient without changing the formula.

## Migration path

For users of the protocol, **no migration is needed**.
As the protocol upgrade path is slightly more complicated than in previous upgrades, this section describes the upgrade path for various of the introduced features.

### Protocol

#### GHO migration

As the current `aGHO` acts as both the `aToken` and the GHO facilitator, the migration can be perceived as two-step process: 1) the migration of the facilitator 2) the alignment of behavior.

In practice, the following steps will be performed on the proposal:

1. Calling `aToken.distributeFeesToTreasury()` to distribute pending fees to the treasury.
2. The GHO `aToken` instance is updated with a custom implementation that offers a `resolveFacilitator(uint256 amount)` function that allows burning `GHO`.
3. A new [`GHODirectMinter`](https://github.com/bgd-labs/GHODirectMinter) is registered as a facilitator(NF) with the same `capacity` as the existing `aToken facilitator`(AF).
4. The NF, does mint the current `aToken facilitator level` and supply it as `aTokens` on the Pool.
5. `resolveFacilitator` is called, burning `level` amount of `GHO`
6. With the GHO being burned, the `level` of AF is reduced to `0`, so it can now be safely removed via `GHO.removeFacilitator`
7. The `pool`, `configurator`, `aToken` and `vToken` are now being updated to v3.4, which will result in `virtualAccounting` being enabled for GHO.
8. Now the `reserveFactor` is increased from `0%` to `100%` and the `supplyCap` is set to `1`
9. `vGHO` is upgraded to align with the default implementation + an `updateDiscountDistribution` noop.

_Note: The cap limitation is in place to prevent users from accidentally supplying GHO(as it is no collateral and there is a `100%` reserve factor, it would never be intentional)._
_Note: The GHO vToken, while being `100%` compatible with the default implementation, will contain an `updateDiscountDistribution` noop so that there are no issues with the stkAAVE transfer hook._
_Note: The pending discount for users will be lost on the upgrade. Therefore we recommend for a DAO related service (e.g. Dolce Vita) to iterate all discounted GHO borrowers and repay `1` wei of GHO on behalf to apply the discount one last time, slightly before proposal execution._
_Note: **Umbrella** can be simplified as there no longer is a special path for coverage with assets that don't have `virtualAccounting` enabled._

#### Emit deprecated events

The `PoolConfigurator` contract should emit the `FlashloanPremiumToProtocolUpdated` event in the migration. This event was deprecated, now the `FLASHLOAN_PREMIUM_TO_PROTOCOL` function always returns `100_00` value. The emit should contain these values:

- `oldFlashloanPremiumToProtocol`: the old value of the `FLASHLOAN_PREMIUM_TO_PROTOCOL` function.
- `newFlashloanPremiumToProtocol`: value `100_00`.

#### Virtual accounting

As virtual accounting is now always active, fetching `getIsVirtualAccActive` is becoming obsolete.
That said, upon investigating existing contracts we noticed that there are various instances of people hard-coding the `PoolDataProvider` or directly decoding `configuration.getIsVirtualAccActive`.
To maintain compatibility with these contracts, the boolean flag will be carried in the configuration for the upcoming version(s).

#### Storage optimization

As the storage slot of `virtualUnderlyingBalance` was moved, the Pool initializer will copy the value from the deprecated `__deprecatedVirtualUnderlyingBalance` slot to the new `virtualUnderlyingBalance` slot.

There are no user-facing changes related to this change.

#### Misc

In addition to the points mentioned above, the upgrade should upgrade

- all logic libraries as the InterestRate is now passed as a parameter instead of being fetched from storage.
- all tokens, due to changes from storage to immutables
- the pool configurator, to account for the changed signatures
- the config engine, as the signature of token initialization changed

### Integrators

#### GHO FlashMinter

The `GHO FlashMinter` is not affected by the upgrade.
That said, for contracts that rely on flashloans, GHO no longer needs to be handled as a special case - GHO can be flashloaned as any other asset. This makes contracts like the custom `GHO Debt Swap` obsolete.

#### PositionManager

When currently supplying(via transfer of supply) `aToken` to a user they **might** enable as collateral.
There are certain scenarios in which they don't. For a future version 3.5 we are considering changing this behavior, therefore we recommend migrating to the more explicit positionManager/multicall approach.

Instead of assuming that an asset will be enabled as collateral, for interactions on your own behalf, do `multiCall([supply, enableAsCollateral])` for interactions on behalf of another entity, use the position manager functionality (`approvePositionManager` + `supply, enableAsCollateralOnBehalf`).
