## Aave v3.5 features

### Rounding improvements

Historically Aave has used half-up, or so called bankers rounding, for rounding operations. This has been a source of confusion and bugs in the past as it makes the rounding somewhat chaotic.

The aave protocol handles balances & yield by storing a `scaledBalance` and an index. The actual balance is then derived by multiplying the `scaledBalance` by the `index` or by dividing the `amount` by the index.
The index has 1e27 precision, which means that the rounding error usually applies on the least significant digit of the asset.
In practice that means that when e.g. depositing 1e18 of an asset, your balance might be 1e18 +-1. The rounding depends on time & index accrual, so it's difficult to exactly predict the outcome. The stata tokens and similar systems built on top therefore use a custom rounding function to ensure that the rounding is always in favor of the protocol (like it is done on the 4626 spec).

It's important to note that the rounding error is still technically unbounded. The index can grow almost(uint128.max) infinitely and the `shares` and the `underlying` share the same decimal precision. The intention of this change is to always round in favor of the protocol, to avoid insolvency situations.

This upgrade aligns the rounding methods by:

#### Rounding `down` when minting aTokens

When users `supply(amount)` to the protocol, the amount is rounded down. This means that from now on a supply will always be less than or equal to the amount the user supplied. A `supply(n)` will always yield `m = n / index` scaled balance.

Example: `supply(1e18)` would previously have resulted in an aToken balance equal to `scaledAmount = halfUp(amount / index)`, so that `amount' = halfUp(scaledAmount * index) = amount (+-precision loss)`. After the change the variance is limited to `amount' = halfUp(scaledAmount * index) = amount (-precision loss)`.

#### Rounding `up` when burning aTokens

When users `withdraw(amount)` from the protocol, the amount is rounded up. This is done to ensure that the user always receives at least the amount they requested.

Example: `withdraw(amount)` would previously have resulted in releasing `amount` of underlying and burning `scaledAmount = halfUp(amount / index)` shares, so that `amount' = halfUp(scaledAmount * index) = amount (+-precision loss)`.

#### Rounding `down` for aToken balance operations

`balanceOf` and `totalSupply` are now rounded down. Currently these methods sometimes overaccount by 1 wei, and sometimes underaccount by 1 wei. From now on they will no longer overaccount.
This is done to ensure correct behavior in regards to user operations, so that e.g. `withdraw(aToken.balanceOf(user))` will always redeem the full user balance.

#### Rounding `up` when minting vTokens

When users `borrow(amount)` from the protocol, the amount is rounded up. This is done to ensure that the protocol never underaccounts the user debt.

#### Rounding `down` when burning vTokens

When users `repay(amount)` or are being liquidated, the protocol must ensure that the repayment covers the full debt.

#### Rounding `up` for vToken balance operations

`balanceOf` and `totalSupply` are now rounded up. Currently these methods sometimes overaccount by 1 wei, and sometimes underaccount by 1 wei. From now on they will no longer underaccount.
This is done to ensure correct behavior in regards to user operations, so that e.g. `repay(vToken.balanceOf(user))` will always repay the full debt.

#### Transfers

On transfers, the scaled amount is rounded `up`.
While for other methods the rational is obvious(and well specified on ERC4626), on transfers the "correct" path is more debatable. We think that currently the more "problematic" code-path is, if you pull x funds, but you get x-1. Therefore by rounding up the scaled amount, we ensure that the contract pulling receives at least the amount it requested.

#### Rounding for User Position Valuation in Base Currency

When calculating a user's health factor, the protocol must convert their asset and debt balances into a common base currency (e.g., USD). To ensure the protocol's safety, these conversions are rounded pessimistically.

- **Collateral (aToken) Value:** The value of a user's supplied assets in the base currency is always rounded **down**. This ensures the protocol never overestimates the value of a user's collateral.
- **Debt (vToken) Value:** The value of a user's borrowed assets in the base currency is always rounded **up**. This ensures the protocol never underestimates a user's debt. A key consequence of this is that any non-zero debt, no matter how small, will be valued as at least 1 wei in the base currency. This prevents situations where tiny "dust" debts could round down to zero after conversion, making them invisible to Health Factor calculations.

This approach of always rounding in favor of the protocol during health factor calculations is a critical security measure that protects it from potential insolvencies arising from rounding discrepancies. As a result of this change, the health factor of a user may be lower than in previous versions of the protocol.

