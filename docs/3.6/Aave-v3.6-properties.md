# Aave v3.6 properties

Formal properties in natural language describing the v3.6 features.

## Glossary

**ltv0 rules**: `ltv` usually describes the loan to value ratio. If ltv is set to **exact** 0, additional rules apply, namely:

1. The asset can no longer be enabled as collateral.
2. If the user is borrowing something, ltv0 asset(s) must be withdrawn first.

## Properties

### 1. eMode Improvements

#### Collateral Enablement Rules

An asset can be enabled as collateral under the following conditions inside an eMode:

1. **Reserve-based eligibility:**

   - `reserve.lt != 0`
   - `reserve.ltv != 0`
   - `eMode.collateralBitmap` is **disabled**

2. **eMode-based eligibility:**
   - `eMode.collateralBitmap` is **enabled**
   - `eMode.ltvZeroBitmap` is **disabled**

If either condition is met, the asset can be enabled as collateral. In all other cases, the asset **cannot** be enabled as collateral.

#### LTV Zero Rules

The `ltvZero` rules apply under the following conditions inside an eMode:

1. **Reserve-based trigger:**

   - `ltv == 0`
   - `eMode.collateralBitmap` is **disabled**

2. **eMode-based trigger:**
   - `eMode.collateralBitmap` is **enabled**
   - `eMode.ltvZeroBitmap` is **enabled**

If either condition is met, `ltvZero` rules apply. In all other cases, `ltvZero` rules do **not** apply.

#### Borrow rules

An asset can be borrowed inside an eMode if the following condition is met:

- `eMode.borrowable` is **enabled**

If this condition is met, the asset can be borrowed. In all other cases, the asset **cannot** be borrowed.

#### EMode Configuration rules

- An asset can only be enabled on `eModeConfiguration.ltvzeroBitmap` if it is also enabled on `eModeConfiguration.collateralEnabledBitmap`.
- An asset can only be disabled on `eModeConfiguration.ltvzeroBitmap` if it is not `frozen`
- Removing an asset from `eModeConfiguration.collateralEnabledBitmap` will also remove it from `eModeConfiguration.ltvzeroBitmap`.
- An asset can only be removed from `eModeConfiguration.collateralEnabledBitmap` if there is no aToken supply or/and the `reserve.lt != 0`.

### Reserve Configuration rules

- `setReserveLtvzero(asset, true)` will set `pendingLtv=ltv` and `ltv=0`
- `setReserveLtvzero(asset, false)` will
  - revert in case the reserve is `frozen`
  - revert in case the `pendingLtv` is zero
  - set `ltv=pendingLtv` and `pendingLtv=0`

#### Switching eModes

When switching an eMode it must be ensured that all previously described rules are respected in the **new** eMode. Namely:

- When entering an eMode != 0 it must be ensured that:
  - All currently borrowed assets can be borrowed in the selected eMode.
  - All enabled collaterals are not considered `ltv0` based on the rules described above.
- When leaving eModes (entering eMode 0), it must be ensured that:
  - All currently borrowed assets can be borrowed on the reserve configuration.
  - All enabled collaterals are not considered `ltv0` on the reserve configuration. Implicitly this also means the collaterals are not `lt=0` as the configurator enforces `lt >= ltv`.

### OpenZeppelin alignment

- The `BorrowAllowanceDelegated` event is not emitted when a borrow allowance is decreased. It is only emitted on explicit approval via `approveDelegation` or `delegationWithSig`.
- The `Approval` event is not emitted when `transferFrom` is called on an `AToken`.
- The `allowance` is no longer consumed on `transferFrom` when infinite allowance (`uint256.max`) is given.

### Liquidate aTokens

- `liquidationCall(args)` with `receiveATokens = true` will no longer enable the received aTokens as collateral on behalf of the liquidator

### Isolated collateral supplier

- The role and functionality linked to `ISOLATED_COLLATERAL_SUPPLIER` no longer exists.

### Transfer

- The recipient of an `aToken` transfer will no longer enable the received asset as collateral.
