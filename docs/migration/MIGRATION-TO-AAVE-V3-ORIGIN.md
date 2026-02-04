# Migration Plan: aave-v3-deploy → aave-v3-origin

## Executive Summary

This document outlines the comprehensive migration plan for transitioning the Helsinki protocol from its current `aave-v3-deploy` fork (Aave V3.0) to `aave-v3-origin` (Aave V3.1+/V3.4). This migration enables compatibility with the latest Aave infrastructure, UI, and protocol features.

**Estimated Effort:** 2-3 weeks of development work
**Risk Level:** Medium-High (significant contract changes required)

---

## Table of Contents

1. [Architecture Comparison](#1-architecture-comparison)
2. [Breaking Changes](#2-breaking-changes)
3. [Migration Phases](#3-migration-phases)
4. [Contract Migration Guide](#4-contract-migration-guide)
5. [Deployment Script Migration](#5-deployment-script-migration)
6. [Test Migration](#6-test-migration)
7. [Configuration Migration](#7-configuration-migration)
8. [Validation & Testing Strategy](#8-validation--testing-strategy)
9. [Rollback Plan](#9-rollback-plan)

---

## 1. Architecture Comparison

### Directory Structure

| Component | aave-v3-deploy (Current) | aave-v3-origin (Target) |
|-----------|--------------------------|-------------------------|
| Build System | Hardhat | Foundry |
| Contracts Location | `contracts/` | `src/contracts/` |
| Tests Location | `test/`, `tests/` | `tests/` |
| Deploy Scripts | `deploy/` (Hardhat tasks) | `scripts/` (Foundry scripts) |
| Dependencies | `node_modules/` | `lib/` (git submodules) |
| Config | `hardhat.config.ts` | `foundry.toml` |

### Dependency Management

**Current (aave-v3-deploy):**
```
@aave/core-v3@^1.19.3 (npm)
@aave/periphery-v3@^2.5.2 (npm)
@openzeppelin/contracts@^4.3.2 (npm)
```

**Target (aave-v3-origin):**
```
lib/forge-std (git submodule)
lib/solidity-utils (git submodule)
  └── lib/openzeppelin-contracts-upgradeable (OpenZeppelin 5.x)
```

---

## 2. Breaking Changes

### 2.1 Stable Debt Tokens Removed

**Impact:** HIGH - Affects all GHO-based stablecoins

Aave V3.1+ completely removed stable rate borrowing. The following must be updated:

| File | Required Changes |
|------|------------------|
| `GhoStableDebtToken.sol` | **DELETE** - No longer needed |
| `GhoAToken.sol` | Remove stable debt token references |
| `JpyUbiVariableDebtToken.sol` | Update imports, remove stable references |
| `JUBCVariableDebtToken.sol` | Update imports, remove stable references |
| `JUCVariableDebtToken.sol` | Update imports, remove stable references |

### 2.2 Interest Rate Strategy Interface Change

**Impact:** HIGH - All custom interest rate strategies

| Old Interface (V3.0) | New Interface (V3.1+) |
|---------------------|----------------------|
| `IDefaultInterestRateStrategy` | `IDefaultInterestRateStrategyV2` |
| `getVariableRateSlope1()` | `getInterestRateData(address)` returns struct |
| `getVariableRateSlope2()` | `getInterestRateDataBps(address)` returns struct |
| `getBaseVariableBorrowRate()` | All rates in single `InterestRateDataRay` struct |

**Files Requiring Updates:**
```
contracts/gho-core/facilitators/aave/interestStrategy/GhoInterestRateStrategy.sol
contracts/gho-core/facilitators/aave/interestStrategy/FixedRateStrategyFactory.sol
contracts/jpyubi/JpyUbiInterestRateStrategy.sol
contracts/jubc/JUBCInterestRateStrategy.sol
contracts/juc/JUCInterestRateStrategy.sol
```

### 2.3 OpenZeppelin 4.x → 5.x

**Impact:** MEDIUM - Import path changes

| Old Import (OZ 4.x) | New Import (OZ 5.x) |
|--------------------|---------------------|
| `@openzeppelin/contracts/security/ReentrancyGuard.sol` | `@openzeppelin/contracts/utils/ReentrancyGuard.sol` |
| `@openzeppelin/contracts/security/Pausable.sol` | `@openzeppelin/contracts/utils/Pausable.sol` |
| `IERC20Metadata` | Unchanged |
| `SafeERC20` | `SafeERC20` (but interface changes) |

### 2.4 VersionedInitializable Removal

**Impact:** MEDIUM - Upgradeability pattern change

The `VersionedInitializable` pattern used in Aave V3.0 is replaced with OpenZeppelin's `Initializable` in V3.1+.

**Files Affected:**
```
contracts/gho-core/facilitators/aave/interestStrategy/FixedRateStrategyFactory.sol
```

### 2.5 DataTypes Changes

**Impact:** HIGH - Core protocol data structures

| V3.0 DataTypes | V3.1+ DataTypes |
|---------------|-----------------|
| `ReserveData` includes `stableDebtTokenAddress` | `ReserveDataLegacy` - stable fields removed |
| `EModeCategory` has `priceSource` | `EModeCategory` has `collateralBitmap`, `borrowableBitmap` |

---

## 3. Migration Phases

### Phase 1: Infrastructure Setup (Day 1-2)

1. **Fork aave-v3-origin repository**
   ```bash
   git clone https://github.com/aave/aave-v3-origin.git
   cd aave-v3-origin
   git submodule update --init --recursive
   ```

2. **Create custom directories**
   ```
   src/contracts/custom/
   ├── gho-core/
   ├── jpyubi/
   ├── jubc/
   ├── juc/
   ├── oracles/
   ├── integrations/
   │   └── morpho/
   └── products/
       └── carryUSDC/
   ```

3. **Configure remappings.txt**
   ```
   # Add to existing remappings
   custom/=src/contracts/custom/
   ```

### Phase 2: Core Contract Migration (Day 3-7)

#### 2.1 Base Token Contract Updates

**GhoToken.sol** - Minimal changes, mostly import updates
```solidity
// Old
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

// New
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
```

#### 2.2 AToken Updates

**GhoAToken.sol, JpyUbiAToken.sol, JUBCAToken.sol, JUCAToken.sol**

Remove stable debt token interactions:
```solidity
// REMOVE these functions/references:
- function getGhoTreasury()
- stableDebtToken references
- _updateStableDebtToken()
```

#### 2.3 Variable Debt Token Updates

**GhoVariableDebtToken.sol, JpyUbiVariableDebtToken.sol, etc.**

Update base class:
```solidity
// Old
import {VersionedInitializable} from '@aave/core-v3/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol';

// New - Use OpenZeppelin Initializable
import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
```

#### 2.4 Interest Rate Strategy Updates

**Critical Rewrite Required**

```solidity
// Old Interface
interface IDefaultInterestRateStrategy {
    function getVariableRateSlope1() external view returns (uint256);
    function getVariableRateSlope2() external view returns (uint256);
    function getBaseVariableBorrowRate() external view returns (uint256);
    function OPTIMAL_USAGE_RATIO() external view returns (uint256);
}

// New Interface (V3.1+)
interface IDefaultInterestRateStrategyV2 {
    struct InterestRateDataRay {
        uint256 optimalUsageRatio;
        uint256 baseVariableBorrowRate;
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
    }

    function getInterestRateData(address reserve) external view returns (InterestRateDataRay memory);
}
```

**Migration Pattern:**
```solidity
// contracts/custom/gho-core/facilitators/aave/interestStrategy/GhoInterestRateStrategyV2.sol

pragma solidity ^0.8.10;

import {IDefaultInterestRateStrategyV2} from '../../../interfaces/IDefaultInterestRateStrategyV2.sol';
import {IPoolAddressesProvider} from '../../../interfaces/IPoolAddressesProvider.sol';
import {WadRayMath} from '../../../protocol/libraries/math/WadRayMath.sol';
import {DataTypes} from '../../../protocol/libraries/types/DataTypes.sol';

contract GhoInterestRateStrategyV2 is IDefaultInterestRateStrategyV2 {
    using WadRayMath for uint256;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    // Store rate data per reserve
    mapping(address => InterestRateData) internal _interestRateData;

    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    function getInterestRateData(address reserve)
        external
        view
        override
        returns (InterestRateDataRay memory)
    {
        InterestRateData memory data = _interestRateData[reserve];
        return InterestRateDataRay({
            optimalUsageRatio: uint256(data.optimalUsageRatio) * 1e23,
            baseVariableBorrowRate: uint256(data.baseVariableBorrowRate) * 1e23,
            variableRateSlope1: uint256(data.variableRateSlope1) * 1e23,
            variableRateSlope2: uint256(data.variableRateSlope2) * 1e23
        });
    }

    // ... rest of implementation
}
```

### Phase 3: Morpho Integration Updates (Day 8-10)

The Morpho integration contracts use OpenZeppelin and may need import updates:

```solidity
// Update in CarryAdapter.sol, MorphoVaultV1Adapter.sol, CarryStrategy.sol
// Old
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// New
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
```

### Phase 4: Oracle Adapter Updates (Day 11)

**DataStreamAggregatorAdapter.sol** - Likely minimal changes, primarily import updates.

### Phase 5: Deployment Script Migration (Day 12-14)

#### Hardhat → Foundry Script Conversion

**Current Hardhat Task:**
```typescript
// deploy/02_market/00_testnet/00_token_setup.ts
task("deploy:testnet-tokens").setAction(async (_, hre) => {
    const { deployer } = await hre.getNamedAccounts();
    // ... deployment logic
});
```

**New Foundry Script:**
```solidity
// scripts/DeployTestnetTokens.s.sol
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {TestnetERC20} from '../src/contracts/mocks/TestnetERC20.sol';

contract DeployTestnetTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens
        TestnetERC20 usdc = new TestnetERC20("USDC", "USDC", 6);

        vm.stopBroadcast();
    }
}
```

#### Market Deployment Script Structure

```solidity
// scripts/markets/DeploySepoliaMarket.s.sol
pragma solidity ^0.8.0;

import {DeployAaveV3MarketBatchedBase} from '../misc/DeployAaveV3MarketBatchedBase.sol';
import {SepoliaMarketInput} from './inputs/SepoliaMarketInput.sol';

contract DeploySepoliaMarket is DeployAaveV3MarketBatchedBase, SepoliaMarketInput {}
```

```solidity
// scripts/markets/inputs/SepoliaMarketInput.sol
pragma solidity ^0.8.0;

import {MarketInput} from 'src/deployments/inputs/MarketInput.sol';

contract SepoliaMarketInput is MarketInput {
    function _getMarketInput(address deployer)
        internal
        pure
        override
        returns (Roles memory, MarketConfig memory, DeployFlags memory, MarketReport memory)
    {
        Roles memory roles;
        roles.marketOwner = deployer;
        roles.emergencyAdmin = deployer;
        roles.poolAdmin = deployer;

        MarketConfig memory config;
        config.marketId = "Helsinki Sepolia Market";
        config.providerId = 8080;
        config.oracleDecimals = 8;
        config.flashLoanPremium = 0.0005e4;
        config.networkBaseTokenPriceInUsdProxyAggregator = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        config.marketReferenceCurrencyPriceInUsdProxyAggregator = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        config.wrappedNativeToken = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;

        DeployFlags memory flags;
        flags.l2 = false;

        MarketReport memory report;

        return (roles, config, flags, report);
    }
}
```

### Phase 6: Test Migration (Day 15-17)

#### Foundry Test Updates

```solidity
// tests/custom/unit/JpyUbiToken.t.sol
pragma solidity ^0.8.0;

import {Test, console2} from 'forge-std/Test.sol';
import {JpyUbiToken} from 'src/contracts/custom/jpyubi/JpyUbiToken.sol';

contract JpyUbiTokenTest is Test {
    JpyUbiToken public token;

    function setUp() public {
        token = new JpyUbiToken(address(this));
    }

    function test_InitialSupply() public {
        assertEq(token.totalSupply(), 0);
    }

    function test_Mint() public {
        token.addFacilitator(address(this), "test", 1000e18);
        token.mint(address(1), 100e18);
        assertEq(token.balanceOf(address(1)), 100e18);
    }
}
```

---

## 4. Contract Migration Guide

### 4.1 Import Mapping Reference

| Old Import | New Import |
|------------|------------|
| `@aave/core-v3/contracts/interfaces/IPool.sol` | `src/contracts/interfaces/IPool.sol` |
| `@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol` | `src/contracts/interfaces/IPoolAddressesProvider.sol` |
| `@aave/core-v3/contracts/protocol/libraries/math/WadRayMath.sol` | `src/contracts/protocol/libraries/math/WadRayMath.sol` |
| `@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol` | `src/contracts/protocol/libraries/types/DataTypes.sol` |
| `@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol` | `openzeppelin-contracts/contracts/token/ERC20/IERC20.sol` |
| `@aave/core-v3/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol` | `openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol` |

### 4.2 Contract-by-Contract Checklist

#### GHO Core Contracts

- [ ] `GhoToken.sol` - Update imports
- [ ] `ERC20.sol` - Update OZ imports
- [ ] `GhoAToken.sol` - Remove stable debt, update imports
- [ ] `GhoVariableDebtToken.sol` - Update base class, imports
- [ ] `GhoStableDebtToken.sol` - **DELETE**
- [ ] `GhoInterestRateStrategy.sol` - **REWRITE** to V2 interface
- [ ] `GhoDiscountRateStrategy.sol` - Update WadRayMath import
- [ ] `FixedRateStrategyFactory.sol` - Remove VersionedInitializable

#### Custom Stablecoins (jpyUBI, jUBC, jUC)

For each stablecoin:
- [ ] `*Token.sol` - Update imports
- [ ] `*AToken.sol` - Remove stable debt references, update imports
- [ ] `*VariableDebtToken.sol` - Update base class
- [ ] `*InterestRateStrategy.sol` - **REWRITE** to V2 interface
- [ ] `*DiscountRateStrategy.sol` - Update imports

#### Oracle Contracts

- [ ] `DataStreamAggregatorAdapter.sol` - Update OZ imports

#### Morpho Integration

- [ ] `CarryAdapter.sol` - Update OZ imports (ReentrancyGuard)
- [ ] `MorphoVaultV1Adapter.sol` - Update OZ imports
- [ ] `CarryStrategy.sol` - Update OZ imports
- [ ] `CarryKeeper.sol` - Update Chainlink imports
- [ ] `CarryTwapPriceChecker.sol` - Verify compatibility
- [ ] `LinearBlockTwapOracle.sol` - Verify compatibility

---

## 5. Deployment Script Migration

### 5.1 Task → Script Mapping

| Hardhat Task | Foundry Script |
|--------------|----------------|
| `deploy/00_core/00_markets_registry.ts` | `scripts/core/DeployMarketRegistry.s.sol` |
| `deploy/02_market/00_testnet/00_token_setup.ts` | `scripts/testnet/DeployTestnetTokens.s.sol` |
| `deploy/04_morpho/*.ts` | `scripts/morpho/DeployMorpho.s.sol` |
| `tasks/misc/deploy-jubc-token.ts` | `scripts/custom/DeployJUBC.s.sol` |

### 5.2 Configuration Migration

**Current (TypeScript):**
```typescript
// markets/sepolia/reservesConfigs.ts
export const strategyUSDC: IReserveParams = {
    strategy: rateStrategyStableTwo,
    baseLTVAsCollateral: "8000",
    liquidationThreshold: "8500",
    // ...
};
```

**Target (Solidity):**
```solidity
// src/deployments/inputs/reserves/SepoliaReserveConfigs.sol
library SepoliaReserveConfigs {
    function getUSDCConfig() internal pure returns (ReserveConfig memory) {
        return ReserveConfig({
            baseLTVAsCollateral: 8000,
            liquidationThreshold: 8500,
            // ...
        });
    }
}
```

---

## 6. Test Migration

### 6.1 Test File Mapping

| Current Test | New Location |
|--------------|--------------|
| `test/unit/JpyUbiToken.t.sol` | `tests/custom/unit/JpyUbiToken.t.sol` |
| `test/integration/BorrowingIntegration.t.sol` | `tests/custom/integration/BorrowingIntegration.t.sol` |
| `test/invariants/InvariantProtocol.t.sol` | `tests/custom/invariants/InvariantProtocol.t.sol` |
| `tests/__setup.spec.ts` | Convert to Foundry `setUp()` |

### 6.2 Test Import Updates

```solidity
// Old
import {Test, console2} from "forge-std/Test.sol";
import {JpyUbiToken} from "../../contracts/jpyubi/JpyUbiToken.sol";

// New
import {Test, console2} from 'forge-std/Test.sol';
import {JpyUbiToken} from 'src/contracts/custom/jpyubi/JpyUbiToken.sol';
```

---

## 7. Configuration Migration

### 7.1 Environment Variables

**Current `.env`:**
```bash
ALCHEMY_KEY=...
PRIVATE_KEY=...
ETHERSCAN_KEY=...
```

**Target `.env`:**
```bash
RPC_SEPOLIA=https://eth-sepolia.g.alchemy.com/v2/...
RPC_MAINNET=https://eth.llamarpc.com
PRIVATE_KEY=...
ETHERSCAN_API_KEY=...
```

### 7.2 foundry.toml Configuration

```toml
[profile.default]
src = 'src'
test = 'tests'
script = 'scripts'
optimizer = true
optimizer_runs = 200
solc = '0.8.27'
evm_version = 'shanghai'
bytecode_hash = 'none'
libs = ['lib']
ffi = true

[rpc_endpoints]
sepolia = "${RPC_SEPOLIA}"
mainnet = "${RPC_MAINNET}"

[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}", chainId = 11155111 }
mainnet = { key = "${ETHERSCAN_API_KEY}", chainId = 1 }
```

---

## 8. Validation & Testing Strategy

### 8.1 Unit Tests

```bash
# Run all custom unit tests
forge test --match-path "tests/custom/unit/*" -vvv
```

### 8.2 Integration Tests

```bash
# Fork Sepolia and run integration tests
forge test --match-path "tests/custom/integration/*" --fork-url $RPC_SEPOLIA -vvv
```

### 8.3 Deployment Dry Run

```bash
# Simulate deployment without broadcasting
forge script scripts/markets/DeploySepoliaMarket.s.sol --rpc-url $RPC_SEPOLIA
```

### 8.4 Contract Verification

```bash
# Verify after deployment
forge verify-contract <ADDRESS> src/contracts/custom/jpyubi/JpyUbiToken.sol:JpyUbiToken --chain sepolia
```

---

## 9. Rollback Plan

### 9.1 Git Strategy

```bash
# Create migration branch
git checkout -b migration/aave-v3-origin

# Keep main branch on aave-v3-deploy
git checkout main

# If migration fails, simply:
git checkout main
git branch -D migration/aave-v3-origin
```

### 9.2 Deployment Rollback

Keep existing Sepolia deployment addresses in documentation. If new deployment fails:
1. Point UI back to old contract addresses
2. No on-chain rollback needed (new deployment is independent)

---

## Appendix A: File Inventory

### Custom Contracts to Migrate (47 files)

**GHO Core (13 files):**
- contracts/gho-core/gho/GhoToken.sol
- contracts/gho-core/gho/ERC20.sol
- contracts/gho-core/gho/interfaces/IGhoToken.sol
- contracts/gho-core/gho/interfaces/IGhoFacilitator.sol
- contracts/gho-core/facilitators/aave/tokens/GhoAToken.sol
- contracts/gho-core/facilitators/aave/tokens/GhoVariableDebtToken.sol
- contracts/gho-core/facilitators/aave/tokens/GhoStableDebtToken.sol (DELETE)
- contracts/gho-core/facilitators/aave/interestStrategy/GhoInterestRateStrategy.sol
- contracts/gho-core/facilitators/aave/interestStrategy/GhoDiscountRateStrategy.sol
- contracts/gho-core/facilitators/aave/interestStrategy/FixedRateStrategyFactory.sol
- contracts/gho-core/facilitators/aave/interestStrategy/ZeroDiscountRateStrategy.sol
- + interfaces

**jpyUBI (5 files):**
- contracts/jpyubi/JpyUbiToken.sol
- contracts/jpyubi/JpyUbiAToken.sol
- contracts/jpyubi/JpyUbiVariableDebtToken.sol
- contracts/jpyubi/JpyUbiInterestRateStrategy.sol
- contracts/jpyubi/JpyUbiDiscountRateStrategy.sol

**jUBC (5 files):** Same structure as jpyUBI

**jUC (5 files):** Same structure as jpyUBI

**Oracles (2 files):**
- contracts/oracles/DataStreamAggregatorAdapter.sol
- contracts/oracles/interfaces/

**Morpho Integration (8 files):**
- contracts/integrations/morpho/adapters/CarryAdapter.sol
- contracts/integrations/morpho/adapters/MorphoVaultV1Adapter.sol
- contracts/integrations/morpho/interfaces/
- contracts/products/carryUSDC/CarryStrategy.sol
- contracts/products/carryUSDC/CarryKeeper.sol
- contracts/products/carryUSDC/CarryTwapPriceChecker.sol
- contracts/products/carryUSDC/LinearBlockTwapOracle.sol

---

## Appendix B: Estimated Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| 1. Infrastructure Setup | 2 days | None |
| 2. Core Contract Migration | 5 days | Phase 1 |
| 3. Morpho Integration | 3 days | Phase 2 |
| 4. Oracle Updates | 1 day | Phase 2 |
| 5. Deployment Scripts | 3 days | Phase 2-4 |
| 6. Test Migration | 3 days | Phase 2-4 |
| 7. Integration Testing | 2 days | All |
| **Total** | **~19 days** | |

---

## Appendix C: Resources

- [aave-v3-origin Repository](https://github.com/aave/aave-v3-origin)
- [Aave V3.1 Technical Paper](https://github.com/aave/aave-v3-origin/blob/main/docs/techpaper.md)
- [OpenZeppelin 5.x Migration Guide](https://docs.openzeppelin.com/contracts/5.x/upgradeable)
- [Foundry Book](https://book.getfoundry.sh/)