### Internal scaledAccounting

A lot of the precision loss is caused by having multiple conversions from unscaled to scaled and back.
To name a few examples:

- when validating caps, for the validation the `scaledAmount * index` + `input.amount` were considered to be the total supply - this is not accurate though as the conversion from `input.amount` to `scaledAmount` will always have a precision loss.
- when minting tokens to the treasury, the protocol stores the `scaledAmount` in `accruedToTreasury`. When the protocol mints to the treasury, the `accruedToTreasury` is scaled up and then scaled down again, which can lead to precision loss.

While these problems are not critical, for the most part, they can be mitigated by consistently working with the scaled values throughout the protocol. Therefore, `mint` and `burn` now accept `scaledAmount` as an additional input, which allows avoiding repeated roundings. As a side effect, this also slightly reduces gas consumption across the board.

### Improved flag logic

In v3.4 we increased the robustness of the flag logic for borrow operations, by switching validations from `unscaled to scaled` comparisons to checks against the actual balance (e.g. `balanceZeroAfterBurn`).

In v3.5 we decided to double down on these robustness improvements:

- on `repayWithAToken` and `withdraw`, the collateral flag is now properly set to `false` when burning all aTokens in the process. In previous versions of the protocol, there were edge cases in which the collateral flag was not properly updated.

### Improved allowance

Aave historically has never accurately tracked allowance. The reason for this is that in practice most operations are performed with the desired amount of `assets`, but the a/v token converting these amounts to `shares`.
For allowance / approval, this means that the consumed allowance is not always equal to the amount transferred. While this problem is not perfectly solvable without breaking changes, in v3.5 the protocol ensures that the exact consumed allowance is burned if available.

Example: When a user calls `transferFrom(sender, recipient, 100)` in most cases the transfer will transfer slightly more than `100` tokens (e.g `101`). This is due to precision loss between assets/shares conversion.
In Aave versions `< 3.5` this action would always result in burning `100` allowance. On Aave v3.5, the transfer will check the balance difference on the sender and discount up to the difference from the allowance.
Example: The user transfers `100`, but due to rounding he loses `102` balance. The allowance is reduced by up to `102`. If the original allowance was only `100`, the transaction will still pass for backwards compatibility.

### Misc changes

- smaller refactoring in `LiquidationLogic` making the code more consistent
- `repayWithAToken` is only allowed when the user is still healthy **after** the repayment. This is done in order to prevent some edge cases where the user would have debt, but no collateral or now with the adjustments on rounding, bringing himself into liquidation area through selfRepayment.
- `eliminateReserveDeficit` return value: The `eliminateReserveDeficit` function has been updated to return the `uint256` amount of deficit that was actually covered. This returned value represents the lesser of the input `amount` and the actual `deficit` of the reserve at the time of the call. This provides clarity to the caller on the exact amount that was successfully written off.
  - Note: This is a non-breaking change. The migration from no return value to a `uint256` return value is not expected to break any existing integrations.
- In previous versions of the protocol, `Mint` and `Burn` events on `AToken` and `VariableDebtToken` did not always perfectly reflect the amount minted and burned due to imprecision in the calculation of the `amountToMint` and `amountToBurn` variables. In v3.5, the `value` emitted in `Mint` and `Burn` events now always accurately reflects the difference between the previous upscaled balance and the new upscaled balance. For `AToken` transfers, the `Transfer` event emits the input amount, while the `BalanceTransfer` event emits the precise scaled amount being transferred. Due to the new rounding logic, the actual change in unscaled balance might differ slightly from the input amount.
- The control flow of `borrow` has been altered. While in previous versions of the protocol the `borrow` function would first check the hf limitations, from v3.5.0 the healthfactor check is performed at the end. Moving the check allows to de-duplicate the healthfactor related calculations and avoids issues due to non-equivalence in some edge cases.

### Changelog

- General changes:
  - Changed conversions between scaled and unscaled amounts:
    - In the `AToken` contract:
      - The `balanceOf` and `totalSupply` functions now round down (from scaled to unscaled).
      - The `mint` function now rounds down (from unscaled to scaled).
      - The `burn` function now rounds up (from unscaled to scaled).
      - Calculations of a transfer's scaled amount now round up in `AToken` (from unscaled to scaled).
    - In the `VariableDebtToken` contract:
      - The `balanceOf` and `totalSupply` functions now round up (from scaled to unscaled).
      - The `mint` function now rounds up (from unscaled to scaled).
      - The `burn` function now rounds down (from unscaled to scaled).
