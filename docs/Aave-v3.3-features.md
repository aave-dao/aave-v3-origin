## Aave v3.3 features

Aave v3.3 is an upgrade on top of Aave 3.2

<br>
<br>

## Features

<br>

### 1. Bad Debt Management

On Aave v3, some liquidation scenarios can result in a permanent bad debt on the protocol.
This occurs when the total collateral liquidated is insufficient to cover the repayment of the debt, leaving the account with zero collateral and some remaining debt.
We understand that such debt is unlikely to be repaid and adversely affects the protocol by continuing to accrue interest.

To mitigate the creation of new bad debt accounts post-liquidation and to halt further interest accrual on such liabilities, the bad debt feature introduces a new verification step during liquidation.
This step checks the total collateral and total debt values of the account post-liquidation and repayment:
If an account ends up with zero collateral and non-zero debt, any remaining debt in the account is burned and the new deficit created is accounted to the reserve.

In terms of implementation, the feature checks whether the liquidation will result in a bad debt situation by comparing whether the total borrower’s collateral equals the collateral liquidated in the base currency.
If the total borrower’s debt exceeds the debt repaid in base currency, the variable debt tokens of the borrower are burned, and it is accounted to the respective reserve as a deficit.

For accounts already in a bad debt situation, an nem `eliminateReserveDeficit`method is introduced allowing permissionless burning of debt tokens.
It employs the same verification criteria, checking if the account's collateral equals zero while its debt remains non-zero.
This function accepts a list of accounts in bad debt to be processed. It validates that the account has zero collateral in base currency and non-zero debt before burning all variable debt tokens of the account and accounting the deficit to the equivalent reserve.

The new `deficit` data is introduced to the `ReserveData` struct by re-utilizing the deprecated stableBorrowRate (`__deprecatedStableBorrowRate`) storage, and can be fetched via the new `getReserveDeficit` function in the Pool contract.

The deficit reduction of a reserve is introduced via the `eliminateReserveDeficit` function in the Pool contract, where a permissioned entity (the registered `Umbrella` on the PoolAddressesProvider) can burn aTokens to decrease the deficit of the respective reserve.
This function only allows burning up to the currently existing deficit and validates the callers health factor and LTV before reducing the deficit.

**Misc considerations & acknowledged limitations**

- For the scope of this feature we define a bad debt situation as an account that has zero collateral but retains some level of debt. Accounts with any remaining collateral potentially can be overcollateralized again.
- Currently, there are no additional incentives for burning the debt of accounts that are already in bad debt.

**Gas Analysis**

A gas consumption analysis was conducted to evaluate the impact of implementing the bad debt feature. On average, the increase in gas usage is approximately 0.26%, with a potential maximum of 11%, depending on the number of variable debt tokens held by the borrower. We conclude that integrating this feature is beneficial despite a moderate increase in gas costs.

For accounts already in bad debt, the gas cost for executing the external function that batches multiple accounts shows an incremental increase of about 30% per account added to the batch.

```
| General Pool.Liquidations.t.sol                         |            |        |        |        |            |
|---------------------------------------------------------|------------|--------|--------|--------|------------|
|                                                         |            |        |        |        |            |
| Function Name                                           | min        | avg    | median | max    | increase   |
| burnBadDebt                                             | 84480      | 134140 | 134140 | 183800 |            |
| liquidationCall  (without bad debt feature)             | 53294      | 230728 | 324231 | 376846 |            |
| liquidationCall  (with bad debt feature)                | 53421      | 231041 | 325214 | 417368 | 0.23 - 11% |
|---------------------------------------------------------|------------|--------|--------|--------|------------|


| Isolated Tests: Liquidation without bad debt occurency  |            |        |        |        |          |
|---------------------------------------------------------|------------|--------|--------|--------|----------|
|                                                         |            |        |        |        |          |
| Function Name                                           | min        | avg    | median | max    | increase |
| liquidationCall   (without bad debt feature)            | 372084     | 372084 | 372084 | 372084 |          |
| liquidationCall   (with bad debt feature)               | 373068     | 373068 | 373068 | 373068 | 0.26%    |
|---------------------------------------------------------|------------|--------|--------|--------|----------|


| Isolated Tests: Liquidation with bad debt occurency     |            |        |        |        |          |
|---------------------------------------------------------|------------|--------|--------|--------|----------|
|                                                         |            |        |        |        |          |
| Function Name                                           | min        | avg    | median | max    | increase |
| liquidationCall   (without bad debt feature)            | 360782     | 360782 | 360782 | 360782 |          |
| liquidationCall   (with bad debt feature)               | 362937     | 362937 | 362937 | 362937 | 0.59%    |
|---------------------------------------------------------|------------|--------|--------|--------|----------|


| Isolated Tests: Batching Accounts in Bad Debt           |           |        |        |        |           |
|---------------------------------------------------------|-----------|--------|--------|--------|-----------|
|                                                         |           |        |        |        |           |
| Function Name                                           | min       | avg    | median | max    | increase  |
| burnBadDebt - 1 account                                 | 183800    | 183800 | 183800 | 183800 |           |
| burnBadDebt - 2 accounts                                | 243768    | 243768 | 243768 | 243768 | 33.68%    |
| burnBadDebt - 4 accounts                                | 363704    | 363704 | 363704 | 363704 | 50.53%    |
|---------------------------------------------------------|-----------|--------------------------|-----------|
```

<br>

---

<br>

### 2. Bitmap access optimization

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


### 3. Additional getters

When analyzing ecosystem contracts we noticed that a lot of contracts have to pay excess gas due to the lack of fine grained getters on the protocol.
If an external integration e.g. wants to query the aToken balance of an address, it currently has to fetch `Pool.getReserveData().aTokenAddress` or `Pool.getReserveDataExtended().aTokenAddress` which will read 7 or 8 storage slots respectively.
This is suboptimal, as the consumer is only interested in a single slot - the one containing the `aTokenAddress`.
Therefore we added a `getReserveAToken()` getter reducing gas cost by up to ~12k gas. We plan on adding more dedicated getters in the future when we see fit.
