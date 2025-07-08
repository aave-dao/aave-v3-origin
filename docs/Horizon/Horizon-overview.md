# Horizon RWA Instance

## Context

- Horizon is an initiative by Aave Labs focused on creating Real-World Asset (RWA) products tailored for institutions.
- Horizon will launch a licensed, separate instance of the Aave Protocol (initially a fork of v3.3) to accommodate regulatory compliance requirements associated with RWA products.
- Horizon will have a dual role setup with responsibilities split between Aave DAO (Operational role) and Aave Labs (Executive role).

## Overview

The Horizon Instance will introduce permissioned (RWA) assets. The Aave Pool will remain the same, except that RWA assets can be used as collateral in order to borrow stablecoins (or other permissionless non-RWA assets). Permissioning occurs at the asset level, with each RWA Token issuer enforcing asset-specific restrictions directly into their ERC-20 token. The Aave Pool is agnostic to each specific RWA implementation and its asset-level permissioning.

From an Issuer perspective, RwaATokens are an extension of the RWA Tokens, which are securities. These RWA-specific aTokens (which are themselves not securities) will simply signify receipt of ownership of the supplied underlying RWA Token, but holders retain control over their RWA Token and can withdraw them as desired within collateralization limits.

However, holding an RwaAToken is purposefully more restrictive than merely holding an RWA Token. RWA Tokens subject holders to Issuer whitelisting and transfer mechanisms, but RwaATokens are fully locked and cannot be transferred by holders themselves.

For added security and robustness, a protocol-wide RWA aToken Transfer Admin is also added, allowing Issuers the ability to forcibly transfer RWA aTokens on behalf of end users (without needing approval). These transfers will still enforce collateralization and health factor requirements as in existing Aave peer-to-peer aToken transfers.

As with the standard Aave instance, an asset can be listed in Horizon through the usual configuration process. This instance is primarily aimed at onboarding stablecoins (or other non-RWA assets) to be borrowed by RWA holders.

## Implementation

### RWA Asset (Collateral Asset)

RWA assets can be listed by utilizing a newly developed aToken contract, `RwaAToken`, which restricts the functionality of the underlying asset within the Aave Pool. These RWA assets are intended to be used as collateral only, which is achieved through proper Pool configuration (ie setting `Liquidation Threshold` for RWA Tokens to `0`).

- RwaAToken transfers
  - users cannot transfer their own RwaATokens (transfer, allowance, and permit related methods will revert).
  - new `ATOKEN_ADMIN` role, which can forcibly transfer any RwaAToken without needing approval (but can still only transfer an RwaAToken amount up to a healthy collateralization/health factor). This role is expected to be given to the `RwaATokenManager` contract, which will granularly delegate authorization to individual accounts on a per-RwaAToken basis.
  - note that `ATOKEN_ADMIN` can also forcibly transfer RwaATokens away from the treasury address. While the treasury address currently does not receive RwaATokens of any sort through Reserve Factor or Liquidation Bonus, if this changes in the future there must be restrictions in place to protect RwaATokens earned by treasury.