- `Pool` contract:
  - The `finalizeTransfer` function now accepts scaled amounts instead of unscaled amounts. This avoids the precision loss caused by rounding the unscaled parameters.
  - The `eliminateReserveDeficit` function now returns the actual amount of deficit that was covered.
- `AToken` contract:
  - The following functions now accept a `scaledAmount` parameter instead of the `amount` parameter, which avoids the precision loss caused by rounding the `amount` parameter:
    - `mint`
    - `mintToTreasury`
    - `transferOnLiquidation`
  - The `burn` function now accepts a new `scaledAmount` argument, which is the scaled amount of tokens to be burned. This avoids the precision loss caused by rounding the `amount` parameter.
  - Changed the logic and math of the allowance decrease in the `transferFrom` function.
- `VariableDebtToken` contract:
  - The `mint` function now accepts a new `scaledAmount` argument, which is the scaled amount of tokens to be minted. This avoids the precision loss caused by rounding the `amount` parameter.
  - The `burn` function now accepts a `scaledAmount` parameter instead of the `amount` parameter, which avoids the precision loss caused by rounding the `amount` parameter.
  - Added new state variables `__unusedGap` and `__DEPRECATED_AND_NEVER_TO_BE_REUSED`.
  - Changed the logic and math of the borrow allowance decrease in the `mint` function.
- `DebtTokenBase` contract:
  - Changed the logic and math of the borrow allowance decrease in the `_decreaseBorrowAllowance` function.
- `IncentivizedERC20` contract:
  - Added a new `_spendAllowance` function, which is used to decrease the allowance of a spender.
- `ScaledBalanceTokenBase` contract:
  - The following functions now accept scaled amounts instead of unscaled amounts:
    - `_mintScaled`
    - `_burnScaled`
  - Changed the math of the `amountToMint` variable in the `_mintScaled` function.
  - Changed the math of the `amountToBurn` and `amountToMint` variables in the `_burnScaled` function.
- Libraries:
  - `BorrowLogic` library:
    - The `executeBorrow` function now checks the health factor and the LTV of a user after the borrow operation by calling the new `ValidationLogic.validateHFAndLtv` function.
    - In the `executeRepay` function, the contract now checks the health factor of a user (`user`, not `onBehalfOf`) after the repay operation when the user is repaying with `ATokens`.
  - `FlashLoanLogic` library:
    - The `executeFlashLoan` function now rounds up the protocol fees for flash loans of type `0`.
  - `GenericLogic` library:
    - In the `calculateUserAccountData` function, the precision in health factor calculations has been improved.
    - In the `calculateAvailableBorrows` function, the `availableBorrowsInBaseCurrency` variable is now rounded down.
    - In the `_getUserDebtInBaseCurrency` function, the amount in the base currency is now rounded up.
  - `LiquidationLogic` library:
    - The `executeEliminateDeficit` function now returns the actual amount of deficit that was covered.
    - In the `executeLiquidationCall` function, some rounding behavior has been changed:
      - The `borrowerReserveDebtInBaseCurrency` variable is now rounded up.
      - The `isDebtMoreThanLeftoverThreshold` variable is now rounded up.
    - In the `_calculateAvailableCollateralToLiquidate` function, the `debtAmountNeeded` variable is now rounded up when `maxCollateralToLiquidate > borrowerCollateralBalance`.
  - `ReserveLogic` library:
    - In the `_accrueToTreasury` function, the `totalDebtAccrued` variable is now rounded down.
  - `SupplyLogic` library:
    - The `executeFinalizeTransfer` function now accepts scaled amounts instead of unscaled amounts.
  - `ValidationLogic` library:
    - The following functions now accept scaled parameters instead of unscaled parameters, which avoids the precision loss caused by rounding unscaled parameters:
      - `validateSupply`
      - `validateWithdraw`
      - `validateBorrow`
      - `validateRepay`
    - The `validateBorrow` function no longer checks the user's health factor and LTV before the borrow operation.
  - A new `TokenMath` library has been added. It contains functions to perform conversions between scaled and unscaled amounts for A/V tokens.
