# Horizon RWA Instance

## Context

- Horizon is an initiative by Aave Labs focused on creating Real-World Asset (RWA) products tailored for institutions.
- Horizon will launch a licensed, separate instance of the Aave Protocol (initially a fork of v3.3) to accommodate regulatory compliance requirements associated with RWA products.
- Horizon will have a dual role setup with responsibilities split between Aave DAO (Operational role) and Aave Labs (Executive role).

## Overview

The Horizon Instance will introduce permissioned (RWA) assets. The Aave Pool will remain the same, except that RWA assets can be used as collateral in order to borrow stablecoins. Permissioning occurs at the asset level, with each RWA token issuer enforcing asset-specific restrictions directly into their ERC-20 token. The Aave Pool is agnostic to each specific RWA implementation and its asset-level permissioning.

From an Issuer perspective, aTokens are an extension of the RWA tokens, which are securities. The aTokens will signify ownership of the supplied underlying RWA Token. To accommodate edge cases, a protocol-wide RWA aToken Transfer Admin is also added, allowing Issuers the ability to forcibly transfer RWA aTokens on behalf of end users (without needing approval). These transfers will still enforce collateralization and health factor requirements as in existing Aave peer-to-peer aToken transfers.

As with the standard Aave instance, an asset can be listed in Horizon through the usual configuration process. This instance is primarily aimed at onboarding stablecoins for borrowing.

## Implementation Overview

### RWA Asset (Collateral Asset)

RWA assets can be listed by utilizing a newly developed aToken contract, `RwaAToken`, which restricts the functionality of the underlying asset within the Aave Pool. These RWA assets are aimed to be used as collateral only, which is achieved through proper Pool configuration.

- RwaAToken transfers
  - users cannot transfer their own RwaATokens (transfer and allowance related methods will revert).
  - new `ATOKEN_ADMIN` can forcibly transfer users' RwaATokens without needing approval (but can still only transfer an RwaAToken amount up to a healthy collateralization/health factor).
- `RwaATokenManager` contract
  - external RwaAToken manager smart contract which encodes granular authorized RwaAToken transfer permissions (by granting `AUTHORIZED_TRANSFER_ROLE`).
- Supply
  - can only be supplied by permissioned users allowlisted to hold RWA Token (will rely on underlying RWA asset-level permissioning).
  - can be supplied as collateral, through proper risk configuration (non-zero LTV and Liquidation Threshold).
  - cannot supply `onBehalfOf` (to align with restricting RwaAToken transfers; via RwaAToken implementation, this action will revert on `mint`).
    - as a consequence, meta transactions are not supported.
- Borrow
  - cannot be borrowed or flashborrowed (via RwaAToken implementation, this action will revert on `transferUnderlyingTo`; also via asset configuration).
- Repay
  - N/A as it cannot be borrowed.
- Liquidation
  - cannot liquidate into RwaATokens, by reverting on `transferOnLiquidation` when `receiveAToken` is set to `true` (only underlying RWA Token collateral can be liquidated).
  - disbursement of Liquidation Protocol Fee is disabled (if fee is set greater than 0, it will revert on `transferOnLiquidation`; also via asset configuration).
  - liquidators are implicitly permissioned to those already allowlisted to receive underlying RWA asset (will rely on underlying RWA asset-level permissioning imposed by RWA's `transfer` function).
    - technically any user allowlisted to hold RWA token asset can liquidate; any further permissioning to a smaller subset of liquidators will be governed off-chain.
- Withdrawal
  - users can withdraw RWA assets to any particular address (via the `to` address in the `withdraw` function); this can be considered a standard ERC20 transfer and will adhere to the same restrictions imposed by the underlying RWA Token.

#### Configuration

- `enabledToBorrow` set to `false` to prevent borrowing.
- Liquidation Protocol Fee set to `0` (otherwise liquidations will revert in RwaAToken due to `transferOnLiquidation`).
- RwaATokenManager contract address granted the RwaAToken admin role in the ACL Manager.
  - further granular RwaAToken admin permissions will be configured in the RwaATokenManager contract itself.
  - Token Issuers or relevant admin will be granted admin permissions on the RwaAToken corresponding to their specific RWA asset.
- No bridges/portals will be configured, hence no unbacked RwaATokens can be minted. 

#### Edge Cases of Note

- User has a borrow position but loses private keys to wallet. This position will need to be migrated to a new wallet. Issuers can resolve using:
  - authorized flashborrow to borrow enough stablecoin to repay a user's debt.
  - repay `onBehalfOf` to repay debt on behalf of user.
  - `ATOKEN_ADMIN` to move RwaAToken collateral to new wallet.
  - open a new borrow position from new wallet.
- User creates a position in Horizon but then becomes sanctioned. Their actions will need to be blocked until further resolution. Issuers can resolve using:
  - `ATOKEN_ADMIN` to move maximum allowable RwaAToken collateral to temporary wallet, preventing further borrowing.
  - prevent the liquidation of the sanctioned user's position through off-chain coordination.

### Stablecoins (Borrowable Asset)

Stablecoins can be supplied permissionlessly to earn yield. However, they will only be able to be borrowed, but disabled as collateral assets (via asset configuration, by setting LTV to 0). Borrowing will be implicitly permissioned because only users that have supplied RWA assets can borrow stablecoins. Other existing functionality remains the same as in v3.3. Stablecoin assets will be listed as usual, also working in a standard way.

#### Configuration

- LTV set to `0` to prevent their utilization as collateral assets.
- authorized flashborrowers to be configured.

## References

- https://governance.aave.com/t/arfc-horizon-s-rwa-instance/21898