- `RwaATokenManager` contract
  - external RwaAToken manager smart contract which encodes granular authorized RwaAToken transfer permissions (by granting `AUTHORIZED_TRANSFER_ROLE` for specific RwaATokens).
  - it is expected that only trusted parties (such as token Issuers) will be granted `AUTHORIZED_TRANSFER_ROLE`, and that RwaAToken authorized transfers will only occur in emergency situations (such as resolving [specific edge cases](#edge-cases-of-note)), rather than within the typical flow of operations.
  - it is left to Authorized Transfer Admin to execute authorized transfers that ensure compliance (for example, ensuring that Authorized Transfer RwaAToken recipients are allowlisted to hold the corresponding RWA Token). This scenario is described [here](#non-allowlisted-account-can-receive-rwaatokens).
- Supply
  - can only be supplied by permissioned users allowlisted to hold RWA Token (will rely on underlying RWA asset-level permissioning).
  - can be supplied as collateral, through proper risk configuration (non-zero LTV and Liquidation Threshold).
  - cannot supply `onBehalfOf` (to align with restricting RwaAToken transfers; via RwaAToken implementation, this action will revert on `mint`).
    - as a consequence, meta transactions submitted by relayers on behalf of a user are not supported.
- Withdraw
  - users can withdraw RWA assets to any specified address (via the `to` address argument in the `withdraw` function); this should be considered a standard ERC20 transfer and will adhere to the same restrictions imposed by the underlying RWA Token. This scenario is described [here](#withdraw-as-a-transfer-of-underlying-rwa-token).
- Borrow
  - cannot be borrowed or flashborrowed (via RwaAToken implementation, this action will revert on `transferUnderlyingTo`; also via asset configuration).
- Repay
  - N/A as it cannot be borrowed.
- Liquidation
  - cannot liquidate into RwaATokens, by reverting on `transferOnLiquidation` when `receiveAToken` is set to `true` (only underlying RWA Token collateral can be liquidated).
  - disbursement of Liquidation Protocol Fee is disabled (if fee is set greater than 0, it will revert on `transferOnLiquidation`; also via asset configuration).
  - release of collateral asset (ie RWA Token) should be considered a standard ERC20 transfer between liquidated user and liquidator, and will adhere to the same restrictions imposed by the underlying RWA Token. This scenario is described [here](#liquidation-as-a-transfer-of-underlying-rwa-token).
  - liquidators are implicitly permissioned to those already allowlisted to receive underlying RWA asset (will rely on underlying RWA asset-level permissioning imposed by RWA's `transfer` function).
    - technically any user allowlisted to hold RWA Token asset can liquidate; any further permissioning to a smaller subset of liquidators is expected to be governed off-chain.

#### Configuration

- RwaATokenManager contract address granted the RwaAToken admin role in the ACL Manager.
  - further granular RwaAToken admin permissions will be configured in the RwaATokenManager contract itself.
  - Token Issuers or relevant admin can be granted admin permissions on the RwaAToken corresponding to their specific RWA asset.
- No bridges/portals will be configured, hence no unbacked RwaATokens can be minted.

#### Reserve Configuration

- priceFeed: different per asset, Chainlink-compatible
- rateStrategyParams: N/A (can be left empty)
- borrowingEnabled: false (to prevent its borrowing)
- borrowableInIsolation: false
- withSiloedBorrowing: false
- flashloanable: false
- LTV: different per asset, <100%
- liquidationThreshold: different per asset, <100%
- liquidationBonus: different per asset, >100%
- reserveFactor: 0
- supplyCap: different per asset
- borrowCap: 0 (signifies no borrow cap, but cannot be borrowed due to borrowingEnabled set to false)
- debtCeiling: non-zero if the RWA asset is in isolation
- liquidationProtocolFee: 0 (must be 0, otherwise liquidations will revert in RwaAToken due to `transferOnLiquidation`)

### Stablecoins / Permissionless Non-RWA Assets (Borrowable Asset)

Stablecoins, or other non-RWA assets, can be supplied permissionlessly to earn yield. However, they will only be able to be borrowed, but disabled as collateral assets (via asset configuration, by setting Liquidation Threshold to 0). Borrowing will be implicitly permissioned because only users that have supplied RWA assets can borrow stablecoins or other permissionless non-RWA assets (except in a potential edge case described [here](#non-allowlisted-account-can-receive-rwaatokens)).

All other existing functionality remains unchanged from v3.3. Stablecoins, or other non-RWA assets, will be listed and operate as usual, following the standard process.

#### Reserve Configuration

- priceFeed: different per asset, Chainlink-compatible
- rateStrategyParams: different per asset
- borrowingEnabled: true
- borrowableInIsolation: true
- withSiloedBorrowing: false
- flashloanable: true (authorized flashborrowers can be configured)
- LTV: 0
- liquidationThreshold: 0 (to disable its use as collateral)
- liquidationBonus: N/A (can be 0)
- reserveFactor: different per asset
- supplyCap: different per asset
- borrowCap: different per asset
- debtCeiling: 0 (only applies to isolated asset)
- liquidationProtocolFee: 0 (as it won't apply for a non-collateral asset)

Stablecoins, or other non-RWA permissionless assets, may also be configured as collateral in the future, by setting `liquidationThreshold` above `0`. In such case, natively permissionless borrowing would therefore be enabled within the instance.

## Edge Cases of Note

Consider the following scenarios involving the example permissioned `RWA_1` token.

### RWA Holder Loses Private Keys to Wallet

If a user has a borrow position but loses private keys to their wallet, this position can be migrated to a new wallet by the Issuer.

#### Assumptions

- `RWA_1_ISSUER` has been granted `FLASH_BORROWER_ROLE`. The account will not pay a fee on the flashloan amount loaned.
- `RWA_1_ISSUER` has been granted `AUTHORIZED_TRANSFER_ROLE` in the RwaATokenManager contract for `aRWA_1`.
- `RWA_1_ISSUER` has an off-chain agreement with `RWA_1` suppliers to migrate supplier lost positions if needed.

#### Context

1. `ALICE` supplies `100 RWA_1`, receiving `100 aRWA_1`.
2. `ALICE` borrows `50 USDC`.
3. `ALICE` loses her wallet private key.

#### Resolution

1. `ALICE` creates a new wallet, `ALICE2`.
2. `RWA_1_ISSUER` creates a new multisig wallet controlled by `RWA_1_ISSUER` and `ALICE2` with 1 of 2 signers (`NEW_ALICE_WALLET`) which will eventually be fully transferred to `ALICE2`.
3. `RWA_1_ISSUER` executes a "complex" flashloan for `50 USDC` by calling `Pool.flashLoan(...)`. In the flashloan callback, `RWA_1_ISSUER`:
   - repays the `50 USDC` debt `onBehalfOf` `ALICE`.
   - executes `RwaATokenManager.transferRwaAToken` to transfer `100 aRWA_1` to `NEW_ALICE_WALLET`.
   - `RWA_1_ISSUER` opens a new borrow position from `NEW_ALICE_WALLET` for `50 USDC`.
   - `RWA_1_ISSUER` repays flashloan using newly borrowed `50 USDC`.
4. `RWA_1_ISSUER` revokes its signing role from `NEW_ALICE_WALLET`, fully transferring ownership to `ALICE2`.

At the conclusion, `RWA_1_ISSUER` will have migrated both `ALICE`'s initial debt and collateral positions to `NEW_ALICE_WALLET`, which will be fully controlled by `ALICE2`. It is not strictly necessary for `RWA_1_ISSUER` to be granted the `FLASH_BORROWER_ROLE`, but this will be helpful in cases where the position to migrate is large, ensuring that `RWA_1_ISSUER` will not be required to consistently maintain a liquidity buffer on hand to resolve this situation. This also allows for the position to be migrated without paying a premium for the flashloaned amount.

#### Limitations

There may not be ample liquidity in the Horizon Pool to cover via flashloan the debt position to migrate. Under those circumstances, it is the responsibility of the Issuer to provide liquidity or resolve as needed.

### RWA Holder Becomes Sanctioned After Creating a Debt Position

If a user creates a debt position but then becomes sanctioned, their actions may need to be blocked until further resolution. Consider the following scenario.

#### Assumptions

- `RWA_1` has a `80% LTV` in Horizon.

#### Context

- `ALICE` supplies `1000 RWA_1` with a value of `$1000`, receiving `1000 aRWA_1`.
- `ALICE` borrows `100 USDC`. With `80% LTV`, she could borrow `700 USDC` more.
- At this point `ALICE` becomes sanctioned.

#### Resolution

- `RWA_1_ISSUER` repays `100 USDC` debt on behalf of `ALICE`.
- `RWA_1_ISSUER` calls `RwaAToken.authorizedTransfer` to move all `1000 aRWA_1` collateral to a separate trusted address (`RWA_1_TRUSTED`) to be custodied until the sanction case is resolved.
- `RWA_1_ISSUER` retains off-chain agreement with `ALICE` to recoup `100 USDC` repaid debt.

At the conclusion, `aRWA_1` custodied by `RWA_1_TRUSTED` can be returned or moved elsewhere to ensure legal compliance. It is left to `RWA_1_ISSUER` to adjudicate as required.

#### Limitations

- Technically speaking, any wallet whitelisted to hold the underlying RWA Token can perform liquidations. Therefore, if the need arises to prevent the liquidation of any specific user's position (such as in a sanctioned user case), off-chain coordination or legal agreements are required to be in place between Issuers and any relevant parties.
  - It's possible that the accrued interest could lead to bad debt and deficit accounting if the remaining collateral is insufficient to cover the remaining debt during a liquidation operation.

## Additional Considerations

Consider the following scenarios involving the example permissioned `RWA_1` token.

### Non Allowlisted Account Can Receive RwaATokens

`authorizedTransfer` of RwaATokens do not validate that recipient addresses belong to the allowlist of the underlying RWA Token. It is left to Authorized Transfer Admin to execute authorized transfers that adhere to the proper underlying RWA Token mechanics and ensure legal compliance.

This theoretically allows recipients to open stablecoin debt positions without owning underlying RWA Tokens. Consider the following scenario.

Assumptions:

- `RWA_1_ISSUER` has been granted `AUTHORIZED_TRANSFER_ROLE` in the RwaATokenManager contract for `aRWA_1`..
- `ALICE` is allowlisted to hold `RWA_1` and has supplied `100 RWA_1` to Horizon, receiving `100 aRWA_1`.
- `BOB` is not allowlisted to hold `RWA_1`.

1. `RWA_1_ISSUER` executes `authorizedTransfer` from `ALICE` to `BOB` for `100 aRWA_1`.
2. `BOB` sets `RWA_1` to be used as collateral.
3. `BOB` borrows `50 USDC` against their `aRWA_1`.

`BOB` then has created a debt position without having held any underlying RWA Token. `RWA_1_ISSUER` bears responsibility to avoid this scenario through proper execution of `authorizedTransfer`.

### `Withdraw` as a Transfer of Underlying RWA Token

By specifying an arbitrary `to` address argument in the `withdraw` function, users who have supplied RWA Tokens can withdraw them to any other allowlisted account. This should be considered a standard ERC20 transfer and will adhere to the same restrictions imposed by the underlying RWA Token.

Assumptions:

- `ALICE` has been allowlisted.
- `RWA_1` and `aRWA_1` have decimals of 6.

Consider the following scenario.

- `Bob` supplies `100 RWA_1`.
- `Bob` withdraws `50 RWA_1` with `to` set to `ALICE`'s account.
  - if `ALICE` has **not** been allowlisted to hold `RWA_1`, this transaction will revert on the transfer of underlying `RWA_1`.
  - if `ALICE` has been allowlisted to hold `RWA_1`, she will receive `50 RWA_1`.

#### Outcome

Multiple events will be emitted, including two `Transfer` events - one from the underlying `RWA_1` token and one from the `aRWA_1` token being burned.

`aRWA_1` Transfer

```
event Transfer(address indexed from, address indexed to, uint256 value);
```

From `ScaledBalanceTokenBase.sol`, where:

- `from` is the user account whose tokens are withdrawn, `BOB`.
- `to` is the zero address to signify a `burn` action.
- `value` is the amount of `aRWA_1` being burned when collateral is withdrawn, including `aToken` decimals (ie `50_000_000`).

Underlying `RWA_1` Transfer

```
event Transfer(address indexed from, address indexed to, uint256 value);
```

From the RWA `ERC20` Token contract itself, where:

- `from` is the `RWA_1` **RwaAToken** address.
  - Note that the emitted `from` address is the **RwaAToken** smart contract rather than `BOB`'s account.
- `to` is `ALICE`'s account.
- `value` is the amount of `RWA_1` withdrawn, including decimals (ie `50_000_000`).

```
event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);
```

From `Pool.sol`, where:

- `reserve` is the `RWA_1` token address.
- `user` is `BOB`'s account.
- `to` is `ALICE`'s account.
- `amount` is the amount of `aRWA_1` withdrawn, including decimals (ie `50_000_000`).

The `RWA_1` Transfer Agent must properly record this action officially as a transfer of `RWA_1` between `BOB` and `ALICE` (rather than a transfer between the `RWA_1` RwaAToken contract and `ALICE`).

### `Liquidation` as a Transfer of Underlying RWA Token

During a liquidation, collateral seized from the user being liquidated will be transferred to the liquidator. This should also be considered a standard ERC20 transfer.

Assumptions:

- `BOB` and `ALICE` are allowlisted to hold `RWA_1`.
- `ALICE` has an off-chain legal agreement with `RWA_1_ISSUER` to be able to be a liquidator.
- `LTV` of `RWA_1` is `>80%` in Horizon.
- `RWA_1` and `aRWA_1` have decimals of 8.

Consider the following scenario:

- `BOB` supplies `100 RWA_1`, and borrows `80 USDC`.
- time flies and `Bob`'s `USDC` debt grows to `120 USDC` through accumulation of interest. His position is no longer healthy and it becomes eligible for liquidation.
- `ALICE` executes a `liquidationCall` on `BOB`'s position, and receives all of `BOB`'s `100 RWA_1` collateral (which includes the liquidation bonus) by repaying `BOB`'s `120 USDC` debt.
- `ALICE` receives `100 RWA_1`.

#### Outcome

Multiple events will be emitted, including two `Transfer` events - one from the underlying `RWA_1` token and one from the `aRWA_1` token being burned.

`aRWA_1` Transfer

```
event Transfer(address indexed from, address indexed to, uint256 value);
```

From `ScaledBalanceTokenBase.sol`, where:

- `from` is the user account being liquidated, `BOB`.
- `to` is the zero address to signify a `burn` action.
- `value` is the amount of `aRWA_1` being burned when collateral is liquidated, including decimals (ie `10_000_000_000 aRWA_1`).

Underlying `RWA_1` Transfer

```
event Transfer(address indexed from, address indexed to, uint256 value);
```

From the RWA `ERC20` Token contract itself, where:

- `from` is the `RWA_1` **RwaAToken** address.
  - Note that the emitted `from` address is the **RwaAToken** smart contract rather than `BOB`'s account.
- `to` is `ALICE`'s account.
- `value` will be the liquidated `RWA_1` collateral amount, including decimals (ie `10_000_000_000 RWA_1`).

```
event LiquidationCall(
  address indexed collateralAsset,
  address indexed debtAsset,
  address indexed user,
  uint256 debtToCover,
  uint256 liquidatedCollateralAmount,
  address liquidator,
  bool receiveAToken
);
```

From `Pool.sol`, where:

- `collateralAsset` is the `RWA_1` collateral token address.
- `debtAsset` is the `USDC` debt token address.
- `user` is the liquidated user account, `BOB`.
- `debtToCover` is the debt amount of borrowed `asset`, `USDC`, the liquidator wants to cover, including decimals (ie `120_000_000 USDC`).
- `liquidatedCollateralAmount` is the amount of collateral asset to liquidate, including decimals (ie `10_000_000_000 RWA_1`).
- `liquidator` is the liquidator address, `ALICE`'s account.
- `receiveAToken` will be `false`, as `receiveAToken` set to `true` is not allowed.

The Issuer's Transfer Agent must properly record this officially as a transfer of `RWA_1` between `BOB` (liquidated user) and `ALICE` (liquidator) (rather than a transfer between the `RWA_1` RwaAToken contract and `ALICE`).

### Further Configuration

Exact configuration details for eMode, isolated mode, flashloan fees, and liquidity mining rewards are to be determined.

## References

- https://governance.aave.com/t/arfc-horizon-s-rwa-instance/21898
- https://avara.xyz/blog/horizon
