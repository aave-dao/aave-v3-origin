## Aave v3.3 features

Aave v3.3 is an upgrade on top of Aave 3.2

## Features

### 1. Bad Debt Management

On Aave v3, some liquidation scenarios can result in a permanent "bad debt" on the protocol.
This occurs when the total collateral liquidated is insufficient to cover the repayment of all debt, leaving the account with zero collateral and some remaining debt.
We understand that such debt is unlikely to be repaid and adversely affects the protocol by continuing to accrue interest.

The bad debt feature introduces a new verification step during liquidation to mitigate the creation of new bad debt accounts post-liquidation and halt further interest accrual on such liabilities.
This step checks the total collateral and total debt values of the account post-liquidation and repayment:
If an account ends up with zero collateral and non-zero debt, any remaining debt in the account is burned and the new deficit created is accounted to the reserve.

In terms of implementation, the feature checks whether the liquidation will result in a bad debt situation by comparing whether the total borrower’s collateral equals the collateral liquidated in the base currency.
If the total borrower’s debt exceeds the debt repaid in base currency, the variable debt tokens of the borrower are burned, and it is accounted to the respective reserve as a deficit.

Conceptually the bad debt cleanup is seen as step **after** the actual liquidation.
In the special case of vGHO, the liquidation process is split into two steps:

1. vGHO.burn, burning the variable debt token.
2. `aGHO.handleRepayment(address user, address onBehalfOf, uint256 amount)` which will first discount the fee from the amount as this is the part that belongs to the treasury and then burn the remaining GHO.

When a deficit is created in GHO, there is the possibility that the no fee or only part of the fee is repaid to the treasury, but in any case, all corresponding vGHO is burned.
This would leave the protocol in an inconsistent state as the user would have stale accrued fee storage, but no more debt so the accrued fee will likely never be redirected to the treasury.
Therefore in order to maintain proper accounting and not leave users with stale fee storage on the vGHO token, the protocol will reset the accrued fee storage on the vGHO token when burning bad debt and discount the created deficit accordingly.
In practice, this means the protocol will burn the claims / accept the loss on the accrued fee when burning bad debt.
It is important to note, that this only applies to the **bad debt** part of the liquidation.
If GHO is the liquidated asset, it is possible that part of the fee or even the full fee is repaid to the treasury.

The new `deficit` data is introduced to the `ReserveData` struct by re-utilizing the deprecated stableBorrowRate (`__deprecatedStableBorrowRate`) storage, and can be fetched via the new `getReserveDeficit` function in the Pool contract.

The deficit reduction of a reserve is introduced via the `eliminateReserveDeficit` function in the Pool contract, where a permissioned entity (the registered `Umbrella` on the PoolAddressesProvider) can burn aTokens to decrease the deficit of the respective reserve.
This function only allows burning aTokens(and in the case of GHO underlying) up to the currently existing deficit and validates that the caller has no open borrow positions.

**Misc considerations**

