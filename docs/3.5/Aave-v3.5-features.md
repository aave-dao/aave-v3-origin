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

This approach of always rounding in favor of the protocol during health factor calculations is a critical security measure that protects it from potential insolvencies arising from rounding discrepancies.

### Misc changes

- smaller refactoring in `LiquidationLogic` making the code more consistent
- `repayWithAToken` is only allowed when the user is still healthy **after** the repayment. This is done in order to prevent some edge cases where the user would have debt, but no collateral or now with the adjustments on rounding, bringing himself into liquidation area through selfRepayment.
