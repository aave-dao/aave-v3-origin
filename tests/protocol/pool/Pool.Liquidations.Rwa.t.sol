// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from 'src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {LiquidationLogic} from 'src/contracts/protocol/libraries/logic/LiquidationLogic.sol';
import {IERC20Detailed} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {PercentageMath} from 'src/contracts/protocol/libraries/math/PercentageMath.sol';
import {WadRayMath} from 'src/contracts/protocol/libraries/math/WadRayMath.sol';
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';
import {Errors} from 'src/contracts/protocol/libraries/helpers/Errors.sol';
import {AggregatorInterface} from 'src/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {TestnetRWAERC20} from 'src/contracts/mocks/testnet-helpers/TestnetRWAERC20.sol';
import {RwaAToken} from 'src/contracts/protocol/tokenization/RwaAToken.sol';
import {LiquidationDataProvider} from 'src/contracts/helpers/LiquidationDataProvider.sol';
import {TestnetProcedures} from 'tests/utils/TestnetProcedures.sol';

contract PoolLiquidationsRwaTests is TestnetProcedures {
  using UserConfiguration for DataTypes.UserConfigurationMap;

  struct RwaTokenInfo {
    address rwaToken;
    address rwaAToken;
    address user;
    address liquidator;
  }

  enum LiquidationType {
    Partial,
    Full // Full means the maximum liquidatable amount (even if that is half of the position)
  }

  /// @dev if priceImpactToken is non-zero, then its price must be changed
  /// such that the healthFactorTarget is reached. otherwise, time must be
  /// skipped such that the target is reached through borrow interest accrued.
  struct LiquidationCheck {
    address user;
    address supplyToken;
    uint256 supplyAmount;
    address borrowToken;
    address priceImpactToken;
    uint256 healthFactorTarget;
    LiquidationType liquidationType;
    bool receiveAToken;
    address liquidator;
    bytes expectedRevertData;
    bool expectFullLiquidation;
    bytes beforeLiquidationCallbackCalldata;
  }

  struct CheckLiquidationVars {
    uint256 borrowAmount;
    uint256 avgLiqThreshold;
    uint256 totalCollateralInBaseCurrency;
    uint256 totalDebtInBaseCurrency;
    int256 priceImpactPercent;
    uint256 timeToSkip;
    uint256 totalCollateralInBaseCurrencyTarget;
    uint256 totalDebtInBaseCurrencyTarget;
    uint256 liquidationAmount;
  }

  RwaTokenInfo[] internal rwaTokenInfos;
  LiquidationDataProvider internal liquidationDataProvider;

  function setUp() public {
    initTestEnvironment(false);

    liquidationDataProvider = new LiquidationDataProvider(
      address(contracts.poolProxy),
      address(contracts.poolAddressesProvider)
    );

    address buidlLiquidator = makeAddr('BUIDL_LIQUIDATOR_1');
    address wtgxxLiquidator = makeAddr('WTGXX_LIQUIDATOR_1');
    address ustbLiquidator = makeAddr('USTB_LIQUIDATOR_1');

    vm.startPrank(poolAdmin);
    // authorize alice to hold BUIDL
    buidl.authorize(alice, true);
    // mint BUIDL to alice
    buidl.mint(alice, 100_000e6);
    // authorize bob to hold USTB
    ustb.authorize(bob, true);
    // mint USTB to bob
    ustb.mint(bob, 10_000e6);
    // authorize carol to hold WTGXX
    wtgxx.authorize(carol, true);
    // mint WTGXX to carol
    wtgxx.mint(carol, 100_000e18);
    // authorize the BUIDL Liquidator to hold BUIDL
    buidl.authorize(buidlLiquidator, true);
    // authorize the USTB Liquidator to hold USTB
    ustb.authorize(ustbLiquidator, true);
    // authorize the WTGXX Liquidator to hold WTGXX
    wtgxx.authorize(wtgxxLiquidator, true);
    // mint USDX to liquidators
    usdx.mint(buidlLiquidator, 100_000e6);
    usdx.mint(ustbLiquidator, 100_000e6);
    usdx.mint(wtgxxLiquidator, 100_000e6);
    vm.stopPrank();

    vm.prank(alice);
    buidl.approve(report.poolProxy, UINT256_MAX);
    vm.prank(bob);
    ustb.approve(report.poolProxy, UINT256_MAX);
    vm.prank(carol);
    wtgxx.approve(report.poolProxy, UINT256_MAX);

    // supply 100000 USDX such that users can borrow USDX against RWAs
    _seedLiquidity({token: tokenList.usdx, amount: 100_000e6, isRwa: false});

    vm.prank(buidlLiquidator);
    usdx.approve(report.poolProxy, UINT256_MAX);
    vm.prank(ustbLiquidator);
    usdx.approve(report.poolProxy, UINT256_MAX);
    vm.prank(wtgxxLiquidator);
    usdx.approve(report.poolProxy, UINT256_MAX);

    rwaTokenInfos.push(
      RwaTokenInfo({
        rwaToken: tokenList.buidl,
        rwaAToken: rwaATokenList.aBuidl,
        user: alice,
        liquidator: buidlLiquidator
      })
    );

    rwaTokenInfos.push(
      RwaTokenInfo({
        rwaToken: tokenList.ustb,
        rwaAToken: rwaATokenList.aUstb,
        user: bob,
        liquidator: ustbLiquidator
      })
    );

    rwaTokenInfos.push(
      RwaTokenInfo({
        rwaToken: tokenList.wtgxx,
        rwaAToken: rwaATokenList.aWtgxx,
        user: carol,
        liquidator: wtgxxLiquidator
      })
    );
  }

  /// @dev Supply token price drops, which makes user fully liquidatable.
  /// It is a small liquidation (under the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  function test_fuzz_liquidation_SupplyTokenPriceDrop_Full_SmallLiquidation_GoodHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 2001e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: true,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertLt(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertLt(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGt(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Supply token price drops, which makes user fully liquidatable.
  /// It is a big liquidation (over the $2000 base value threshold),
  /// and health factor is bad (below the 0.95 close factor threshold).
  function test_fuzz_liquidation_SupplyTokenPriceDrop_Full_BigLiquidation_BadHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    // 75% price drop -> supply = $2500
    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 10000e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 94_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: true,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertGe(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGe(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertLe(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Supply token price drops, which makes user fully liquidatable.
  /// It is a big liquidation (over the $2000 base value threshold),
  /// and health factor is bad (below the 0.95 close factor threshold).
  /// User is partially liquidated due to limited liquidator power.
  function test_fuzz_liquidation_SupplyTokenPriceDrop_Partial_BigLiquidation_BadHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    // 75% price drop -> supply = $2500
    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 10000e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 94_00,
        liquidationType: LiquidationType.Partial,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertGe(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGe(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertLe(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Supply token price drops, which makes user half liquidatable.
  /// It is a big liquidation (over the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  function test_fuzz_liquidation_SupplyTokenPriceDrop_Partial_BigLiquidation_GoodHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    // 75% price drop -> supply = $2500
    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 10000e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertGe(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGe(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGt(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Borrow token price increases, which makes user fully liquidatable.
  /// It is a small liquidation (under the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  function test_fuzz_liquidation_BorrowTokenPriceIncrease_Full_SmallLiquidation_GoodHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 100e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: tokenList.usdx,
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: true,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertLt(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertLt(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGt(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Borrow token price increases, which makes user fully liquidatable.
  /// It is a big liquidation (over the $2000 base value threshold),
  /// and health factor is bad (below the 0.95 close factor threshold).
  function test_fuzz_liquidation_BorrowTokenPriceIncrease_Full_BigLiquidation_BadHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 5000e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: tokenList.usdx,
        healthFactorTarget: 90_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: true,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertGe(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGe(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertLe(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Borrow token price increases, which makes user fully liquidatable.
  /// It is a big liquidation (over the $2000 base value threshold),
  /// and health factor is bad (below the 0.95 close factor threshold).
  /// User is partially liquidated due to limited liquidator power.
  function test_fuzz_liquidation_BorrowTokenPriceIncrease_Partial_BigLiquidation_BadHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 5000e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: tokenList.usdx,
        healthFactorTarget: 90_00,
        liquidationType: LiquidationType.Partial,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertGe(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGe(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertLe(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Borrow token price increases, which makes user half liquidatable.
  /// It is a big liquidation (over the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  function test_fuzz_liquidation_BorrowTokenPriceIncrease_Partial_BigLiquidation_GoodHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    // aim for ~0.98 health at liquidation time -> $5000 * 0.86 / 0.98 = ~$4387.75
    // 4387.75 / 4000 = ~1.096 -> ~9.6% price increase in borrow token
    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 5000e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: tokenList.usdx,
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertGe(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGe(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGt(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Borrow interest accrues, which makes user fully liquidatable.
  /// It is a small liquidation (under the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  function test_fuzz_liquidation_BorrowInterestAccrued_Full_SmallLiquidation_GoodHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    // liquidityProvider withdraws 95000 USDX -> 5000 USDX are still supplied
    vm.prank(liquidityProvider);
    contracts.poolProxy.withdraw(tokenList.usdx, 95000e6, liquidityProvider);

    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 1500e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: address(0),
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: true,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertLt(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertLt(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGt(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Borrow interest accrues, which makes user fully liquidatable.
  /// It is a big liquidation (over the $2000 base value threshold),
  /// and health factor is bad (below the 0.95 close factor threshold).
  function test_fuzz_liquidation_BorrowInterestAccrued_Full_BigLiquidation_BadHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    // liquidityProvider withdraws 50000 USDX -> 50000 USDX are still supplied
    vm.prank(liquidityProvider);
    contracts.poolProxy.withdraw(tokenList.usdx, 50000e6, liquidityProvider);

    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 15000e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 93_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: true,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertGe(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGe(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertLe(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Borrow interest accrues, which makes user fully liquidatable.
  /// It is a big liquidation (over the $2000 base value threshold),
  /// and health factor is bad (below the 0.95 close factor threshold).
  /// User is partially liquidated due to limited liquidator power.
  function test_fuzz_liquidation_BorrowInterestAccrued_Partial_BigLiquidation_BadHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    // liquidityProvider withdraws 50000 USDX -> 50000 USDX are still supplied
    vm.prank(liquidityProvider);
    contracts.poolProxy.withdraw(tokenList.usdx, 50000e6, liquidityProvider);

    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 15000e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 93_00,
        liquidationType: LiquidationType.Partial,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertGe(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGe(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertLe(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Borrow interest accrues, which makes user half liquidatable.
  /// It is a big liquidation (over the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  function test_fuzz_liquidation_BorrowInterestAccrued_Partial_BigLiquidation_GoodHealth(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    // liquidityProvider withdraws 50000 USDX -> 50000 USDX are still supplied
    vm.prank(liquidityProvider);
    contracts.poolProxy.withdraw(tokenList.usdx, 50000e6, liquidityProvider);

    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 15000e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: new bytes(0),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );

    assertGe(
      liquidationInfo.collateralInfo.collateralBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGe(
      liquidationInfo.debtInfo.debtBalanceInBaseCurrency,
      LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
    );
    assertGt(liquidationInfo.userInfo.healthFactor, LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD);
  }

  /// @dev Supply token price drops, which makes user fully liquidatable.
  /// It is a small liquidation (under the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  /// Liquidator opts to receive aTokens, which is not supported for RWAs.
  function test_fuzz_reverts_liquidation_ReceiveATokens_OperationNotSupported(
    uint256 rwaTokenIndex,
    address liquidator
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    vm.assume(liquidator != report.poolAddressesProvider); // otherwise the pool proxy will not fallback

    _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 1500e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: true,
        liquidator: liquidator,
        expectedRevertData: bytes(Errors.OPERATION_NOT_SUPPORTED),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );
  }

  function test_reverts_liquidation_ReceiveATokens_OperationNotSupported() public {
    for (uint256 i = 0; i < rwaTokenInfos.length; i++) {
      test_fuzz_reverts_liquidation_ReceiveATokens_OperationNotSupported(
        i,
        rwaTokenInfos[i].liquidator
      );
    }
  }

  function test_reverts_liquidation_ReceiveATokens_Treasury_OperationNotSupported() public {
    for (uint256 i = 0; i < rwaTokenInfos.length; i++) {
      test_fuzz_reverts_liquidation_ReceiveATokens_OperationNotSupported(i, report.treasury);
    }
  }

  /// @dev Supply token price drops, which makes user fully liquidatable.
  /// It is a small liquidation (under the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  /// Liquidator is not an authorized RWA account.
  function test_fuzz_reverts_liquidation_UnauthorizedRwaAccount(
    uint256 rwaTokenIndex,
    address liquidator
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    vm.assume(liquidator != rwaTokenInfos[rwaTokenIndex].liquidator);
    vm.assume(liquidator != rwaTokenInfos[rwaTokenIndex].user);
    vm.assume(liquidator != rwaTokenInfos[rwaTokenIndex].rwaAToken);
    vm.assume(liquidator != report.poolAddressesProvider); // otherwise the pool proxy will not fallback

    _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 1500e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: liquidator,
        expectedRevertData: bytes('UNAUTHORIZED_RWA_ACCOUNT'),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );
  }

  function test_reverts_liquidation_UnauthorizedRwaAccount() public {
    test_fuzz_reverts_liquidation_UnauthorizedRwaAccount(0, rwaTokenInfos[1].liquidator);
    test_fuzz_reverts_liquidation_UnauthorizedRwaAccount(1, rwaTokenInfos[0].liquidator);
    test_fuzz_reverts_liquidation_UnauthorizedRwaAccount(2, rwaTokenInfos[0].liquidator);
  }

  /// @dev Supply token price drops, which makes user fully liquidatable.
  /// It is a small liquidation (under the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  /// The RWA aToken is no longer an authorized account.
  function test_fuzz_reverts_liquidation_ATokenUnauthorizedRwaAccount(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 1500e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: bytes('UNAUTHORIZED_RWA_ACCOUNT'),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encodeCall(
          this.removeRwaAccountAuthorization,
          (rwaTokenInfos[rwaTokenIndex].rwaToken, rwaTokenInfos[rwaTokenIndex].rwaAToken)
        )
      })
    );
  }

  /// @dev Supply token price drops, which makes user fully liquidatable.
  /// It is a small liquidation (under the $2000 base value threshold),
  /// and health factor is good (above the 0.95 close factor threshold).
  /// Liquidation Protocol Fee enabled, but aTokens cannot be sent to treasury.
  function test_fuzz_reverts_liquidation_with_LiquidationProtocolFee_OperationNotSupported(
    uint256 rwaTokenIndex
  ) public {
    rwaTokenIndex = bound(rwaTokenIndex, 0, rwaTokenInfos.length - 1);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(
      rwaTokenInfos[rwaTokenIndex].rwaToken,
      10_00
    );

    // expect call by matching the selector only
    // given that receiveAToken is false, it must be a call for fees transfer
    vm.expectCall(
      rwaTokenInfos[rwaTokenIndex].rwaAToken,
      abi.encodeWithSelector(RwaAToken.transferOnLiquidation.selector)
    );

    _checkLiquidation(
      LiquidationCheck({
        user: rwaTokenInfos[rwaTokenIndex].user,
        supplyToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        supplyAmount: _getTokenAmount(rwaTokenInfos[rwaTokenIndex].rwaToken, 1500e8),
        borrowToken: tokenList.usdx,
        priceImpactToken: rwaTokenInfos[rwaTokenIndex].rwaToken,
        healthFactorTarget: 98_00,
        liquidationType: LiquidationType.Full,
        receiveAToken: false,
        liquidator: rwaTokenInfos[rwaTokenIndex].liquidator,
        expectedRevertData: bytes(Errors.OPERATION_NOT_SUPPORTED),
        expectFullLiquidation: false,
        beforeLiquidationCallbackCalldata: abi.encode()
      })
    );
  }

  function removeRwaAccountAuthorization(address rwaToken, address account) public {
    vm.prank(poolAdmin);
    TestnetRWAERC20(rwaToken).authorize(account, false);
  }

  function _mockPrice(address token, int256 priceImpactPercent) internal {
    int256 currentPrice = int256(contracts.aaveOracle.getAssetPrice(token));
    int256 priceDelta = (currentPrice * priceImpactPercent) / 100_00;
    int256 newPrice = currentPrice + priceDelta;
    assertGe(newPrice, 0, 'new price should be non-negative');

    address priceFeed = contracts.aaveOracle.getSourceOfAsset(token);
    vm.mockCall(
      priceFeed,
      abi.encodeCall(AggregatorInterface.latestAnswer, ()),
      abi.encode(int256(newPrice))
    );
  }

  function _getRewardTokenBalance(
    address user,
    address underlyingToken,
    bool receiveAToken
  ) internal view returns (uint256) {
    address rewardToken = underlyingToken;
    if (receiveAToken) {
      (address aToken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        underlyingToken
      );
      rewardToken = aToken;
    }

    return IERC20Detailed(rewardToken).balanceOf(user);
  }

  function _getLiquidationThreshold(address token) internal view returns (uint256) {
    DataTypes.ReserveConfigurationMap memory supplyReserveConfig = contracts
      .poolProxy
      .getConfiguration(token);
    return ReserveConfiguration.getLiquidationThreshold(supplyReserveConfig);
  }

  function _getLtv(address token) internal view returns (uint256) {
    DataTypes.ReserveConfigurationMap memory supplyReserveConfig = contracts
      .poolProxy
      .getConfiguration(token);
    return ReserveConfiguration.getLtv(supplyReserveConfig);
  }

  function _convertTokenAmount(
    address fromToken,
    address toToken,
    uint256 amount
  ) internal view returns (uint256) {
    uint256 fromTokenUnits = 10 ** IERC20Detailed(fromToken).decimals();
    uint256 toTokenUnits = 10 ** IERC20Detailed(toToken).decimals();
    uint256 fromTokenPrice = contracts.aaveOracle.getAssetPrice(fromToken);
    uint256 toTokenPrice = contracts.aaveOracle.getAssetPrice(toToken);
    return (amount * toTokenUnits * fromTokenPrice) / (fromTokenUnits * toTokenPrice);
  }

  function _getTokenAmount(
    address token,
    uint256 amountInBaseCurrency
  ) internal view returns (uint256) {
    uint256 tokenUnits = 10 ** IERC20Detailed(token).decimals();
    uint256 tokenPrice = contracts.aaveOracle.getAssetPrice(token);
    return (amountInBaseCurrency * tokenUnits) / tokenPrice;
  }

  function _checkLiquidation(
    LiquidationCheck memory input
  ) internal returns (LiquidationDataProvider.LiquidationInfo memory liquidationInfo) {
    CheckLiquidationVars memory vars;

    vars.borrowAmount = _convertTokenAmount(
      input.supplyToken,
      input.borrowToken,
      // borrow almost max amount (1.05 health factor)
      (input.supplyAmount * _getLtv(input.supplyToken)) / 100_50
    );

    vm.startPrank(input.user);
    contracts.poolProxy.supply(input.supplyToken, input.supplyAmount, input.user, 0);
    contracts.poolProxy.borrow(input.borrowToken, vars.borrowAmount, 2, 0, input.user);
    vm.stopPrank();

    vars.avgLiqThreshold = _getLiquidationThreshold(input.supplyToken);
    (vars.totalCollateralInBaseCurrency, vars.totalDebtInBaseCurrency, , , , ) = contracts
      .poolProxy
      .getUserAccountData(input.user);

    if (input.priceImpactToken == input.supplyToken) {
      vars.totalCollateralInBaseCurrencyTarget =
        (vars.totalDebtInBaseCurrency * input.healthFactorTarget) /
        vars.avgLiqThreshold;
      vars.priceImpactPercent =
        ((int256(
          (vars.totalCollateralInBaseCurrencyTarget * 1e8) / vars.totalCollateralInBaseCurrency
        ) - 1e8) * int256(PercentageMath.PERCENTAGE_FACTOR)) /
        1e8;
    } else {
      vars.totalDebtInBaseCurrencyTarget =
        (vars.totalCollateralInBaseCurrency * vars.avgLiqThreshold) /
        input.healthFactorTarget;
      if (input.priceImpactToken == input.borrowToken) {
        vars.priceImpactPercent =
          ((int256((vars.totalDebtInBaseCurrencyTarget * 1e8) / vars.totalDebtInBaseCurrency) -
            1e8) * int256(PercentageMath.PERCENTAGE_FACTOR)) /
          1e8;
      } else {
        DataTypes.ReserveDataLegacy memory borrowReserveData = contracts.poolProxy.getReserveData(
          input.borrowToken
        );
        vars.timeToSkip =
          ((((vars.totalDebtInBaseCurrencyTarget * 1e8) / vars.totalDebtInBaseCurrency - 1e8) *
            365 days *
            WadRayMath.RAY) / 1e8) /
          borrowReserveData.currentVariableBorrowRate;
      }
    }

    if (input.priceImpactToken != address(0)) {
      _mockPrice(input.priceImpactToken, vars.priceImpactPercent);
    } else {
      skip(vars.timeToSkip);
    }

    uint256 liquidatorBalanceBefore = _getRewardTokenBalance(
      input.liquidator,
      input.supplyToken,
      input.receiveAToken
    );

    if (input.beforeLiquidationCallbackCalldata.length > 0) {
      (bool success, ) = address(this).delegatecall(input.beforeLiquidationCallbackCalldata);
      assertTrue(success);
    }

    vars.liquidationAmount = IERC20Detailed(
      contracts.poolProxy.getReserveVariableDebtToken(input.borrowToken)
    ).balanceOf(input.user);
    if (input.liquidationType == LiquidationType.Partial) {
      vars.liquidationAmount = vars.liquidationAmount / 2;
    }

    if (input.expectedRevertData.length != 0) {
      vm.expectRevert(input.expectedRevertData);
    } else {
      liquidationInfo = liquidationDataProvider.getLiquidationInfo({
        user: input.user,
        collateralAsset: input.supplyToken,
        debtAsset: input.borrowToken,
        debtLiquidationAmount: vars.liquidationAmount
      });

      vm.expectEmit(address(contracts.poolProxy));
      emit LiquidationLogic.LiquidationCall(
        input.supplyToken,
        input.borrowToken,
        input.user,
        liquidationInfo.maxDebtToLiquidate,
        liquidationInfo.maxCollateralToLiquidate,
        input.liquidator,
        input.receiveAToken
      );
    }

    vm.prank(input.liquidator);
    contracts.poolProxy.liquidationCall({
      collateralAsset: input.supplyToken,
      debtAsset: input.borrowToken,
      user: input.user,
      debtToCover: vars.liquidationAmount,
      receiveAToken: input.receiveAToken
    });

    // post-liquidation checks
    if (input.expectedRevertData.length == 0) {
      // check that the liquidator received the correct amount of collateral
      assertEq(
        _getRewardTokenBalance(input.liquidator, input.supplyToken, input.receiveAToken),
        liquidatorBalanceBefore + liquidationInfo.maxCollateralToLiquidate
      );

      // check partial/full liquidation
      uint256 debtLeft = IERC20Detailed(
        contracts.poolProxy.getReserveVariableDebtToken(input.borrowToken)
      ).balanceOf(input.user);
      if (input.expectFullLiquidation) {
        assertEq(debtLeft, 0, 'Debt was not fully liquidated');
      } else {
        assertGt(debtLeft, 0, 'Debt was not partially liquidated');
      }

      // check bad debt was cleared, if any
      (uint256 totalCollateralInBaseCurrency, , , , , ) = contracts.poolProxy.getUserAccountData(
        input.user
      );
      if (totalCollateralInBaseCurrency == 0) {
        assertFalse(
          contracts.poolProxy.getUserConfiguration(input.user).isBorrowingAny(),
          'Bad debt was not cleared'
        );
      }
    }
  }
}
