// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IStableDebtToken} from '../../../src/contracts/interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IReserveInterestRateStrategy} from '../../../src/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
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

  IStableDebtToken internal staDebtUSDX;
  IVariableDebtToken internal varDebtUSDX;
  address internal aUSDX;

  PriceOracleSentinel internal priceOracleSentinel;
  SequencerOracle internal sequencerOracleMock;

  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

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
      totalStableDebt: 0,
      totalVariableDebt: 800e6,
      averageStableBorrowRate: 0,
      reserveFactor: 1000,
      reserve: tokenList.usdx,
      usingVirtualBalance: contracts
        .poolProxy
        .getConfiguration(tokenList.usdx)
        .getIsVirtualAccActive(),
      virtualUnderlyingBalance: contracts.poolProxy.getVirtualUnderlyingBalance(tokenList.usdx)
    });

    (, , uint256 expectedVariableBorrowRate) = rateStrategy.calculateInterestRates(input);

    vm.expectEmit(true, true, true, true, address(contracts.poolProxy));
    emit Borrow(
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
  }

  function test_stable_borrow() public {
    uint256 amount = 1e8;
    uint256 borrowAmount = 800e6;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 1, 0, alice);
    vm.stopPrank();
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
    uint256 debtBalanceBefore = staDebtUSDX.principalBalanceOf(alice);
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
      totalStableDebt: 0,
      totalVariableDebt: borrowAmount,
      averageStableBorrowRate: 0,
      reserveFactor: 1000,
      reserve: tokenList.usdx,
      usingVirtualBalance: contracts
        .poolProxy
        .getConfiguration(tokenList.usdx)
        .getIsVirtualAccActive(),
      virtualUnderlyingBalance: contracts.poolProxy.getVirtualUnderlyingBalance(tokenList.usdx)
    });

    (, , uint256 expectedVariableBorrowRate) = rateStrategy.calculateInterestRates(input);

    vm.expectEmit(address(contracts.poolProxy));
    emit IsolationModeTotalDebtUpdated(tokenList.wbtc, 100_00);
    vm.expectEmit(true, true, true, true, address(contracts.poolProxy));
    emit Borrow(
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
    assertEq(debtBalanceAfter, debtBalanceBefore + borrowAmount);
    assertEq(contracts.poolProxy.getUserConfiguration(alice).isBorrowing(reserveData.id), true);
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

    vm.expectRevert(bytes(Errors.INVALID_AMOUNT));
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
  }

  function test_reverts_borrow_invalidAmount() public {
    vm.expectRevert(bytes(Errors.INVALID_AMOUNT));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 0, 2, 0, alice);
  }

  function test_reverts_borrow_reserveInactive() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.wbtc, false);

    vm.expectRevert(bytes(Errors.RESERVE_INACTIVE));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 1, 0, alice);
  }

  function test_reverts_borrow_reservePaused() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.wbtc, true, 0);

    vm.expectRevert(bytes(Errors.RESERVE_PAUSED));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 1, 0, alice);
  }

  function test_reverts_borrow_reserveFrozen() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.wbtc, true);

    vm.expectRevert(bytes(Errors.RESERVE_FROZEN));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 1, 0, alice);
  }

  function test_reverts_borrow_cap() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 50e8, alice, 0);
    vm.stopPrank();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setBorrowCap(tokenList.wbtc, 1);

    vm.expectRevert(bytes(Errors.BORROW_CAP_EXCEEDED));

    contracts.poolProxy.borrow(tokenList.wbtc, 10e8, 1, 0, alice);
  }

  function test_reverts_borrow_invalid_rate() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 50e8, alice, 0);
    vm.stopPrank();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setBorrowCap(tokenList.wbtc, 1);

    vm.expectRevert(bytes(Errors.INVALID_INTEREST_RATE_MODE_SELECTED));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 100, 0, 0, alice);
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
    vm.expectRevert(bytes(Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.wbtc, 100, 2, 0, alice);
  }

  function test_reverts_borrow_stable_borrow_not_enabled() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveStableRateBorrowing(tokenList.usdx, false);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 50e8, alice, 0);

    vm.expectRevert(bytes(Errors.STABLE_BORROWING_NOT_ENABLED));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 100e6, 1, 0, alice);
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
    vm.expectRevert(bytes(Errors.ASSET_NOT_BORROWABLE_IN_ISOLATION));
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_borrow_debt_ceiling_exceeded() public {
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000_00);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    // Perform borrow in isolated position
    vm.expectRevert(bytes(Errors.DEBT_CEILING_EXCEEDED));
    contracts.poolProxy.borrow(tokenList.usdx, 10001e6, 2, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_borrow_inconsistent_emode_category() public {
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
    vm.stopPrank();

    vm.startPrank(alice);

    contracts.poolProxy.setUserEMode(ct.id);

    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    vm.expectRevert(bytes(Errors.INCONSISTENT_EMODE_CATEGORY));
    contracts.poolProxy.borrow(tokenList.usdx, 10001e6, 2, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_borrow_collateral_balance_zero() public {
    vm.expectRevert(bytes(Errors.COLLATERAL_BALANCE_IS_ZERO));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 0.2e8, 1, 0, alice);
  }

  function test_reverts_borrow_collateral_can_not_cover() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);

    vm.expectRevert(bytes(Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW));
    contracts.poolProxy.borrow(tokenList.usdx, 29001e6, 2, 0, alice);
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

    vm.expectRevert(bytes(Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 10001e6, 2, 0, alice);
  }

  function test_reverts_borrow_stable_collateral_same_borrow() public {
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);

    vm.expectRevert(bytes(Errors.COLLATERAL_SAME_AS_BORROWING_CURRENCY));
    contracts.poolProxy.borrow(tokenList.usdx, 10e6, 1, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_borrow_stable_amount_gt_max_loan_size_stable() public {
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, 100e8, alice, 0);

    vm.expectRevert(bytes(Errors.AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE));
    contracts.poolProxy.borrow(tokenList.usdx, 60_000e6, 1, 0, alice);
    vm.stopPrank();
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

    vm.expectRevert(bytes(Errors.SILOED_BORROWING_VIOLATION));
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
    vm.expectRevert(bytes(Errors.DEBT_CEILING_EXCEEDED));
    contracts.poolProxy.borrow(tokenList.usdx, 10001e6, 2, 0, alice);
    vm.stopPrank();
  }

  function test_reverts_rebalance_borrow_rate_reserve_inactive() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.wbtc, false);

    vm.expectRevert(bytes(Errors.RESERVE_INACTIVE));

    vm.prank(alice);
    contracts.poolProxy.rebalanceStableBorrowRate(tokenList.wbtc, alice);
  }

  function test_reverts_rebalance_borrow_rate_reserve_paused() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.wbtc, true, 0);

    vm.expectRevert(bytes(Errors.RESERVE_PAUSED));
    vm.prank(alice);
    contracts.poolProxy.rebalanceStableBorrowRate(tokenList.wbtc, alice);
  }

  function test_reverts_rebalance_borrow_rate_conditions_not_met() public {
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 15000e6, 2, 0, alice);

    vm.expectRevert(bytes(Errors.INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET));
    contracts.poolProxy.rebalanceStableBorrowRate(tokenList.usdx, alice);
    vm.stopPrank();
  }

  function test_rebalance_borrow_rate() public {
    DataTypes.ReserveDataLegacy memory usdxReserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );

    vm.mockCall(
      address(usdxReserveData.interestRateStrategyAddress),
      abi.encodeWithSelector(IReserveInterestRateStrategy.calculateInterestRates.selector),
      abi.encode(0, 0, 0)
    );

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    contracts.poolProxy.rebalanceStableBorrowRate(tokenList.usdx, alice);
    vm.clearMockedCalls();
  }

  function test_swap_borrow_rate_from_variable_to_stable() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 100e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 2000e6, 2, 0, alice);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    contracts.poolProxy.swapBorrowRateMode(tokenList.usdx, 2);
    vm.stopPrank();
  }

  function test_reverts_swap_borrow_rate_reserve_inactive() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.wbtc, false);

    vm.expectRevert(bytes(Errors.RESERVE_INACTIVE));

    vm.prank(alice);
    contracts.poolProxy.swapBorrowRateMode(tokenList.wbtc, 1);
  }

  function test_reverts_swap_borrow_rate_reserve_paused() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.usdx, true, 0);

    vm.expectRevert(bytes(Errors.RESERVE_PAUSED));

    vm.prank(alice);
    contracts.poolProxy.swapBorrowRateMode(tokenList.usdx, 2);
  }

  function test_swap_borrow_rate_reserve_frozen() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 100e8, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 2000e6, 2, 0, alice);
    vm.stopPrank();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(alice);
    contracts.poolProxy.swapBorrowRateMode(tokenList.usdx, 2);
  }

  function test_reverts_swap_borrow_rate_reserve_variable_no_debt() public {
    vm.expectRevert(bytes(Errors.NO_OUTSTANDING_VARIABLE_DEBT));

    vm.prank(alice);
    contracts.poolProxy.swapBorrowRateMode(tokenList.usdx, 2);
  }

  function test_reverts_swap_borrow_rate_reserve_stable_no_debt() public {
    vm.expectRevert(bytes(Errors.NO_OUTSTANDING_STABLE_DEBT));

    vm.prank(alice);
    contracts.poolProxy.swapBorrowRateMode(tokenList.usdx, 1);
  }

  function test_reverts_swap_borrow_rate_reserve_invalid_rate_mode() public {
    vm.expectRevert(bytes(Errors.INVALID_INTEREST_RATE_MODE_SELECTED));

    vm.prank(alice);
    contracts.poolProxy.swapBorrowRateMode(tokenList.usdx, 0);
  }
}