- For positions already in bad debt, this upgrade does not offer any solution, but recommends the DAO to clean up these positions via a `repayOnBehalf`.
- `eliminateReserveDeficit` assumes for umbrella to have the tokens to be burned. In case of assets having virtual accounting enabled, aTokens will be burned. In case of virtual accounting being disabled, the underlying will be disposed of.
  Depending on the coverage asset and reserve configuration(e.g. if coverage is done via underlying, and caps don't allow depositing) it might be that it us not possible to receive the aToken.
  This is expected and considered a non-issue as the elimination of the deficit has no strict time constraint.

**Acknowledged limitations**

- For the scope of this feature we define a bad debt situation as an account that has zero collateral, in base currency, but retains some level of debt, in base currency.
  Accounts with any remaining collateral potentially can be overcollateralized again.

### 2. Liquidation logic changes

#### 2.1 Liquidation: 50% close factor re-design

The Aave protocol currently implements a so-called "Close Factor" which determines how much of a debt position can be repaid in a single liquidation.
While in Aave v2, this parameter was a constant 50%, in Aave v3 there is an alteration between the default 50% and a max close factor of 100%, currently applied when a user health-factor deteriorates below a certain threshold.

The 50% close factor has always been applied on a per reserve basis, so if a user has e.g. the following positions:

- 3k $ GHO DEBT
- 3k $ USDC DEBT
- 3k $ DAI DEBT
- 9k $ ETH Collateral
  A liquidation would only be able to liquidate 1.5k $ GHO/USDC or DAI per liquidation.

While being by design, it's also rather unintuitive and can even be problematic in smaller positions.
If the overall position value falls below a certain threshold it might no longer be economically sound to liquidate that position - by applying the close factor to each specific reserve, this problem scope is increased unnecessarily.

Therefore in Aave v3.3 the Close Factor is altered to apply for the whole position, which in the above example would allow to liquidate the whole 3k $ GHO/USDC or DAI in a single liquidation.

#### 2.2 Liquidation: Position size dependent 100% close factor

For the aave protocol it is problematic to have dust debt positions, as there is no incentive to liquidate them, while on the other hand they create an ever increasing liability to the protocol.
Most of these dust debt positions are caused by the 50% close factor being applied to already small positions.
In this case, liquidators can only liquidate 50% of a position which will decrease the overall position value to a point where the gas cost no longer outweighs the liquidation bonus.

Therefore in order to reduce the accumulation of minor debt positions, a new mechanism is introduced:
Liquidations up to a 100% close factor are now allowed whenever the total principal or the total debt of the user on the specific reserve being liquidated is below a `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD`

**Example**:
Assuming a `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD` of 1_000e8 and a position composed as:

- 1200 $ collateral A
- 900 $ debt B
- a health-factor at 0.96

In the previous system, a liquidation could have liquidated up to 50% of `debt B`.
With the new system the debt position is below the `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD`.
Therefore a liquidation could liquidate 100% of `debt B`.

**Acknowledged limitations**
Liquidations are still highly influenced by gas prices, liquidation-bonus and secondary market liquidity.
`MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD` has to be chosen in a "best effort" way to allow for liquidations on "average" network conditions.
A threshold of 2000$ for example would mean that, at a 1% bonus a liquidation cannot cost more then 20$ before no longer being liquidated by a economically reasonable liquidator.

#### 2.3 Liquidation: Forced position cleanup

A problem that exists with current liquidations is that for one or another reason, liquidators sometimes chose to not clean up a full positions but leave some minor dust.
As elaborated before, small debt positions can be a burden already, but they are especially problematic with the newly introduced bad debt cleanup:

- when leaving dust, the bad debt cleanup will **not** clean up debt, as it only triggers when the collateral is zero
- as the bad debt cleanup slightly increases gas, for liquidators there is an incentive to leave dust

To counter these problems a new mechanism is introduced to now allow any debt or collateral below `MIN_LEFTOVER_BASE` to remain after a liquidation.
If debt or collateral after the liquidation would be below `MIN_LEFTOVER_BASE`, but non of the two is exactly zero, the transaction reverts.
To achieve that, `MIN_LEFTOVER_BASE` is defined as `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD/2`.
This way it is ensured that in the range of `[0, MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD]` you can perform a full liquidation (via close Factor 100%).
On the other hand a 50% liquidation in the range of `[MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD, Infinity]` will always leave at least `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD/2`.

**Example**
Assuming a `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD` of 1_000e8, `MIN_LEFTOVER_BASE` of 500e8 and a position composed as:

- 400e8 collateral A
- 1000e8 collateral B
- 900e8 debt A
- 400e8 debt B
- a healthFactor at 0.94

In the previous system it would have been possible to liquidate any amount of debt for any respective amount of collateral.
With the new system you have to either:

- liquidate 100% of `debt B`
- liquidate 100% of `collateral A`
- liquidate up to 400e8 of `debt A` or liquidate 100% of `debt A`
- liquidate up to 500e8 of `collateral B` or liquidate 100% of `collateral B`

**Acknowledged limitations**
This feature is highly dependent on `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD` and therefore relies on choosing a reasonably high `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD`.

### 3. Bitmap access optimization

The current bitmasks on `ReserveConfiguration` have been optimized for `writes`.
This is unintuitive, as the most common protocol interactions `read` from the configuration.
By flipping the masks:

```diff
- uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
+ uint256 internal constant LTV_MASK =                       0x000000000000000000000000000000000000000000000000000000000000FFFF; // prettier-ignore
```

The access can be simplified:

```
function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
-    return self.data & ~LTV_MASK;
+    return self.data & LTV_MASK;
}
```

Which slightly reduces gas & code-size. The effect is getting more meaningful for accounts holding multiple collateral & borrow positions.

### 4. Additional getters

When analyzing ecosystem contracts we noticed that a lot of contracts have to pay excess gas due to the lack of fine grained getters on the protocol.
If an external integration e.g. wants to query the aToken balance of an address, it currently has to fetch `Pool.getReserveData().aTokenAddress` which will read 9 storage slots.
This is suboptimal, as the consumer is only interested in a single slot - the one containing the `aTokenAddress`.
Therefore we added a `getReserveAToken()` and `getReserveVariableDebtToken()` getters reducing gas cost by up to ~16k gas dependent on the usecase.
We plan on adding more dedicated getters in the future as we see fit.

## Breaking changes

The previously deprecated `pool.getReserveDataExtended()` was removed.
You can fetch the data via `pool.getReserveData()`, `pool.getVirtualUnderlyingBalance()` & `pool.getVirtualUnderlyingBalance()`.

While the interface of `calculateInterestRates` did not change, the usage assumptions changed.
Instead of passing `reserve.unbacked` you now have to pass `reserve.deficit + reserve.unbacked`.
The rational being that both values represent unbacked tokens on the pool.
