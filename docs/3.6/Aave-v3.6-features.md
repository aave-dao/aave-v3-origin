## Aave v3.6 Features

### Table of Contents

- [eMode Improvements](#emode-improvements)
- [Automatic Collateral Behavior](#automatic-collateral-behavior)
  - [Liquidate aTokens](#liquidate-atokens)
  - [Isolated Collaterals](#isolated-collaterals)
  - [aToken Transfers](#atoken-transfers)
- [Renounce Allowance](#renounce-allowance)
- [OpenZeppelin Alignment](#openzeppelin-alignment)
  - [`BorrowAllowanceDelegated` event removal in `_decreaseBorrowAllowance`](#borrowallowancedelegated-event-removal-in-_decreaseborrowallowance)
  - [`Approval` event removal in `transferFrom`](#approval-event-removal-in-transferfrom)
- [eMode Category Label (Soft Deprecation)](#emode-category-label-soft-deprecation)
- [Deprecation](#deprecation)
- [Upgrade Considerations](#upgrade-considerations)

### eMode Improvements

**Change**: In Aave v3.6, `lt`, `ltv`, and `borrowingEnabled` are now fully decoupled — the configuration for `eMode = 0` no longer affects any non-default efficiency modes (`eMode ≠ 0`).
To achieve this, the eMode configuration has been extended with an `ltvZeroBitmap` that allows enabling `ltv0 rules` for a specific asset in a specific eMode.

**Background**:
In prior versions of the Aave Protocol, the default `reserve configuration` always superseded the `eMode configuration`. In practice, this meant:

- For an asset to be collateral inside an eMode, it must be collateral outside as well.
- For an asset to be borrowable inside an eMode, it must be borrowable outside as well.
- If an asset is set to `ltv = 0` in the `reserve configuration`, it is considered as `ltv = 0` inside the eMode as well, and **ltv0 rules** apply.

**ltv0 rules**: In Aave v3, `ltv0` assets have `ltv = 0`, but in addition, some `ltv0 rules` apply:

- `ltv0` assets cannot be enabled as collateral.
- `ltv0` collateral has to be withdrawn **first**. This means that if a position consists of `ltv0` and non-`ltv0` collateral, trying to withdraw or transfer the non-`ltv0` collateral will revert.

While this approach evolved naturally from v3.0, it made certain scenarios impossible to configure:

- Making an asset exclusively borrowable in some eMode.
- Making an asset exclusively collateral in some eMode.
- Capping exposure via `ltv0 rules` exclusively for usage outside an eMode, or exclusively inside a specific eMode.

This limitation was artificial and existed only because upgrades had historically been applied gradually, with minimal but impactful changes.
Therefore, in Aave v3.6, this limitation has been removed.

**Motivation**:

This feature enables more granular risk control and resolves issues that risk teams currently face:

- **Collateral-only in eMode**: Previously, to make an asset collateral only inside an eMode, teams had to enable it outside with a very low LT as a workaround. Now assets can be collateral exclusively within specific eModes.
- **Borrowable-only in eMode**: Previously, to make an asset borrowable only inside an eMode, teams had to enable it as borrowable outside of eMode as well. This meant assets were borrowable globally even when there was only a specific use case within an eMode. Now assets can be borrowable exclusively within specific eModes.
- **eMode-specific ltv0 rules**: Previously, there was no way to flag an asset as `ltv0` only in a specific eMode or, more importantly, only outside of it. v3.6 introduces this capability, which greatly improves risk control and enables better asset offboarding strategies.

### Automatic Collateral Behavior

In v3.6, automatic collateral enabling for a user has been removed in three scenarios. These changes reduce gas costs and code complexity while having minimal impact on integrations.

**Important**: `supply` and `deposit` still automatically enable the asset as collateral for the user as before.

| Scenario             | Change                                                                          | Gas Savings               | Impact                            |
| -------------------- | ------------------------------------------------------------------------------- | ------------------------- | --------------------------------- |
| Liquidating aTokens  | Received aTokens no longer automatically enabled as collateral for the user     | ~25k gas                  | None - no one relied on this      |
| Isolated collaterals | Isolated collaterals no longer automatically enabled as collateral for the user | Savings on every transfer | None - role was never used        |
| aToken transfers     | Received aTokens no longer automatically enabled as collateral for the user     | ~18% (~25k gas)           | Minimal - one DeFi Saver contract |

#### Liquidate aTokens

**Change**: Liquidating aTokens will no longer automatically enable the received assets as collateral for the liquidator.

**Background**: In previous versions, when a liquidator received aTokens from a liquidation (including the liquidation bonus), these aTokens were automatically enabled as collateral for the liquidator.

**Motivation**:

- The current behavior was flagged by various auditors across multiple releases of the Aave protocol.
- In self-liquidation scenarios, the behavior creates accounting inconsistencies where excess debt appears as a deficit while the liquidation bonus remains as collateral.
- On-chain data showed no one ever relied on this automatic behavior.
- Removing it reduces liquidation gas costs by approximately 25k.

Given the gas-sensitive nature of liquidations and the lack of reliance on this feature, the automatic collateral enablement has been removed.

**Impact**: None. No liquidator relied on this behavior.

**Alternative**: Liquidators who want to enable the received aTokens as collateral can still do so in a single transaction via multicall.

#### Isolated Collaterals

**Change**: In v3.6, isolated collaterals are no longer automatically enabled as collateral for the user upon deposit.

**Background**: In Aave v3.2, an "Isolated collateral supplier" role was introduced. The goal was to allow certain permissioned entities to deposit isolated collateral assets and automatically enable them as collateral. The feature was never actively used but increased gas costs and code complexity.

**Motivation**:

- Code analysis revealed that the feature never worked as intended on transfers.
- The role was only ever granted twice: to the [MigrationHelperMainnet](https://etherscan.io/address/0xB748952c7BC638F31775245964707Bcc5DDFabFC) and [Legacy ParaSwapLiquiditySwapAdapter](https://etherscan.io/address/0x872fBcb1B582e8Cd0D0DD4327fBFa0B4C2730995).
- While the first contract still has some transactions, migrating only isolated assets is not a common use case.
- The second contract has not been used for over two years.
- The feature increased gas costs for every transfer.

Given the lack of usage and the gas overhead, the feature has been removed.

**Impact**: None. The role was never actively used, and the feature was never relied upon.

#### aToken Transfers

**Change**: When receiving an aToken via transfer, the receiver does not automatically get the asset enabled as collateral.

**Background**: In previous versions of the Aave protocol, a transfer would enable the received asset as collateral automatically if possible. On-chain analysis shows that for the vast majority of transfers, enabling as collateral is **unintentional** - the vast majority of users never borrow against assets received via transfer.

**Note**: While v3.6 changes the behavior on **transfer**, `supply`/`deposit` still automatically enable collateral as before.

**Motivation**:

- The feature is rarely relied upon. Most integrations work with the underlying asset rather than relying on aToken transfers. Since `deposit` still automatically enables collateral, these integrations are unaffected.
- Testing with major integrations confirmed no significant impact. The only affected integration was a [DeFi Saver](https://defisaver.com/) contract, which can be adapted to the new behavior.
- Transfers become significantly more gas efficient (~18% or ~25k gas per transfer). Since transfers are the backbone of some contracts (stata and weth gateway), the gas savings will be noticeable there as well.
- Code complexity is reduced.

All robust integrations that rely on `aToken` transfers already handle the case of an asset not being enabled as collateral, as there are edge cases where the automation does not work (isolation and ltv0).

**Impact**: Minimal. Testing confirmed no significant impact on major integrations. One DeFi Saver contract requires adaptation.

**Alternatives**:

- Integrations that want this functionality can use position manager or deposit on behalf.
- Users can manually enable collateral after transfer via multicall in a single transaction.

**Safety**: If any integration relies on this feature (e.g., non-verified contracts or small integrations), there is essentially zero chance of funds being stuck or lost. As long as a contract that manages aTokens has the ability to pull or transfer aTokens elsewhere (which should always be the case), the funds will be safe.

### Renounce Allowance

**Background**: In the current Aave ecosystem, it is common to have pending approvals for aTokens and credit delegation. This occurs because the tokens are rebasing, and the exact amount needed at execution time is often unknown. To mitigate this, integrations over-approve, leaving unused approvals.

**Change**: v3.6 introduces new functions to revoke excess approvals:

- `renounceDelegation(address delegator)` on the `VariableDebtToken`
- `renounceAllowance(address owner)` on the `AToken`

These functions allow integrations to "burn" excess allowances by setting `borrowAllowance` and `allowance` back to zero.

**Motivation**: This addresses a long-standing issue in the ecosystem by providing a clean way for integrations to revoke unused approvals.

### OpenZeppelin Alignment

v3.6 aligns event emission behavior with OpenZeppelin's ERC20 standard implementation to reduce gas costs and improve ecosystem consistency.

#### `BorrowAllowanceDelegated` event removal in `_decreaseBorrowAllowance`

**Change**: The `_decreaseBorrowAllowance` function on the `DebtTokenBase` no longer emits a `BorrowAllowanceDelegated` event.

**Motivation**: This change aligns with OpenZeppelin's ERC20 implementation regarding allowance updates. The `BorrowAllowanceDelegated` event is now only emitted on explicit approval via `approveDelegation` or `delegationWithSig`, analogous to how the `Approval` event is handled in OpenZeppelin's ERC20 contract. This reduces gas costs for operations that decrease borrow allowance, such as borrowing on behalf of another user.

#### `Approval` event removal in `transferFrom`

**Change**: The `transferFrom` function on `AToken` no longer emits an `Approval` event. The allowance is still correctly updated. Also when infinite allowance(`uint256.max`) is given, allowance is not longer consumed.

**Motivation**: This is a gas optimization that aligns with OpenZeppelin's ERC20 standard implementation, where `transferFrom` is not required to emit an `Approval` event. This behavior was flagged by multiple auditors in past releases. While there was no issue with the previous behavior, it was not aligned with most other contracts (notably modern OpenZeppelin). Removing the event emission saves (2k) gas for integrations that heavily rely on `transferFrom` (e.g., all ParaSwap adapters).

### EMode Category Label (Soft Deprecation)

**Change**: v3.6 does **not** modify the eMode category label configuration but adds a soft deprecation notice. On-chain labels remain available and will continue to function for the foreseeable future.

**Background and Motivation**: eMode categories have evolved significantly since their introduction in Aave v3. With liquid eModes (v3.2) and further improvements (v3.6), eMode categories are now much more dynamic than they originally were. As a result, the fixed label that is set on creation is starting to fall out of date. Additionally, multiple eMode categories can now exist for the same asset subset, making naming via a fixed label more complex, as seen in the existing, often clashing, labels with differentiation suffixes.

**Recommendation**: We highly recommend updating the UI code to handle the eMode selection based on a different logic rather than relying on the on-chain label. While on-chain labels will remain for backward compatibility, they should not be used in new implementations.

### Deprecation

- The `increaseAllowance` and `decreaseAllowance` functions are flagged as deprecated. Modern OpenZeppelin no longer includes these functions, and adoption is minimal.
- The `getEModeCategoryLabel` function is flagged as deprecated.
- Removal of `getEModeLogic` as the single function from `eModeLogic` was moved to `supplyLogic`.

## Upgrade Considerations

- In the upgrade payload, reserves must be iterated, and each eMode containing an `ltv0` asset as collateral must be updated to include the asset in the `ltvZeroBitmap`.
- All aToken and variable debt token implementations must be updated to account for the change in event emission.

# Emergency-Flow Considerations

`setReserveFreeze` will freeze a reserve and set ltv0 for the reserve(eMode 0), as well as on all the eModes in which the reserve is currently configured as a collateral asset.

To restore the previous state after a freeze, the emergency admin has to call:

- `setReserveFreeze(..., false)` to unfreeze the reserve.
- `setReserveLtvzero(..., false)` to revert the ltv change outside of eMode(eMode 0).
- `setAssetLtvzeroInEMode(..., false)` to remove the ltvzero flag from the respective eMode.

This change in behavior allows the `emergency admin` to:

- remove the `freeze` state without restoring ltv
- apply `ltv0` state exclusively
- remove `ltv0` state for non frozen reserves

## Changelog

### Core Contracts

#### Pool

- The `finalizeTransfer` function signature has been updated to remove the `scaledBalanceToBefore` parameter. The new signature is `finalizeTransfer(address asset, address from, address to, uint256 scaledAmount, uint256 scaledBalanceFromBefore)`.
- Two new functions have been added: `configureEModeCategoryLtvzeroBitmap(uint8 id, uint128 ltvzeroBitmap)` and `getEModeCategoryLtvzeroBitmap(uint8 id)`.
- The `getEModeLogic()` function has been removed.
- The `setUserEMode` function now delegates its execution to `SupplyLogic.executeSetUserEMode`, the function `executeSetUserEMode` was moved from the `EModeLogic` library to the `SupplyLogic` library.
- The function `getEModeCategoryLabel` is marked as deprecated.

#### PoolConfigurator

- The logic of `setReserveFreeze` has been extended. When an asset is frozen, it is now also flagged as an LTV=0 asset within all eModes where it is used as collateral.
- Added a new function `setReserveLtvzero(address asset, bool ltvzero)`.
- The `setAssetCollateralInEMode` function's logic has been updated to accommodate the new decoupled eMode configuration.
- Added a new function, `setAssetLtvzeroInEMode(address asset, uint8 categoryId, bool ltvzero)`.
- The `AssetLtvzeroInEModeChanged` event has been added.

#### AToken & IncentivizedERC20

- The `transferFrom` function no longer emits an `Approval` event. Also, allowance is not consumed when it is set to the maximum value (`type(uint256).max`).
- A new function, `renounceAllowance(address owner)`, has been added.
- The `increaseAllowance` and `decreaseAllowance` functions have been marked as deprecated.

#### VariableDebtToken & DebtTokenBase

- `VariableDebtToken` now includes a `renounceAllowance(address)` function.
- `DebtTokenBase` now includes a `renounceDelegation(address delegator)` function.

### Periphery

#### UiPoolDataProviderV3

- The `getEModes` function was updated to include the `ltvzeroBitmap` field in the returned `EModeCategory` data, according to the changes in the `DataTypes.EModeCategory` struct.

### Libraries

- **EModeLogic**: This library has been deleted, and its functionality has been integrated into other parts of the codebase, primarily `SupplyLogic`.
- **GenericLogic**: The `calculateUserAccountData` function has been refactored to support the new eMode configuration.
- **LiquidationLogic**: The logic for `_liquidateATokens` has been removed.
- **SupplyLogic**: This library now includes the `executeSetUserEMode` function from the `EModeLogic` library. It has also been updated to handle changes in `validateAutomaticUseAsCollateral`, `executeFinalizeTransfer`, and `executeUseReserveAsCollateral`.
- **ValidationLogic**: The `ISOLATED_COLLATERAL_SUPPLIER_ROLE` has been removed, and several validation functions have been updated. A new `getUserReserveLtv` function has been added.
- **DataTypes**: The `EModeCategory` struct now includes a `ltvzeroBitmap`. The `ExecuteSupplyParams` and `FinalizeTransferParams` structs have also been updated.
- **Errors**: New error messages have been added: `InvalidLtvzeroState`, `InvalidCollateralInEmode`, `InvalidDebtInEmode`, `MustBeEmodeCollateral`.
