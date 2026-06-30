// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAccessControl} from '../../../src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';
import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {IPriceOracleGetter} from '../../../src/contracts/interfaces/IPriceOracleGetter.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {IAToken} from '../../../src/contracts/interfaces/IAToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {ReserveLogic, IERC20} from '../../../src/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {MockAggregator} from '../../../src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {LiquidationLogic} from '../../../src/contracts/protocol/libraries/logic/LiquidationLogic.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from '../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {AaveSetters} from '../../utils/AaveSetters.sol';
import {LiquidationDataProvider} from '../../../src/contracts/helpers/LiquidationDataProvider.sol';

contract PoolLiquidationTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using PercentageMath for uint256;
  using WadRayMath for uint256;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;

  IVariableDebtToken internal varDebtUSDX;
  address internal aUSDX;
  address[] internal badDebtAccounts;

  LiquidationDataProvider internal liquidationDataProvider;

  function setUp() public {
    initTestEnvironment();

    (address atoken, , address variableDebtUSDX) = contracts
      .protocolDataProvider
      .getReserveTokensAddresses(tokenList.usdx);
    aUSDX = atoken;
    varDebtUSDX = IVariableDebtToken(variableDebtUSDX);

    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);
    contracts.poolProxy.supply(tokenList.weth, 100e18, carol, 0);
    vm.stopPrank();

    liquidationDataProvider = new LiquidationDataProvider(
      address(contracts.poolProxy),
      address(contracts.poolAddressesProvider)
    );

    badDebtAccounts.push(makeAddr('badDebtUser1'));
    badDebtAccounts.push(makeAddr('badDebtUser2'));
  }

  struct LiquidationInput {
    address collateralAsset;
    address user;
    address debtAsset;
    uint256 actualDebtToLiquidate;
    uint256 actualCollateralToLiquidate;
    bool receiveAToken;
    uint256 liquidationAmountInput;
    uint256 userCollateralBalance;
    uint256 priceImpactPercent;
    uint256 totalCollateralInBaseCurrency;
    uint256 totalDebtInBaseCurrency;
    uint256 healthFactor;
  }

  function test_liquidate_variable_borrow_same_collateral_and_borrow() public {
    uint256 amount = 2000e6;
    uint256 borrowAmount = 1620e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    vm.warp(vm.getBlockTimestamp() + 20000 days);

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.usdx,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      0
    );

    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );
    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );

    _checkInterestRates(params.collateralAsset);
  }

  function test_liquidate_variable_borrow_repro() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 23_33);
    uint256 amount = 1.00999999e8;
    uint256 borrowAmount = 20500.999999e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.warp(vm.getBlockTimestamp() + 30 days);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.002e8, 2, 0, alice);
    vm.stopPrank();

    vm.warp(vm.getBlockTimestamp() + 30 days);

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      16_00
    );

    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );
    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );

    _afterLiquidationChecksVariable(params, bob, liquidatorBalanceBefore, userDebtBefore);

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);
  }

  function test_liquidate_variable_borrow_no_fee() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.wbtc, 0);

    uint256 amount = 1e8;
    uint256 borrowAmount = 20500e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      16_00
    );

    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );
    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );
    _afterLiquidationChecksVariable(params, bob, liquidatorBalanceBefore, userDebtBefore);

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);
  }

  function test_partial_liquidate_variable_borrow() public {
    uint256 amount = 1e8;
    uint256 borrowAmount = 20500e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      106e6,
      tokenList.wbtc,
      25_00
    );

    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );
    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );

    _afterLiquidationChecksVariable(params, bob, liquidatorBalanceBefore, userDebtBefore);

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);
  }

  function test_partial_liquidate_atokens_variable_borrow() public {
    uint256 amount = 1e8;
    uint256 borrowAmount = 20500e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      106e6,
      tokenList.wbtc,
      25_00
    );
    params.receiveAToken = true;

    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );
    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );

    _afterLiquidationChecksVariable(params, bob, liquidatorBalanceBefore, userDebtBefore);

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);
  }

  function test_full_liquidate_atokens_multiple_variable_borrows() public {
    uint256 amount = 1e8;
    uint256 borrowAmountUsdx = 200e6;
    uint256 borrowAmountWeth = 10e18;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmountUsdx - 1, 2, 0, alice);
    contracts.poolProxy.borrow(tokenList.weth, borrowAmountWeth, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      30_00
    );

    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );
    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);

    // Only USDX debt is fully liquidated — BTC collateral is partially consumed, flag stays on
    uint16 collateralId = contracts.poolProxy.getReserveData(params.collateralAsset).id;
    assertTrue(
      contracts.poolProxy.getUserConfiguration(params.user).isUsingAsCollateral(collateralId),
      'collateral flag should remain after partial collateral consumption'
    );
  }

  function test_full_liquidate_atokens_edgecase_collateral_not_enough_to_cover_fee() public {
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, 49, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 30, 2, 0, alice);
    vm.stopPrank();

    AaveSetters.setLiquidityIndex(address(contracts.poolProxy), tokenList.usdx, 2.05e27);
    AaveSetters.setVariableBorrowIndex(address(contracts.poolProxy), tokenList.usdx, 4.05e27);

    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.usdx,
      alice,
      type(uint256).max,
      true
    );

    address atoken = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    assertEq(IERC20(atoken).balanceOf(alice), 0);

    // All collateral consumed → flag should be cleared
    uint16 usdxId = contracts.poolProxy.getReserveData(tokenList.usdx).id;
    assertFalse(
      contracts.poolProxy.getUserConfiguration(alice).isUsingAsCollateral(usdxId),
      'collateral flag should be cleared when all collateral consumed'
    );
  }

  function test_full_liquidate_multiple_variable_borrows() public {
    uint256 amount = 1e8;
    uint256 borrowAmountUsdx = 200e6;
    uint256 borrowAmountWeth = 10e18;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmountUsdx - 1, 2, 0, alice);
    contracts.poolProxy.borrow(tokenList.weth, borrowAmountWeth, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      30_00
    );
    params.receiveAToken = true;

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );
    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );
    address variableDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);
    address atokenAddress = contracts.poolProxy.getReserveAToken(params.collateralAsset);

    assertEq(IERC20(atokenAddress).balanceOf(bob), params.actualCollateralToLiquidate);
    assertEq(IERC20(variableDebtToken).balanceOf(params.user), 0);

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);

    // Only USDX debt is fully liquidated — BTC collateral is partially consumed, flag stays on
    uint16 collateralId = contracts.poolProxy.getReserveData(params.collateralAsset).id;
    assertTrue(
      contracts.poolProxy.getUserConfiguration(params.user).isUsingAsCollateral(collateralId),
      'collateral flag should remain after partial collateral consumption (receiveAToken)'
    );
  }

  function test_full_liquidate_multiple_supplies_and_variable_borrows() public {
    uint256 supplyWbtc = 1e8;
    uint256 supplyWeth = 0.01e18;
    uint256 borrowAmountUsdx = 200e6;
    uint256 borrowAmountWeth = 10e18;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, supplyWbtc, alice, 0);
    contracts.poolProxy.supply(tokenList.weth, supplyWeth, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmountUsdx - 1, 2, 0, alice);
    contracts.poolProxy.borrow(tokenList.weth, borrowAmountWeth, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.weth,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      30_00
    );
    params.receiveAToken = true;
    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);

    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atokenAddress = contracts.poolProxy.getReserveAToken(params.collateralAsset);

      liquidatorBalanceBefore = IERC20(atokenAddress).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }
    uint256 variableDebtBefore = IERC20(varDebtToken).balanceOf(params.user);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.ReserveUsedAsCollateralDisabled(params.collateralAsset, params.user);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );
    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );

    address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);

    if (params.receiveAToken) {
      assertEq(
        IERC20(atoken).balanceOf(bob),
        liquidatorBalanceBefore + params.actualCollateralToLiquidate,
        'liquidator balance doesnt match'
      );
    } else {
      assertEq(
        IERC20(params.collateralAsset).balanceOf(bob),
        liquidatorBalanceBefore + params.actualCollateralToLiquidate,
        'liquidator balance doesnt match'
      );
    }

    assertApproxEqAbs(
      IERC20(varDebtToken).balanceOf(params.user),
      variableDebtBefore - params.actualDebtToLiquidate,
      1,
      'variable debt balance should decrease liquidation amount'
    );

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);

    // WETH collateral fully consumed → flag cleared
    uint16 wethId = contracts.poolProxy.getReserveData(tokenList.weth).id;
    assertFalse(
      contracts.poolProxy.getUserConfiguration(params.user).isUsingAsCollateral(wethId),
      'WETH collateral flag should be cleared after full liquidation'
    );
    // WBTC collateral still present → flag stays on
    uint16 wbtcId = contracts.poolProxy.getReserveData(tokenList.wbtc).id;
    assertTrue(
      contracts.poolProxy.getUserConfiguration(params.user).isUsingAsCollateral(wbtcId),
      'WBTC collateral flag should remain (not liquidated)'
    );
  }

  function test_self_liquidate_position_shouldRevert() public {
    uint256 borrowAmount = 11000e6;

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      40_00
    );
    params.receiveAToken = true;

    // Liquidate
    vm.expectRevert(abi.encodeWithSelector(Errors.SelfLiquidation.selector));
    vm.prank(alice);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      type(uint256).max,
      params.receiveAToken
    );
    uint256 id = contracts.poolProxy.getReserveData(params.collateralAsset).id;
    assertEq(contracts.poolProxy.getUserConfiguration(alice).isUsingAsCollateral(id), true);
  }

  function test_liquidate_emode_position_without_emode_oracle() public {
    EModeCategoryInput memory ct = _genCategoryOne();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      ct.label,
      ct.isolated
    );
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.weth, ct.id, true);
    vm.stopPrank();

    uint256 amount = 1e8;
    uint256 borrowAmount = 12e18;

    vm.startPrank(alice);
    contracts.poolProxy.setUserEMode(ct.id);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.weth, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.weth,
      UINT256_MAX,
      tokenList.wbtc,
      20_00
    );

    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);

    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);

      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );

    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );

    _afterLiquidationChecksVariable(params, bob, liquidatorBalanceBefore, userDebtBefore);

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);
  }

  function test_liquidate_emode_position_ltzero_outside_emode() public {
    EModeCategoryInput memory ct = _genCategoryOne();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(tokenList.wbtc, 0, 0, 0);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      ct.label,
      ct.isolated
    );
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.weth, ct.id, true);
    vm.stopPrank();

    uint256 amount = 1e8;
    uint256 borrowAmount = 12e18;

    vm.startPrank(alice);
    contracts.poolProxy.setUserEMode(ct.id);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.weth, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.weth,
      UINT256_MAX,
      tokenList.wbtc,
      20_00
    );

    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);

    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);

      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );

    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );

    _afterLiquidationChecksVariable(params, bob, liquidatorBalanceBefore, userDebtBefore);

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);
  }

  function test_liquidate_borrow_bad_debt() public {
    uint256 supplyAmount = 0.5e8;
    uint256 borrowAmount = 11000e6;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, supplyAmount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    vm.warp(vm.getBlockTimestamp() + 30 days);
    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      20_00
    );

    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);

    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);

      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.DeficitCreated(
      params.user,
      tokenList.usdx,
      userDebtBefore - params.actualDebtToLiquidate
    );
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );
    _afterLiquidationChecksVariable(params, bob, liquidatorBalanceBefore, userDebtBefore);

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);
  }

  function test_liquidate_borrow_burn_multiple_assets_bad_debt() public {
    uint256 amount = 1.00999999e8;
    uint256 borrowAmount = 20500.999999e6;
    uint256 secondBorrowAmount = 0.002e8;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.warp(vm.getBlockTimestamp() + 30 days);
    contracts.poolProxy.borrow(tokenList.weth, secondBorrowAmount, 2, 0, alice);
    contracts.poolProxy.borrow(tokenList.wbtc, secondBorrowAmount, 2, 0, alice);
    vm.stopPrank();

    vm.warp(vm.getBlockTimestamp() + 30 days);

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      21_50
    );

    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);

    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);

    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);

      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.DeficitCreated(
      params.user,
      tokenList.usdx,
      userDebtBefore - params.actualDebtToLiquidate
    );
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );
    _afterLiquidationChecksVariable(params, bob, liquidatorBalanceBefore, userDebtBefore);
    // check second borrow
    varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(tokenList.wbtc);
    assertEq(IERC20(varDebtToken).balanceOf(params.user), 0, 'user balance doesnt match');

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);
  }

  function test_deficit_increased_after_liquidate_bad_debt() public {
    uint256 supplyAmount = 0.5e8;
    uint256 borrowAmount = 11000e6;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, supplyAmount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    vm.warp(vm.getBlockTimestamp() + 30 days);
    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      20_00
    );

    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(params.debtAsset);

    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);

      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.DeficitCreated(
      params.user,
      tokenList.usdx,
      userDebtBefore - params.actualDebtToLiquidate
    );
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );
    assertEq(
      contracts.poolProxy.getReserveDeficit(tokenList.usdx),
      userDebtBefore - params.actualDebtToLiquidate
    );

    _checkInterestRates(params.collateralAsset);
    _checkInterestRates(params.debtAsset);
  }

  function _loadLiquidationInput(
    address user,
    address collateralAsset,
    address debtAsset,
    uint256 liquidationAmount,
    address priceImpactSource,
    uint256 priceImpact
  ) internal returns (LiquidationInput memory) {
    LiquidationInput memory params;
    params.collateralAsset = collateralAsset;
    params.debtAsset = debtAsset;
    params.user = user;
    params.liquidationAmountInput = liquidationAmount;
    params.receiveAToken = false;
    address atoken = contracts.poolProxy.getReserveAToken(params.collateralAsset);

    params.userCollateralBalance = IAToken(atoken).balanceOf(params.user);
    params.priceImpactPercent = priceImpact;

    // This test expects oracle source is MockAggregator.sol
    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(priceImpactSource))
      .sig('_latestAnswer()')
      .checked_write(
        _calcPrice(
          IAaveOracle(report.aaveOracle).getAssetPrice(priceImpactSource),
          params.priceImpactPercent
        )
      );

    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = liquidationDataProvider
      .getLiquidationInfo(user, collateralAsset, debtAsset, liquidationAmount);

    params.collateralAsset = collateralAsset;
    params.debtAsset = debtAsset;
    params.user = user;
    params.liquidationAmountInput = liquidationAmount;
    params.receiveAToken = false;

    params.userCollateralBalance = liquidationInfo.collateralInfo.collateralBalance;

    params.totalCollateralInBaseCurrency = liquidationInfo.userInfo.totalCollateralInBaseCurrency;
    params.totalDebtInBaseCurrency = liquidationInfo.userInfo.totalDebtInBaseCurrency;
    params.healthFactor = liquidationInfo.userInfo.healthFactor;

    params.actualCollateralToLiquidate = liquidationInfo.maxCollateralToLiquidate;
    params.actualDebtToLiquidate = liquidationInfo.maxDebtToLiquidate;

    return params;
  }

  function test_reverts_liquidation_reserveInactive() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.wbtc, false);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveInactive.selector));

    vm.prank(alice);
    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.wbtc, bob, 100e6, false);
  }

  function test_reverts_liquidation_hf_gt_liquidation_threshold() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.weth, 2e18, 2, 0, alice);
    vm.stopPrank();

    vm.expectRevert(abi.encodeWithSelector(Errors.HealthFactorNotBelowThreshold.selector));

    vm.prank(bob);
    contracts.poolProxy.liquidationCall(tokenList.wbtc, tokenList.weth, alice, 100e6, false);
  }

  function test_reverts_liquidation_collateral_not_active() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.weth, 10e18, 2, 0, alice);
    vm.stopPrank();

    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(tokenList.wbtc))
      .sig('_latestAnswer()')
      .checked_write(
        _calcPrice(IAaveOracle(report.aaveOracle).getAssetPrice(tokenList.wbtc), 40_00)
      );

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.wbtc, true, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.CollateralCannotBeLiquidated.selector));

    vm.prank(bob);
    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.weth, alice, 100e6, false);
  }

  function test_reverts_liquidation_invalid_borrow() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.weth, 10e18, 2, 0, alice);
    vm.stopPrank();

    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(tokenList.wbtc))
      .sig('_latestAnswer()')
      .checked_write(
        _calcPrice(IAaveOracle(report.aaveOracle).getAssetPrice(tokenList.wbtc), 40_00)
      );

    vm.expectRevert(abi.encodeWithSelector(Errors.SpecifiedCurrencyNotBorrowedByUser.selector));

    vm.prank(bob);
    contracts.poolProxy.liquidationCall(tokenList.wbtc, tokenList.usdx, alice, 100e6, false);
  }

  function test_reverts_liquidation_reservePaused() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.wbtc, true, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReservePaused.selector));

    vm.prank(alice);
    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.wbtc, bob, 100e6, false);
  }

  function test_liquidation_when_grace_period_disabled(uint40 liquidationGracePeriod) public {
    liquidationGracePeriod = uint40(
      bound(liquidationGracePeriod, 1, contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD())
    );
    address[] memory assetsInGrace = new address[](1);
    assetsInGrace[0] = tokenList.usdx;

    _setLiquidationGracePeriod(assetsInGrace, liquidationGracePeriod);

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1.25e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 22_500e6, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc, // collateral
      tokenList.usdx, // debt
      5_000e6,
      tokenList.wbtc,
      25_00
    );

    vm.startPrank(bob);
    // check that liquidations are not allowed after grace period activation
    vm.expectRevert(abi.encodeWithSelector(Errors.LiquidationGraceSentinelCheckFailed.selector));
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );
    vm.stopPrank();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.disableLiquidationGracePeriod(assetsInGrace[0]);
    vm.stopPrank();

    vm.startPrank(bob);
    // check that liquidations are allowed after grace period disabled
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );
    vm.stopPrank();
  }

  function test_liquidation_with_liquidation_grace_period_collateral_active(
    uint40 liquidationGracePeriod
  ) public {
    liquidationGracePeriod = uint40(
      bound(liquidationGracePeriod, 0, contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD())
    );
    address[] memory assetsInGrace = new address[](1);
    assetsInGrace[0] = tokenList.wbtc;
    _testLiquidationGracePeriod(assetsInGrace, liquidationGracePeriod);
  }

  function test_liquidation_with_liquidation_grace_period_debt_active(
    uint40 liquidationGracePeriod
  ) public {
    liquidationGracePeriod = uint40(
      bound(liquidationGracePeriod, 0, contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD())
    );
    address[] memory assetsInGrace = new address[](1);
    assetsInGrace[0] = tokenList.usdx;
    _testLiquidationGracePeriod(assetsInGrace, liquidationGracePeriod);
  }

  function test_liquidation_with_liquidation_grace_period_debt_collateral_active(
    uint40 liquidationGracePeriod
  ) public {
    liquidationGracePeriod = uint40(
      bound(liquidationGracePeriod, 0, contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD())
    );
    address[] memory assetsInGrace = new address[](2);
    assetsInGrace[0] = tokenList.wbtc;
    assetsInGrace[1] = tokenList.usdx;
    _testLiquidationGracePeriod(assetsInGrace, liquidationGracePeriod);
  }

  function _testLiquidationGracePeriod(
    address[] memory assetsInGrace,
    uint40 liquidationGracePeriod
  ) internal {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1.25e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 22_500e6, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc, // collateral
      tokenList.usdx, // debt
      5_000e6,
      tokenList.wbtc,
      25_00
    );

    vm.startPrank(bob);
    // check that liquidations are allowed before grace period activation
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );
    vm.stopPrank();

    _setLiquidationGracePeriod(assetsInGrace, liquidationGracePeriod);

    vm.startPrank(bob);

    uint40 timestampSnapshot = uint40(vm.getBlockTimestamp());
    if (liquidationGracePeriod != 0) {
      // liquidations are not allowed during grace period
      vm.expectRevert(abi.encodeWithSelector(Errors.LiquidationGraceSentinelCheckFailed.selector));
      contracts.poolProxy.liquidationCall(
        params.collateralAsset,
        params.debtAsset,
        params.user,
        params.liquidationAmountInput,
        params.receiveAToken
      );

      // liquidations are not allowed at the grace period timestamp
      vm.warp(timestampSnapshot + liquidationGracePeriod);
      vm.expectRevert(abi.encodeWithSelector(Errors.LiquidationGraceSentinelCheckFailed.selector));
      contracts.poolProxy.liquidationCall(
        params.collateralAsset,
        params.debtAsset,
        params.user,
        params.liquidationAmountInput,
        params.receiveAToken
      );

      // liquidations allowed again when grace period ends
      vm.warp(timestampSnapshot + liquidationGracePeriod + 1);
      contracts.poolProxy.liquidationCall(
        params.collateralAsset,
        params.debtAsset,
        params.user,
        params.liquidationAmountInput,
        params.receiveAToken
      );
    } else {
      // liquidations are allowed if 0 was passed as grace period
      contracts.poolProxy.liquidationCall(
        params.collateralAsset,
        params.debtAsset,
        params.user,
        params.liquidationAmountInput,
        params.receiveAToken
      );
    }
    vm.stopPrank();
  }

  function _afterLiquidationChecksVariable(
    LiquidationInput memory params,
    address liquidator,
    uint256 liquidatorBalanceBefore,
    uint256
  ) internal view {
    address aToken = contracts.poolProxy.getReserveAToken(params.collateralAsset);
    if (params.receiveAToken) {
      assertEq(
        IERC20(aToken).balanceOf(liquidator),
        liquidatorBalanceBefore + params.actualCollateralToLiquidate,
        'liquidator balance doesnt match'
      );
    } else {
      assertEq(
        IERC20(params.collateralAsset).balanceOf(liquidator),
        liquidatorBalanceBefore + params.actualCollateralToLiquidate,
        'liquidator balance doesnt match'
      );
    }
    (
      params.totalCollateralInBaseCurrency,
      params.totalDebtInBaseCurrency,
      ,
      ,
      ,
      params.healthFactor
    ) = contracts.poolProxy.getUserAccountData(params.user);
    if (params.totalCollateralInBaseCurrency == 0) {
      require(
        !contracts.poolProxy.getUserConfiguration(params.user).isBorrowingAny(),
        'BAD_DEBT_MUST_BE_CLEARED'
      );
    }
  }

  function _setLiquidationGracePeriod(address[] memory assets, uint40 gracePeriod) internal {
    vm.startPrank(poolAdmin);
    for (uint256 i = 0; i < assets.length; i++) {
      contracts.poolConfiguratorProxy.setReservePause(assets[i], false, gracePeriod);
    }
    vm.stopPrank();
  }

  // Regression test for L-08: Collateral bit may remain set after collateral is fully consumed
  // due to rayDivCeil rounding in scaled domain consuming all shares while the unscaled equality
  // check fails to detect full consumption.
  //
  // Setup:
  //   scaledBalance = 3, liquidityIndex = 1.5e27
  //   borrowerCollateralBalance = rayMulFloor(3, 1.5e27) = floor(4.5) = 4
  //   debt = 3 (full repayment, so dust check is skipped)
  //   With 5% bonus and 100% protocol fee:
  //     maxCollateralToLiquidate = floor(3 * 1.05) = 3
  //     actualCollateralToLiquidate = 2, fee = 1
  //     Unscaled check: 2 + 1 = 3 != 4 => collateral bit NOT cleared
  //   But in scaled domain:
  //     rayDivCeil(2, 1.5e27) = 2, rayDivCeil(1, 1.5e27) = 1 => total = 3 = scaledBalance
  //     All scaled shares consumed, yet collateral bit remains set.
  function test_collateral_bit_remains_after_full_scaled_consumption() public {
    // Configure USDX with low liquidation threshold so small debt makes HF < 1
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      tokenList.usdx,
      40_00, // ltv (40%)
      50_00, // liquidation threshold (50%)
      105_00 // liquidation bonus (5%)
    );
    // 100% protocol fee: all bonus goes to treasury
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 100_00);
    vm.stopPrank();

    // Alice supplies 3 units USDX (scaledBalance = 3 at initial index 1.0e27)
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 3, alice, 0);
    // Borrow 1 unit (within 40% LTV of 3)
    contracts.poolProxy.borrow(tokenList.usdx, 1, 2, 0, alice);
    vm.stopPrank();

    // Manipulate indexes:
    //   liquidityIndex = 1.5e27 => collateral = floor(3 * 1.5) = 4
    //   variableBorrowIndex = 3e27 => debt = ceil(1 * 3) = 3
    //   HF = 4 * 50% / 3 = 0.667 < 1 (liquidatable)
    AaveSetters.setLiquidityIndex(address(contracts.poolProxy), tokenList.usdx, 1.5e27);
    AaveSetters.setVariableBorrowIndex(address(contracts.poolProxy), tokenList.usdx, 3e27);
    AaveSetters.setLastUpdateTimestamp(
      address(contracts.poolProxy),
      tokenList.usdx,
      uint40(block.timestamp)
    );

    address aToken = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );

    // Verify pre-conditions
    assertEq(IAToken(aToken).scaledBalanceOf(alice), 3, 'pre: scaled balance should be 3');
    assertTrue(
      contracts.poolProxy.getUserConfiguration(alice).isUsingAsCollateral(reserveData.id),
      'pre: should be using USDX as collateral'
    );

    // Bob liquidates alice's full debt
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      tokenList.usdx, // collateral
      tokenList.usdx, // debt
      alice,
      type(uint256).max,
      false
    );

    // After liquidation: scaled balance is 0 (all shares consumed by rounding)
    assertEq(
      IAToken(aToken).scaledBalanceOf(alice),
      0,
      'post: scaled balance should be 0 after liquidation'
    );

    // After fix: collateral bit should be cleared by the post-transfer scaled balance check
    DataTypes.UserConfigurationMap memory configAfter = contracts.poolProxy.getUserConfiguration(
      alice
    );
    assertFalse(
      configAfter.isUsingAsCollateral(reserveData.id),
      'collateral bit should be cleared when scaled balance is zero'
    );
  }

  // Regression: `hasNoCollateralLeft` must account for ceil rounding in burn/transfer
  // paths that can fully deplete the scaled balance even when unscaled arithmetic
  // predicts a leftover. When the position is fully consumed, the bad-debt path
  // must fire so remaining debt is converted to deficit.
  function test_hasNoCollateralLeft_accounts_for_ceil_rounding_single_debt() public {
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      tokenList.usdx,
      80_00, // ltv (80%)
      85_00, // liquidation threshold (85%)
      105_00 // liquidation bonus (5%)
    );
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 10_00);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 3, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 2, 2, 0, alice);
    vm.stopPrank();

    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(tokenList.usdx))
      .sig('_latestAnswer()')
      .checked_write(1e17);

    AaveSetters.setLiquidityIndex(address(contracts.poolProxy), tokenList.usdx, 1.5e27);
    AaveSetters.setVariableBorrowIndex(address(contracts.poolProxy), tokenList.usdx, 2.5e27);
    AaveSetters.setLastUpdateTimestamp(
      address(contracts.poolProxy),
      tokenList.usdx,
      uint40(block.timestamp)
    );

    address aToken = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(tokenList.usdx);

    assertEq(IAToken(aToken).scaledBalanceOf(alice), 3, 'pre: scaled collateral should be 3');
    assertGt(IERC20(varDebtToken).balanceOf(alice), 0, 'pre: debt should be non-zero');

    vm.prank(bob);
    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.usdx, alice, 3, false);

    assertEq(IAToken(aToken).scaledBalanceOf(alice), 0, 'post: scaled collateral should be 0');
    assertEq(
      IERC20(varDebtToken).balanceOf(alice),
      0,
      'post: all debt should be burned (bad debt path should have fired)'
    );
    assertGt(
      contracts.poolProxy.getReserveDeficit(tokenList.usdx),
      0,
      'post: deficit should be created for the outstanding debt'
    );
  }

  // Regression: scaledCollateralConsumed can exceed scaledBalance when the two
  // rayDivCeil operations (liquidator + fee) independently round up beyond the
  // original scaled balance. The >= check must catch this.
  // Here: scaledBalance=2, index=3e27, actual=4, fee=1 → rayDivCeil(4,3e27)+rayDivCeil(1,3e27) = 2+1 = 3 > 2
  function test_hasNoCollateralLeft_accounts_for_ceil_rounding_sum_exceeds_scaled() public {
    // Target state: scaledCollateral=2, scaledDebt=1, liqIndex=5e27, borrowIndex=9e27
    // → balance = rayMulFloor(2, 5e27) = 10
    // → debt = rayMulCeil(1, 9e27) = 9
    // → maxCollateral = floor(9*1.05) = 9, bonusCollateral = 9-floor(9*10000/10500) = 9-8 = 1
    // → fee = percentMulCeil(1, 1000) = 1, actual = 9-1 = 8, leftover = 10-9 = 1
    // → rayDivCeil(8, 5e27) = ceil(8/5) = 2, rayDivCeil(1, 5e27) = ceil(1/5) = 1
    // → scaledConsumed = 3 > scaledBalance = 2
    _supplyAndEnableAsCollateral(tokenList.usdx, 2, alice);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 1, 2, 0, alice);

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      tokenList.usdx,
      80_00,
      85_00,
      105_00
    );
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 10_00);
    vm.stopPrank();

    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(tokenList.usdx))
      .sig('_latestAnswer()')
      .checked_write(1e17);

    AaveSetters.setLiquidityIndex(address(contracts.poolProxy), tokenList.usdx, 5e27);
    AaveSetters.setVariableBorrowIndex(address(contracts.poolProxy), tokenList.usdx, 9e27);
    AaveSetters.setLastUpdateTimestamp(
      address(contracts.poolProxy),
      tokenList.usdx,
      uint40(block.timestamp)
    );

    address aToken = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    address varDebtToken = contracts.poolProxy.getReserveVariableDebtToken(tokenList.usdx);

    assertEq(IAToken(aToken).scaledBalanceOf(alice), 2, 'pre: scaled collateral should be 2');
    assertEq(IERC20(varDebtToken).balanceOf(alice), 9, 'pre: debt should be 9');

    vm.prank(bob);
    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.usdx, alice, 9, false);

    assertEq(IAToken(aToken).scaledBalanceOf(alice), 0, 'post: scaled collateral should be 0');
    assertEq(IERC20(varDebtToken).balanceOf(alice), 0, 'post: debt should be fully repaid');
    assertFalse(
      contracts.poolProxy.getUserConfiguration(alice).isUsingAsCollateral(
        contracts.poolProxy.getReserveData(tokenList.usdx).id
      ),
      'post: collateral bit should be cleared despite scaledConsumed > scaledBalance'
    );
  }

  // Regression: when ceil rounding depletes a user's only collateral and they have
  // debt in a second reserve, _burnBadDebt must run so that debt is also handled.
  function test_hasNoCollateralLeft_accounts_for_ceil_rounding_multi_debt() public {
    IPool pool = contracts.poolProxy;
    address collateralAsset = tokenList.usdx;
    address secondDebtAsset = tokenList.weth;
    uint16 reserveId = pool.getReserveData(collateralAsset).id;

    {
      uint256 collateralSupply = 5;
      uint256 liquidityIndex = 1.3e27;
      uint256 variableBorrowIndex = 1.5e27;
      uint256 firstDebtBeforeIndexUpdate = 3;
      uint256 firstDebtAfterIndexUpdate = 5;
      uint256 residualWethDebt = 555_555_556;

      _supplyAndEnableAsCollateral(collateralAsset, collateralSupply, alice);

      vm.startPrank(alice);
      pool.borrow(collateralAsset, firstDebtBeforeIndexUpdate, 2, 0, alice);
      pool.borrow(secondDebtAsset, residualWethDebt, 2, 0, alice);
      vm.stopPrank();

      vm.startPrank(poolAdmin);
      contracts.poolConfiguratorProxy.configureReserveAsCollateral(
        collateralAsset,
        40_00,
        50_00,
        105_00
      );
      contracts.poolConfiguratorProxy.setLiquidationProtocolFee(collateralAsset, 100_00);
      vm.stopPrank();

      AaveSetters.setLiquidityIndex(address(pool), collateralAsset, liquidityIndex);
      AaveSetters.setVariableBorrowIndex(address(pool), collateralAsset, variableBorrowIndex);
      AaveSetters.setLastUpdateTimestamp(address(pool), collateralAsset, uint40(block.timestamp));

      deal(collateralAsset, bob, firstDebtAfterIndexUpdate);
      vm.prank(bob);
      IERC20(collateralAsset).approve(address(pool), type(uint256).max);

      vm.prank(bob);
      pool.liquidationCall(collateralAsset, collateralAsset, alice, type(uint256).max, false);
    }

    address aToken = pool.getReserveAToken(collateralAsset);
    address secondDebtToken = pool.getReserveVariableDebtToken(secondDebtAsset);

    assertEq(IAToken(aToken).scaledBalanceOf(alice), 0, 'post: scaled collateral should be 0');
    assertFalse(
      pool.getUserConfiguration(alice).isUsingAsCollateral(reserveId),
      'post: collateral bit should be cleared'
    );
    assertEq(
      IERC20(secondDebtToken).balanceOf(alice),
      0,
      'post: second reserve debt should be burned via _burnBadDebt'
    );
    assertGt(
      pool.getReserveDeficit(secondDebtAsset),
      0,
      'post: deficit should be created for the second reserve debt'
    );
  }

  // Regression: 3 wei of WETH dust leftover rounds to $0 in base currency.
  // The leftoverWorthless check catches this and fires _burnBadDebt for the secondary WETH debt.
  function test_weth_dust_leftover_rounds_to_zero_in_base_currency() public {
    IPool pool = contracts.poolProxy;
    address collateralAsset = tokenList.weth;
    address debtAsset = tokenList.usdx;

    uint256 wethSupply = 0.525e18 + 3;

    _supplyAndEnableAsCollateral(collateralAsset, wethSupply, alice);

    vm.startPrank(alice);
    pool.borrow(debtAsset, 360e6, 2, 0, alice);
    pool.borrow(collateralAsset, 1e12, 2, 0, alice);
    vm.stopPrank();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      collateralAsset,
      80_00,
      85_00,
      105_00
    );
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(collateralAsset, 10_00);
    vm.stopPrank();

    AaveSetters.setVariableBorrowIndex(address(pool), debtAsset, 2.5e27);
    AaveSetters.setLiquidityIndex(address(pool), debtAsset, 1e27);
    AaveSetters.setLastUpdateTimestamp(address(pool), debtAsset, uint40(block.timestamp));
    AaveSetters.setLastUpdateTimestamp(address(pool), collateralAsset, uint40(block.timestamp));

    address aToken = pool.getReserveAToken(collateralAsset);
    address debtToken = pool.getReserveVariableDebtToken(debtAsset);
    address wethDebtToken = pool.getReserveVariableDebtToken(collateralAsset);

    assertEq(IERC20(debtToken).balanceOf(alice), 900e6, 'pre: USDX debt should be 900');
    assertGt(IERC20(wethDebtToken).balanceOf(alice), 0, 'pre: WETH debt should exist');

    vm.prank(bob);
    pool.liquidationCall(collateralAsset, debtAsset, alice, type(uint256).max, false);

    assertEq(IERC20(debtToken).balanceOf(alice), 0, 'post: USDX debt should be fully repaid');

    assertFalse(
      pool.getUserConfiguration(alice).isUsingAsCollateral(pool.getReserveData(collateralAsset).id),
      'post: collateral bit should be cleared (leftover worthless)'
    );

    assertGt(
      pool.getReserveDeficit(collateralAsset),
      0,
      'post: WETH deficit should be created via _burnBadDebt'
    );
  }
}
