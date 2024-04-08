// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IStableDebtToken} from 'aave-v3-core/contracts/interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from 'aave-v3-core/contracts/interfaces/IVariableDebtToken.sol';
import {IAaveOracle} from 'aave-v3-core/contracts/interfaces/IAaveOracle.sol';
import {IPoolAddressesProvider} from 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IAToken} from 'aave-v3-core/contracts/interfaces/IAToken.sol';
import {Errors} from 'aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {ReserveLogic, IERC20} from 'aave-v3-core/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {ReserveConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {PriceOracleSentinel} from 'aave-v3-core/contracts/protocol/configuration/PriceOracleSentinel.sol';
import {SequencerOracle, ISequencerOracle} from 'aave-v3-core/contracts/mocks/oracle/SequencerOracle.sol';
import {MockAggregator} from 'aave-v3-core/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {LiquidationLogic} from 'aave-v3-core/contracts/protocol/libraries/logic/LiquidationLogic.sol';
import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from 'aave-v3-core/contracts/protocol/libraries/math/PercentageMath.sol';
import {WadRayMath} from 'aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract PoolLiquidationTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using PercentageMath for uint256;
  using WadRayMath for uint256;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;

  IStableDebtToken internal staDebtUSDX;
  IVariableDebtToken internal varDebtUSDX;
  address internal aUSDX;

  PriceOracleSentinel internal priceOracleSentinel;
  SequencerOracle internal sequencerOracleMock;

  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);
  DataTypes.ReserveData internal collateralReserveData;
  DataTypes.ReserveData internal debtReserveData;

  function setUp() public {
    initTestEnvironment();

    (address atoken, address stableDebtUSDX, address variableDebtUSDX) = contracts
      .protocolDataProvider
      .getReserveTokensAddresses(tokenList.usdx);
    aUSDX = atoken;
    staDebtUSDX = IStableDebtToken(stableDebtUSDX);
    varDebtUSDX = IVariableDebtToken(variableDebtUSDX);

    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);
    contracts.poolProxy.supply(tokenList.weth, 100e18, carol, 0);
    vm.stopPrank();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveStableRateBorrowing(tokenList.usdx, true);

    sequencerOracleMock = new SequencerOracle(poolAdmin);
    priceOracleSentinel = new PriceOracleSentinel(
      IPoolAddressesProvider(report.poolAddressesProvider),
      ISequencerOracle(address(sequencerOracleMock)),
      1 days
    );

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(false, 0);
  }

  struct LiquidationInput {
    address collateralAsset;
    address user;
    address debtAsset;
    uint256 actualDebtToLiquidate;
    uint256 actualCollateralToLiquidate;
    bool receiveAToken;
    uint256 liquidationAmountInput;
    address collateralPriceSource;
    address debtPriceSource;
    uint256 liquidationBonus;
    uint256 userCollateralBalance;
    DataTypes.ReserveCache debtCache;
    uint256 priceImpactPercent;
    uint256 liquidationProtocolFeeAmount;
  }

  function test_liquidate_variable_borrow_same_collateral_and_borrow() public {
    uint256 amount = 2000e6;
    uint256 borrowAmount = 1620e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    vm.warp(block.timestamp + 20000 days);

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
      (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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
  }

  function test_liquidate_variable_borrow() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 23_33);
    uint256 amount = 1.00999999e8;
    uint256 borrowAmount = 20500.999999e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.warp(block.timestamp + 30 days);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.002e8, 2, 0, alice);
    vm.stopPrank();

    vm.warp(block.timestamp + 30 days);

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      25_00
    );

    (, , address varDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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
      25_00
    );

    (, , address varDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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

    (, , address varDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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

    (, , address varDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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
      (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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
    emit LiquidationLogic.LiquidationCall(
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
    (, , address variableDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    (address atokenAddress, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.collateralAsset
    );

    assertEq(IERC20(atokenAddress).balanceOf(bob), params.actualCollateralToLiquidate);
    assertEq(IERC20(variableDebtToken).balanceOf(params.user), 0);
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
    (, , address varDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      (address atokenAddress, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atokenAddress).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }
    uint256 variableDebtBefore = IERC20(varDebtToken).balanceOf(params.user);

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.ReserveUsedAsCollateralDisabled(params.collateralAsset, params.user);

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.ReserveUsedAsCollateralEnabled(params.collateralAsset, bob);

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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

    (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.collateralAsset
    );
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
  }

  function test_liquidate_isolated_position() public {
    uint256 borrowAmount = 11000e6;
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 12_000_00);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

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
      25_00
    );

    (, , address varDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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
  }

  function test_liquidate_emode_position_without_emode_oracle() public {
    EModeCategoryInput memory ct = _genCategoryOne();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      ct.oracle,
      ct.label
    );
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.wbtc, ct.id);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.weth, ct.id);
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
      25_00
    );

    (, , address varDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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
  }

  function test_liquidate_emode_position_with_emode_oracle() public {
    EModeCategoryInput memory ct = _genCategoryOne();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(
      ct.id,
      ct.ltv,
      ct.lt,
      ct.lb,
      tokenList.wbtc,
      ct.label
    );
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.wbtc, ct.id);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(tokenList.weth, ct.id);
    vm.stopPrank();

    uint256 amount = 1e8;
    uint256 borrowAmount = 0.94e18;

    vm.startPrank(alice);
    contracts.poolProxy.setUserEMode(ct.id);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.weth, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    vm.warp(block.timestamp + 20000 days);

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.weth,
      UINT256_MAX,
      tokenList.wbtc,
      0
    );
    (, , address varDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    uint256 userDebtBefore = IERC20(varDebtToken).balanceOf(params.user);
    uint256 liquidatorBalanceBefore;
    if (params.receiveAToken) {
      (address atoken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
        params.collateralAsset
      );
      liquidatorBalanceBefore = IERC20(atoken).balanceOf(bob);
    } else {
      liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);
    }

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
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
    (
      params.liquidationBonus,
      params.collateralPriceSource,
      params.debtPriceSource
    ) = _getLiquidationBonus(params.user, params.collateralAsset, params.debtAsset);
    params.receiveAToken = false;
    (address aToken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.collateralAsset
    );
    params.userCollateralBalance = IAToken(aToken).balanceOf(params.user);
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

    (, , , , , uint256 healthFactor) = contracts.poolProxy.getUserAccountData(params.user);

    (, , uint256 currentVariableDebt, , , , , , ) = contracts
      .protocolDataProvider
      .getUserReserveData(params.debtAsset, params.user);

    uint256 closeFactor = healthFactor > LiquidationLogic.CLOSE_FACTOR_HF_THRESHOLD
      ? LiquidationLogic.DEFAULT_LIQUIDATION_CLOSE_FACTOR
      : LiquidationLogic.MAX_LIQUIDATION_CLOSE_FACTOR;

    uint256 maxLiquidatableDebt = (currentVariableDebt).percentMul(closeFactor);

    params.actualDebtToLiquidate = params.liquidationAmountInput > maxLiquidatableDebt
      ? maxLiquidatableDebt
      : params.liquidationAmountInput;

    collateralReserveData = _getReserveData(params.collateralAsset);
    debtReserveData = _getReserveData(params.debtAsset);

    params.debtCache = debtReserveData.cache();

    (
      params.actualCollateralToLiquidate,
      params.actualDebtToLiquidate,
      params.liquidationProtocolFeeAmount
    ) = LiquidationLogic._calculateAvailableCollateralToLiquidate(
      collateralReserveData,
      params.debtCache,
      params.collateralPriceSource,
      params.debtPriceSource,
      params.actualDebtToLiquidate,
      params.userCollateralBalance,
      params.liquidationBonus,
      IAaveOracle(report.aaveOracle)
    );
    return params;
  }

  function test_reverts_liquidation_oracle_sentinel_on() public {
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 50e8, alice, 0);

    vm.prank(poolAdmin);
    IPoolAddressesProvider(report.poolAddressesProvider).setPriceOracleSentinel(
      address(priceOracleSentinel)
    );

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(true, 0);

    assertEq(priceOracleSentinel.isLiquidationAllowed(), false);
    vm.expectRevert(bytes(Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED));

    vm.prank(alice);
    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.wbtc, bob, 100e6, false);
  }

  function test_reverts_liquidation_reserveInactive() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.wbtc, false);

    vm.expectRevert(bytes(Errors.RESERVE_INACTIVE));

    vm.prank(alice);
    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.wbtc, bob, 100e6, false);
  }

  function test_reverts_liquidation_hf_gt_liquidation_threshold() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.weth, 2e18, 2, 0, alice);
    vm.stopPrank();

    vm.expectRevert(bytes(Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD));

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

    vm.expectRevert(bytes(Errors.COLLATERAL_CANNOT_BE_LIQUIDATED));

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

    vm.expectRevert(bytes(Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER));

    vm.prank(bob);
    contracts.poolProxy.liquidationCall(tokenList.wbtc, tokenList.usdx, alice, 100e6, false);
  }

  function test_reverts_liquidation_reservePaused() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.wbtc, true, 0);

    vm.expectRevert(bytes(Errors.RESERVE_PAUSED));

    vm.prank(alice);
    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.wbtc, bob, 100e6, false);
  }

  function test_liquidation_with_liquidation_grace_period_collateral_active(
    uint40 liquidationGracePeriod
  ) public {
    vm.assume(liquidationGracePeriod <= contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD());
    address[] memory assetsInGrace = new address[](1);
    assetsInGrace[0] = tokenList.wbtc;
    _testLiquidationGracePeriod(assetsInGrace, liquidationGracePeriod);
  }

  function test_liquidation_with_liquidation_grace_period_debt_active(
    uint40 liquidationGracePeriod
  ) public {
    vm.assume(liquidationGracePeriod <= contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD());
    address[] memory assetsInGrace = new address[](1);
    assetsInGrace[0] = tokenList.usdx;
    _testLiquidationGracePeriod(assetsInGrace, liquidationGracePeriod);
  }

  function test_liquidation_with_liquidation_grace_period_debt_collateral_active(
    uint40 liquidationGracePeriod
  ) public {
    vm.assume(liquidationGracePeriod <= contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD());
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

    uint40 timestampSnapshot = uint40(block.timestamp);
    if (liquidationGracePeriod != 0) {
      // liquidations are not allowed during grace period
      vm.expectRevert(bytes(Errors.LIQUIDATION_GRACE_SENTINEL_CHECK_FAILED));
      contracts.poolProxy.liquidationCall(
        params.collateralAsset,
        params.debtAsset,
        params.user,
        params.liquidationAmountInput,
        params.receiveAToken
      );

      // liquidations are not allowed at the grace period timestamp
      vm.warp(timestampSnapshot + liquidationGracePeriod);
      vm.expectRevert(bytes(Errors.LIQUIDATION_GRACE_SENTINEL_CHECK_FAILED));
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

  function _getLiquidationBonus(
    address user,
    address collateralAsset,
    address debtAsset
  ) internal view returns (uint256, address, address) {
    uint256 id = contracts.poolProxy.getUserEMode(user);
    if (id != 0) {
      DataTypes.EModeCategory memory cat = contracts.poolProxy.getEModeCategoryData(uint8(id));
      if (cat.priceSource != address(0)) {
        return (cat.liquidationBonus, cat.priceSource, cat.priceSource);
      } else {
        return (cat.liquidationBonus, collateralAsset, debtAsset);
      }
    } else {
      DataTypes.ReserveConfigurationMap memory conf = contracts.poolProxy.getConfiguration(
        debtAsset
      );
      return (conf.getLiquidationBonus(), collateralAsset, debtAsset);
    }
  }

  function _afterLiquidationChecksVariable(
    LiquidationInput memory params,
    address liquidator,
    uint256 liquidatorBalanceBefore,
    uint256 userBalanceBefore
  ) internal view {
    (address collateralBalance, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.collateralAsset
    );
    (, , address variableDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );
    if (params.receiveAToken) {
      assertEq(
        IERC20(collateralBalance).balanceOf(liquidator),
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
    assertApproxEqAbs(
      IERC20(variableDebtToken).balanceOf(params.user),
      userBalanceBefore - params.actualDebtToLiquidate,
      1,
      'user balance doesnt match'
    );
  }

  function _getReserveData(address asset) internal view returns (DataTypes.ReserveData memory) {
    DataTypes.ReserveDataLegacy memory reserveDataLegacy = contracts.poolProxy.getReserveData(
      asset
    );
    DataTypes.ReserveData memory tempReserveData;
    tempReserveData.configuration = reserveDataLegacy.configuration;
    tempReserveData.liquidityIndex = reserveDataLegacy.liquidityIndex;
    tempReserveData.currentLiquidityRate = reserveDataLegacy.currentLiquidityRate;
    tempReserveData.variableBorrowIndex = reserveDataLegacy.variableBorrowIndex;
    tempReserveData.currentVariableBorrowRate = reserveDataLegacy.currentVariableBorrowRate;
    tempReserveData.currentStableBorrowRate = reserveDataLegacy.currentStableBorrowRate;
    tempReserveData.lastUpdateTimestamp = reserveDataLegacy.lastUpdateTimestamp;
    tempReserveData.id = reserveDataLegacy.id;
    tempReserveData.aTokenAddress = reserveDataLegacy.aTokenAddress;
    tempReserveData.stableDebtTokenAddress = reserveDataLegacy.stableDebtTokenAddress;
    tempReserveData.variableDebtTokenAddress = reserveDataLegacy.variableDebtTokenAddress;
    tempReserveData.interestRateStrategyAddress = reserveDataLegacy.interestRateStrategyAddress;
    tempReserveData.accruedToTreasury = reserveDataLegacy.accruedToTreasury;
    tempReserveData.unbacked = reserveDataLegacy.unbacked;
    tempReserveData.isolationModeTotalDebt = reserveDataLegacy.isolationModeTotalDebt;
    tempReserveData.virtualUnderlyingBalance = uint128(
      contracts.poolProxy.getVirtualUnderlyingBalance(asset)
    );
    return tempReserveData;
  }

  function _setLiquidationGracePeriod(address[] memory assets, uint40 gracePeriod) internal {
    vm.startPrank(poolAdmin);
    for (uint256 i = 0; i < assets.length; i++) {
      contracts.poolConfiguratorProxy.setReservePause(assets[i], false, gracePeriod);
    }
    vm.stopPrank();
  }
}
