// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IReserveInterestRateStrategy} from '../../../src/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {ISequencerOracle} from '../../../src/contracts/interfaces/ISequencerOracle.sol';
import {UserConfiguration} from '../../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {PriceOracleSentinel} from '../../../src/contracts/misc/PriceOracleSentinel.sol';
import {SequencerOracle} from '../../../src/contracts/mocks/oracle/SequencerOracle.sol';
import {MockAggregator} from '../../../src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IERC20} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract PoolBorrowTests is TestnetProcedures {
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  IVariableDebtToken internal varDebtUSDX;
  address internal aUSDX;

  PriceOracleSentinel internal priceOracleSentinel;
  SequencerOracle internal sequencerOracleMock;

  function setUp() public {
    initTestEnvironment();

    (address atoken, , address variableDebtUSDX) = contracts
      .protocolDataProvider
      .getReserveTokensAddresses(tokenList.usdx);
    aUSDX = atoken;
    varDebtUSDX = IVariableDebtToken(variableDebtUSDX);

    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);
    vm.stopPrank();

    sequencerOracleMock = new SequencerOracle(poolAdmin);
    priceOracleSentinel = new PriceOracleSentinel(
      IPoolAddressesProvider(report.poolAddressesProvider),
      ISequencerOracle(address(sequencerOracleMock)),
      1 days
    );

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(false, 0);
  }

  function test_variable_borrow() public {
    uint256 amount = 2000e6;
    uint256 borrowAmount = 800e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);

    uint256 balanceBefore = usdx.balanceOf(alice);
    uint256 debtBalanceBefore = varDebtUSDX.scaledBalanceOf(alice);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    IReserveInterestRateStrategy rateStrategy = IReserveInterestRateStrategy(
      reserveData.interestRateStrategyAddress
    );

    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 800e6,
      totalDebt: 800e6,
      reserveFactor: 1000,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: contracts.poolProxy.getVirtualUnderlyingBalance(tokenList.usdx)
    });

    (, uint256 expectedVariableBorrowRate) = rateStrategy.calculateInterestRates(input);

    vm.expectEmit(true, true, true, true, address(contracts.poolProxy));
    emit IPool.Borrow(
      tokenList.usdx,
      alice,
      alice,
      borrowAmount,
      DataTypes.InterestRateMode.VARIABLE,
      expectedVariableBorrowRate,
      0
    );

    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    uint256 balanceAfter = usdx.balanceOf(alice);
    uint256 debtBalanceAfter = varDebtUSDX.scaledBalanceOf(alice);

    assertEq(balanceAfter, balanceBefore + borrowAmount);
    assertEq(debtBalanceAfter, debtBalanceBefore + borrowAmount);
    assertEq(contracts.poolProxy.getUserConfiguration(alice).isBorrowing(reserveData.id), true);

    _checkInterestRates(tokenList.usdx);
  }

  function test_borrow_variable_in_isolation() public {
    uint256 borrowAmount = 100e6;
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000_00);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    uint256 balanceBefore = usdx.balanceOf(alice);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    IReserveInterestRateStrategy rateStrategy = IReserveInterestRateStrategy(
      reserveData.interestRateStrategyAddress
    );

    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: borrowAmount,
      totalDebt: borrowAmount,
      reserveFactor: 1000,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: contracts.poolProxy.getVirtualUnderlyingBalance(tokenList.usdx)
    });

    (, uint256 expectedVariableBorrowRate) = rateStrategy.calculateInterestRates(input);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.IsolationModeTotalDebtUpdated(tokenList.wbtc, 100_00);
    vm.expectEmit(true, true, true, true, address(contracts.poolProxy));
    emit IPool.Borrow(
      tokenList.usdx,
      alice,
      alice,
      borrowAmount,
      DataTypes.InterestRateMode.VARIABLE,
      expectedVariableBorrowRate,
      0
    );

    // Perform borrow in isolated position
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    uint256 balanceAfter = usdx.balanceOf(alice);
    uint256 debtBalanceAfter = varDebtUSDX.scaledBalanceOf(alice);

    assertEq(balanceAfter, balanceBefore + borrowAmount);
    assertEq(debtBalanceAfter, borrowAmount);
    assertEq(contracts.poolProxy.getUserConfiguration(alice).isBorrowing(reserveData.id), true);

    _checkInterestRates(tokenList.usdx);
  }

  function test_reverts_variable_borrow_transferred_funds() public {
    uint256 collateralAmount = 5 ether;
    uint256 borrowAmount = 800e6;

    vm.startPrank(carol);
    contracts.poolProxy.withdraw(tokenList.usdx, type(uint256).max, carol);
    assertEq(IERC20(aUSDX).totalSupply(), 0);
    vm.stopPrank();

    vm.startPrank(alice);

    // Transfer debt token
    usdx.transfer(aUSDX, borrowAmount);

    // Supply
    contracts.poolProxy.supply(tokenList.weth, collateralAmount, alice, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAmount.selector));
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
  }

  function test_reverts_deprecated_stable_borrow() public {
    uint256 amount = 2000e6;
    uint256 borrowAmount = 100;
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.supply(tokenList.wbtc, borrowAmount, bob, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInterestRateModeSelected.selector));

    contracts.poolProxy.borrow(tokenList.wbtc, borrowAmount, 1, 0, alice);
  }

  function test_reverts_borrow_invalidAmount() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAmount.selector));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 0, 2, 0, alice);
  }

  function test_reverts_borrow_reserveInactive() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.wbtc, false);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveInactive.selector));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 2, 0, alice);
  }

  function test_reverts_borrow_reservePaused() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.wbtc, true, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReservePaused.selector));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 2, 0, alice);
  }

  function test_reverts_borrow_reserveFrozen() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.wbtc, true);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveFrozen.selector));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 2, 0, alice);
  }

  function test_reverts_borrow_cap() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 50e8, alice, 0);
    vm.stopPrank();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setBorrowCap(tokenList.wbtc, 1);

    vm.expectRevert(abi.encodeWithSelector(Errors.BorrowCapExceeded.selector));

    contracts.poolProxy.borrow(tokenList.wbtc, 10e8, 2, 0, alice);
  }

  function test_reverts_borrow_sentinel_oracle_down() public {
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 50e8, alice, 0);

    vm.prank(poolAdmin);
    IPoolAddressesProvider(report.poolAddressesProvider).setPriceOracleSentinel(
      address(priceOracleSentinel)
    );

    vm.prank(poolAdmin);
    sequencerOracleMock.setAnswer(true, 0);

    assertEq(priceOracleSentinel.isBorrowAllowed(), false);
    vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracleSentinelCheckFailed.selector));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 100, 2, 0, alice);
  }

  function test_reverts_borrow_not_borrowable_isolation() public {
    uint256 borrowAmount = 100e6;
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000_00);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    // Perform borrow in isolated position
    vm.expectRevert(abi.encodeWithSelector(Errors.AssetNotBorrowableInIsolation.selector));
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_borrow_DebtCeilingExceeded() public {
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000_00);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    // Perform borrow in isolated position
    vm.expectRevert(abi.encodeWithSelector(Errors.DebtCeilingExceeded.selector));
    contracts.poolProxy.borrow(tokenList.usdx, 10001e6, 2, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_borrow_InconsistentEModeCategory() public {
    EModeCategoryInput memory ct = _genCategoryOne();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct.id, true);
    vm.stopPrank();

    vm.startPrank(alice);

    contracts.poolProxy.setUserEMode(ct.id);

    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.NotBorrowableInEMode.selector));
    contracts.poolProxy.borrow(tokenList.usdx, 10001e6, 2, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_borrow_collateral_balance_zero() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.LtvValidationFailed.selector));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 0.2e8, 2, 0, alice);
  }

  function test_reverts_borrow_collateral_can_not_cover() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.CollateralCannotCoverNewBorrow.selector));
    contracts.poolProxy.borrow(tokenList.usdx, 23000e6, 2, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_borrow_hf_lt_1() public {
    address[] memory assets = new address[](1);
    address[] memory sources = new address[](1);
    assets[0] = tokenList.wbtc;
    sources[0] = address(
      new MockAggregator(int256(IAaveOracle(report.aaveOracle).getAssetPrice(tokenList.wbtc)) / 4)
    );

    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 18001e6, 2, 0, alice);

    vm.stopPrank();

    vm.prank(poolAdmin);
    IAaveOracle(report.aaveOracle).setAssetSources(assets, sources);

    vm.expectRevert(
      abi.encodeWithSelector(Errors.HealthFactorLowerThanLiquidationThreshold.selector)
    );

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 10001e6, 2, 0, alice);
  }

  function test_reverts_borrow_sioled_borrowing_violation() public {
    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.wbtc, 100e8, carol, 0);
    contracts.poolProxy.supply(tokenList.weth, 100e18, carol, 0);
    vm.stopPrank();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setSiloedBorrowing(tokenList.wbtc, true);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.weth, 10e18, alice, 0);

    // Perform siloed borrow
    contracts.poolProxy.borrow(tokenList.wbtc, 0.01e8, 2, 0, alice);

    vm.expectRevert(abi.encodeWithSelector(Errors.SiloedBorrowingViolation.selector));
    contracts.poolProxy.borrow(tokenList.weth, 1e18, 2, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_borrow_debt_ceiling() public {
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000_00);
    vm.stopPrank();

    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.wbtc, 100e8, carol, 0);
    contracts.poolProxy.supply(tokenList.weth, 100e18, carol, 0);
    vm.stopPrank();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.weth, true);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    // Perform borrow in isolated position
    vm.expectRevert(abi.encodeWithSelector(Errors.DebtCeilingExceeded.selector));
    contracts.poolProxy.borrow(tokenList.usdx, 10001e6, 2, 0, alice);
    vm.stopPrank();
  }
}
