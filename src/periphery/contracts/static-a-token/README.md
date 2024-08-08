# stataToken - Static aToken vault/wrapper

<p align="center">
<img src="../../../../resources/static-a-token-wrapping.jpeg" width="300">
</p>

## About

The static-a-token contains an [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) generic token vault/wrapper for all Aave v3 pools.

## Features

- **Full [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) compatibility.**
- **Accounting for any potential liquidity mining rewards.** Let’s say some team of the Aave ecosystem (or the Aave community itself) decides to incentivize deposits of USDC on Aave v3 Ethereum. By holding `stataUSDC`, the user will still be eligible for those incentives.
  It is important to highlight that while currently the wrapper supports infinite reward tokens by design (e.g. AAVE incentivizing stETH & Lido incentivizing stETH as well), each reward needs to be permissionlessly registered which bears some [⁽¹⁾](#limitations).
- **Meta-transactions support.** To enable interfaces to offer gas-less transactions to deposit/withdraw on the wrapper/Aave protocol (also supported on Aave v3). Including permit() for transfers of the `stataAToken` itself.
- **Upgradable by the Aave governance.** Similar to other contracts of the Aave ecosystem, the Level 1 executor (short executor) will be able to add new features to the deployed instances of the `stataTokens`.
- **Powered by a stataToken Factory.** Whenever a token will be listed on Aave v3, anybody will be able to call the stataToken Factory to deploy an instance for the new asset, permissionless, but still assuring the code used and permissions are properly configured without any extra headache.

See [IStaticATokenLM.sol](./interfaces/IStaticATokenLM.sol) for detailed method documentation.

## Deployed Addresses

The staticATokenFactory is deployed for all major Aave v3 pools.
An up to date address can be fetched from the respective [address-book pool library](https://github.com/bgd-labs/aave-address-book/blob/main/src/AaveV3Ethereum.sol).

## Limitations

The `stataToken` is not natively integrated into the aave protocol and therefore cannot hook into the emissionManager.
This means a `reward` added **after** `statToken` creation needs to be registered manually on the token via the permissionless `refreshRewardTokens()` method.
As this process is not currently automated users might be missing out on rewards until the method is called.

## Security procedures

For this project, the security procedures applied/being finished are:

- The test suite of the codebase itself.
- Certora audit/property checking for all the dynamics of the `stataToken`, including respecting all the specs of [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626).

## Upgrade Notes Umbrella

### Inheritance

Interface inheritance has been changed so that `IStaticATokenLM` implements `IERC4626`, making it easier for integrators to work with the interface.
The current `Initializable` has been removed in favor of the new [Initializable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/9a47a37c4b8ce2ac465e8656f31d32ac6fe26eaa/contracts/proxy/utils/Initializable.sol) following the [`ERC-7201`](https://eips.ethereum.org/EIPS/eip-7201) standard.
To account for the shift in storage, a new `DeprecationGap` has been introduced to maintain the remaining storage at the current position.

### Misc

Permit params have been excluded from the METADEPOSIT_TYPEHASH as they are not necessary.
Potential frontrunning of the permit via mempool observation is unavoidable, but due to wrapping the permit execution in a `try..catch` griefing is impossible.

### Features

#### Rescuable

[Rescuable](https://github.com/bgd-labs/solidity-utils/blob/main/src/contracts/utils/Rescuable.sol) has been applied to
the `StaticATokenLM` which will allow the ACL_ADMIN of the corresponding `POOL` to rescue any tokens on the contract.

#### Pausability

The `StaticATokenLM` implements the [PausableUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/9a47a37c4b8ce2ac465e8656f31d32ac6fe26eaa/contracts/utils/PausableUpgradeable.sol) allowing any emergency admin to pause the vault in case of an emergency.
As long as the vault is paused, minting, burning, transfers and claiming of rewards is impossible..

#### LatestAnswer

While there are already mechanisms to price the `StaticATokenLM` implemented by 3th parties for improved UX/DX the `StaticATokenLM` now exposes `latestAnswer`.
`latestAnswer` returns the asset price priced as `underlying_price * excahngeRate`.
It is important to note that:
- `underlying_price` is fetched from the AaveOracle, which means it is subject to mechanisms implemented by the DAO on top of the Chainlink price feeds.
- the `latestAnswer` is a scaled response returning the price in the same denomination as `underlying_price` which means the sprice can be undervalued by up to 1 wei
- while this should be obvious deviations in the price - even when limited to 1 wei per share - will compound per full share

### Storage diff

```
git checkout main
forge inspect src/periphery/contracts/static-a-token/StaticATokenLM.sol:StaticATokenLM storage-layout --pretty > reports/StaticATokenStorageBefore.md
git checkout project-a
forge inspect src/periphery/contracts/static-a-token/StaticATokenLM.sol:StaticATokenLM storage-layout --pretty > reports/StaticATokenStorageAfter.md
make git-diff before=reports/StaticATokenStorageBefore.md after=reports/StaticATokenStorageAfter.md out=StaticATokenStorageDiff
```

```diff
diff --git a/reports/StaticATokenStorageBefore.md b/reports/StaticATokenStorageAfter.md
index a7e3105..89e0967 100644
--- a/reports/StaticATokenStorageBefore.md
+++ b/reports/StaticATokenStorageAfter.md
@@ -1,7 +1,6 @@
 | Name               | Type                                                                           | Slot | Offset | Bytes | Contract                                                                 |
 | ------------------ | ------------------------------------------------------------------------------ | ---- | ------ | ----- | ------------------------------------------------------------------------ |
-| \_initialized      | uint8                                                                          | 0    | 0      | 1     | src/periphery/contracts/static-a-token/StaticATokenLM.sol:StaticATokenLM |
-| \_initializing     | bool                                                                           | 0    | 1      | 1     | src/periphery/contracts/static-a-token/StaticATokenLM.sol:StaticATokenLM |
+| \_\_deprecated     | uint256                                                                        | 0    | 0      | 32    | src/periphery/contracts/static-a-token/StaticATokenLM.sol:StaticATokenLM |
 | name               | string                                                                         | 1    | 0      | 32    | src/periphery/contracts/static-a-token/StaticATokenLM.sol:StaticATokenLM |
 | symbol             | string                                                                         | 2    | 0      | 32    | src/periphery/contracts/static-a-token/StaticATokenLM.sol:StaticATokenLM |
 | decimals           | uint8                                                                          | 3    | 0      | 1     | src/periphery/contracts/static-a-token/StaticATokenLM.sol:StaticATokenLM |
```
