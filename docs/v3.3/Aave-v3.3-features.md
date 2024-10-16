## Aave v3.3 features

Aave v3.3 is an upgrade on top of Aave 3.2

## Features

### 1. Bad Debt Management

On Aave v3, some liquidation scenarios can result in a permanent "bad debt" on the protocol.
This occurs when the total collateral liquidated is insufficient to cover the repayment of all debt, leaving the account with zero collateral and some remaining debt.
We understand that such debt is unlikely to be repaid and adversely affects the protocol by continuing to accrue interest.

To mitigate the creation of new bad debt accounts post-liquidation and to halt further interest accrual on such liabilities, the bad debt feature introduces a new verification step during liquidation.
This step checks the total collateral and total debt values of the account post-liquidation and repayment:
If an account ends up with zero collateral and non-zero debt, any remaining debt in the account is burned and the new deficit created is accounted to the reserve.

In terms of implementation, the feature checks whether the liquidation will result in a bad debt situation by comparing whether the total borrower’s collateral equals the collateral liquidated in the base currency.
If the total borrower’s debt exceeds the debt repaid in base currency, the variable debt tokens of the borrower are burned, and it is accounted to the respective reserve as a deficit.

The new `deficit` data is introduced to the `ReserveData` struct by re-utilizing the deprecated stableBorrowRate (`__deprecatedStableBorrowRate`) storage, and can be fetched via the new `getReserveDeficit` function in the Pool contract.

The deficit reduction of a reserve is introduced via the `eliminateReserveDeficit` function in the Pool contract, where a permissioned entity (the registered `Umbrella` on the PoolAddressesProvider) can burn aTokens to decrease the deficit of the respective reserve.
This function only allows burning up to the currently existing deficit and validates the callers health factor and LTV before reducing the deficit.

**Misc considerations**

- For positions already in bad debt, this upgrade does not offer any solution, but recommends the DAO to clean up these positions via a `repayOnBehalf`.

**Acknowledged limitations**

- For the scope of this feature we define a bad debt situation as an account that has zero collateral, in base currency, but retains some level of debt, in base currency.
  Accounts with any remaining collateral potentially can be overcollateralized again.

### 2. Liquidation: 50% close factor re-design

The Aave protocol currently implements a so-called "Close Factor" which determines how much of a debt position can be repaid in a single liquidation.
While in Aave v2, this parameter was a constant 50%, in Aave v3 there is an alteration between the default 50% and a max close factor of 100%, currently applied when a user health factor deteriorates below a certain threshold.

The 50% close factor has always been applied on a per reserve basis, so if a user has e.g. the following positions:

- 3k $ GHO DEBT
- 3k $ USDC DEBT
- 3k $ DAI DEBT
- 9k $ ETH Collateral
  A liquidation would only be able to liquidate 1.5k $ GHO/USDC or DAI per liquidation.

While being by design, it's also rather unintuitive and can even be problematic on smaller positions.
If the overall position value falls below a certain threshold it might no longer be economically sound to liquidate that position - by applying the close factor to each specific reserve, this problem scope is increased unnecessarily.

Therefore in Aave v3.3 the Close Factor is altered to apply for the whole position, which on the above example would allow to liquidate the whole 3k $ GHO/USDC or DAI in a single liquidation.

### 3. Liquidation: Position size dependent 100% close factor

For the aave protocol it is problematic to have dust debt positions, as there is no incentive to liquidate them, while on the other hand they create an ever increasing liability to the protocol.
Most of these dust debt positions are caused by the 50% close factor being applied to already small positions.
In this liquidators can only liquidate 50% of a position which will decrease the overall position value to a point where the gas cost no longer outweights the liquidation bonus.

Therefore in order to reduce the accumulation of minor debt positions, a new mechanism is introduced:
Liquidations up to a 100% close factor are now allowed whenever the total principal or the total debt of the user on the specific reserve being liquidated is below a `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD`

**Acknowledged limitations**
Liquidations are still highly influenced by gas price, liquidation bonus and secondary market liquidity.
`MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD` has to be chosen in a "best effort" way to allow for liquidations on "average" network conditions.
A threshold of 2000$ for example would mean that, at a 1% bonus a liquidation cannot cost more then 20$ before no longer being liquidated by a economically reasonable liquidator.

### 4. Liquidation: Forced position cleanup

A problem that exists with current liquidations is that for one or another reason, liquidators sometimes chose to not clean up a full positions but leave some minor dust.
As elaborated before, small debt positions can be problmatic already, but they are especially problematic with the newly introduced bad debt cleanup:

- when leaving dust, the bad debt cleanup will **not** clean up debt, as it only triggers when the collateral is zero
- as the bad debt cleanup slightly increases gas, for liquidators there is an incentive to leave dust

To counter these problems a new mechanism is introduced to now allow any debt or collateral below `MIN_LEFTOVER_BASE` to remain after a liquidation.
If debt or collateral after the liquidation would be below `MIN_LEFTOVER_BASE`, but non of the two is exact zero, the transaction reverts.
To achieve that, `MIN_LEFTOVER_BASE` is defined as `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD/2`.
This way it is ensured that int he range of `[0, MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD]` you can perform a full liquidation (via close Factor 100%).
On the other hand a 50% liquidation in the range of `[MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD, Infinity]` will always leave at least `MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD/2`.

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
