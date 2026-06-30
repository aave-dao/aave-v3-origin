# Aave v3.5 features properties

Formal properties in natural language of the 3.5 features.

## Properties

### 1. Rounding

In the following properties `shares` refers to the `scaled balance`, while `assets` refers to the underlying.

- when supplying `x` assets, the protocol should mint an equivalent of aToken shares, so that `shares = floor(x / index)`
- when withdrawing `x` assets, the protocol should burn an equivalent of aToken shares, so that `shares = ceil(x / index)`
- when evaluating the aToken balance of a user, the balance should be calculated as `balance = floor(shares * index)`
- when borrowing `x` assets, the protocol should mint an equivalent of vToken shares, so that `shares = ceil(x / index)`
- when repaying `x` assets, the protocol should burn an equivalent of vToken shares, so that `shares = floor(x / index)`
- when evaluating the vToken balance of a user, the balance should be calculated as `balance = ceil(shares * index)`
- when calculating the `liquidationProtocolFeeAmount` and the fee distributed to the treasury, the received shares should be rounded up
- the flashLoanPremium is always rounded up, meaning that even when flashing just 1 wei of an asset, you will pay 1 wei of fee (where in previous versions of the protocol, the fee would be rounded to zero)
- when calculating the value of a user's collateral (aTokens) in the base currency, the result of `(balanceInAssetUnits * assetPrice) / assetUnit` is rounded down. (this was already the case in previous versions of the protocol for `GenericLogic._getUserBalanceInBaseCurrency`)
- when calculating the totalSupply of the aToken, `totalScaledSupply * index` is rounded down.
- when calculating the value of a user's total debt (vTokens) in the base currency, the result of `(debtInAssetUnits * assetPrice) / assetUnit` is rounded up.
- when calculating the totalSupply of the vToken, `totalScaledSupply * index` is rounded up.

```mermaid
---

config:
theme: redux

---

flowchart LR
subgraph s3["ray"]
rayDivCeil["rayDivCeil(amount, index)"]
rayDivFloor["rayDivFloor(amount, index)"]
end
subgraph s1["AToken"]
aToken.mint["mint(amount)"]
aToken.burn["burn(amount)"]
aToken.mint --> rayDivFloor
aToken.burn --> rayDivCeil
end

subgraph s2["variableDebtToken"]
variableDebtToken.mint["mint(amount)"]
variableDebtToken.burn["burn(amount)"]
variableDebtToken.mint --> rayDivCeil
variableDebtToken.burn --> rayDivFloor
end

    Pool(["Pool"]) --> supply("supply(amount)") & supplyWithPermit("supplyWithPermit(amount)") & deposit("deposit(amount)") & borrow("borrow(amount)") & flashLoantype2("flashLoantype2") & withdraw("withdraw(amount)") & repay("repay(amount)") & repayWithPermit("repayWithPermit(amount)") & repayWithATokens("repayWithATokens(amount)") & liquidationCall("liquidationCall(debtAmount, collateralAmount)")
    supply --> executeSupply["executeSupply(amount)"]
    supplyWithPermit --> executeSupply
    deposit --> executeSupply
    executeSupply --> aToken.mint["aToken.mint(amount)"] & underlying.transfer["underlying.transfer(amount)"]
    borrow --> executeBorrow["executeBorrow(amount)"]
    flashLoantype2 --> executeBorrow
    executeBorrow --> variableDebtToken.mint["variableDebtToken.mint(amount)"] & underlying.transfer
    withdraw --> executeWithdraw["executeWithdraw(amount)"]
    executeWithdraw --> aToken.burn["aToken.burn(amount)"] & underlying.transfer
    repay --> executeRepay["executeRepay(amount)"]
    repayWithPermit --> executeRepay
    repayWithATokens --> executeRepay
    executeRepay -- repayWithATokens? --> aToken.burn
    executeRepay --> variableDebtToken.burn["variableDebtToken.burn(amount)"]
    liquidationCall --> executeLiquidationCall
    executeLiquidationCall --> variableDebtToken.burn
    executeLiquidationCall -- receiveUnderlying? --> aToken.burn
    AToken(["AToken"]) --> transfer("transfer(amount)")
    transfer --> rayDivCeil
```
