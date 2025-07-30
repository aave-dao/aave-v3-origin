// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'forge-std/StdStorage.sol';

import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {IPool, DataTypes} from '../../../src/contracts/interfaces/IPool.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IReserveInterestRateStrategy} from '../../../src/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {PoolInstance} from '../../../src/contracts/instances/PoolInstance.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract PoolTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;

  IPool internal pool;

  function setUp() public virtual {
    initTestEnvironment();

    pool = PoolInstance(report.poolProxy);
  }

  function test_reverts_impl_initialize() external {
    PoolInstance p = new PoolInstance(
      IPoolAddressesProvider(report.poolAddressesProvider),
      IReserveInterestRateStrategy(report.defaultInterestRateStrategy)
    );

    vm.expectRevert(bytes('Contract instance has already been initialized'));
    p.initialize(IPoolAddressesProvider(makeAddr('OTHER_CONTRACT')));
  }

  function test_reverts_new_Pool_invalidAddressesProvider() public {
    PoolInstance p = new PoolInstance(
      IPoolAddressesProvider(report.poolAddressesProvider),
      IReserveInterestRateStrategy(report.defaultInterestRateStrategy)
    );

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddressesProvider.selector));
    new TransparentUpgradeableProxy(
      address(p),
      address(this),
      abi.encodeWithSelector(PoolInstance.initialize.selector, makeAddr('OTHER_CONTRACT'))
    );
  }

  function test_pool_defaultValues() public {
    PoolInstance pImpl = new PoolInstance(
      IPoolAddressesProvider(report.poolAddressesProvider),
      IReserveInterestRateStrategy(report.defaultInterestRateStrategy)
    );

    PoolInstance p = PoolInstance(
      address(
        new TransparentUpgradeableProxy(
          address(pImpl),
          address(this),
          abi.encodeWithSelector(PoolInstance.initialize.selector, report.poolAddressesProvider)
        )
      )
    );

    // Default values after deployment and initialized
    assertEq(p.MAX_NUMBER_RESERVES(), 128);
    assertEq(address(p.ADDRESSES_PROVIDER()), report.poolAddressesProvider);
    assertEq(p.FLASHLOAN_PREMIUM_TOTAL(), 0);
    assertEq(p.FLASHLOAN_PREMIUM_TO_PROTOCOL(), 100_00);
  }

  function test_reverts_initReserve_not_poolConfigurator(address caller) public {
    vm.assume(caller != report.poolConfiguratorProxy && caller != report.poolAddressesProvider);

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    vm.prank(caller);
    pool.initReserve(address(0), address(0), address(0));
  }

  function test_approvePositionManager_true() public {
    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.PositionManagerApproved(alice, bob);

    vm.prank(alice);
    pool.approvePositionManager(bob, true);

    assertTrue(pool.isApprovedPositionManager(alice, bob));
  }

  function test_approvePositionManager_false() public {
    test_approvePositionManager_true();

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.PositionManagerRevoked(alice, bob);

    vm.prank(alice);
    pool.approvePositionManager(bob, false);

    assertFalse(pool.isApprovedPositionManager(alice, bob));
  }

  function test_renouncePositionManager() public {
    vm.prank(alice);
    pool.approvePositionManager(bob, true);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.PositionManagerRevoked(alice, bob);
    vm.prank(bob);
    pool.renouncePositionManagerRole(alice);
    assertFalse(pool.isApprovedPositionManager(alice, bob));
  }

  function test_noop_approvePositionManager_true_when_already_is_activated() public {
    test_approvePositionManager_true();

    vm.prank(alice);
    pool.approvePositionManager(bob, true);

    assertTrue(pool.isApprovedPositionManager(alice, bob));
  }

  function test_setUserUseReserveAsCollateral_false() public {
    vm.startPrank(alice);
    pool.supply(tokenList.usdx, 1e6, alice, 0);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.ReserveUsedAsCollateralDisabled(tokenList.usdx, alice);

    pool.setUserUseReserveAsCollateral(tokenList.usdx, false);
    vm.stopPrank();
  }

  function test_setUserUseReserveAsCollateral_true() public {
    test_setUserUseReserveAsCollateral_false();

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.ReserveUsedAsCollateralEnabled(tokenList.usdx, alice);

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_noop_setUserUseReserveAsCollateral_true_when_already_is_activated() public {
    test_setUserUseReserveAsCollateral_true();

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_setUserUseReserveAsCollateralOnBehalfOf_false() public {
    _supplyAndEnableAsCollateral(alice, 1e6, tokenList.usdx);

    vm.prank(alice);
    pool.approvePositionManager(address(this), true);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.ReserveUsedAsCollateralDisabled(tokenList.usdx, alice);

    pool.setUserUseReserveAsCollateralOnBehalfOf(tokenList.usdx, false, alice);
  }

  function test_setUserUseReserveAsCollateralOnBehalfOf_true() public {
    test_setUserUseReserveAsCollateralOnBehalfOf_false();

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.ReserveUsedAsCollateralEnabled(tokenList.usdx, alice);

    pool.setUserUseReserveAsCollateralOnBehalfOf(tokenList.usdx, true, alice);
  }

  function test_noop_setUserUseReserveAsCollateralOnBehalfOf_true_when_already_is_activated()
    public
  {
    test_setUserUseReserveAsCollateralOnBehalfOf_true();

    pool.setUserUseReserveAsCollateralOnBehalfOf(tokenList.usdx, true, alice);
  }

  function test_reverts_setUserUseReserveAsCollateralOnBehalfOf_caller_not_position_manager(
    address caller
  ) public {
    vm.assume(caller != address(this) && caller != report.poolAddressesProvider);

    _supplyAndEnableAsCollateral(alice, 1e6, tokenList.usdx);

    vm.prank(alice);
    pool.approvePositionManager(address(this), true);

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPositionManager.selector));

    vm.prank(caller);
    pool.setUserUseReserveAsCollateralOnBehalfOf(tokenList.usdx, true, alice);
  }

  function test_reverts_setUserUseReserveAsCollateral_true_ltv_zero() public {
    test_setUserUseReserveAsCollateral_false();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(tokenList.usdx, 0, 70_00, 105_00);

    vm.expectRevert(abi.encodeWithSelector(Errors.UserInIsolationModeOrLtvZero.selector));

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_reverts_setUserUseReserveAsCollateral_true_user_isolation_mode() public {
    _seedUsdxLiquidity();

    test_setUserUseReserveAsCollateral_false();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    pool.supply(tokenList.wbtc, 0.5e8, alice, 0);

    pool.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    pool.borrow(tokenList.usdx, 10e6, 2, 0, alice);

    vm.expectRevert(abi.encodeWithSelector(Errors.UserInIsolationModeOrLtvZero.selector));

    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
    vm.stopPrank();
  }

  function test_reverts_setUserUseReserveAsCollateral_true_user_balance_zero() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.UnderlyingBalanceZero.selector));

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_reverts_setUserUseReserveAsCollateral_true_reserve_inactive() public {
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.usdx, false);

    vm.prank(report.poolProxy);
    IAToken(aUSDX).mint(alice, alice, 100e6, 1e27);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveInactive.selector));

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_reverts_setUserUseReserveAsCollateral_true_reserve_paused() public {
    test_setUserUseReserveAsCollateral_false();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.usdx, true, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReservePaused.selector));

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_reverts_setUserUseReserveAsCollateral_false_hf_lower_lqt() public {
    _seedUsdxLiquidity();

    vm.startPrank(alice);
    pool.supply(tokenList.wbtc, 0.5e8, alice, 0);

    pool.borrow(tokenList.usdx, 10e6, 2, 0, alice);

    vm.expectRevert(
      abi.encodeWithSelector(Errors.HealthFactorLowerThanLiquidationThreshold.selector)
    );
    pool.setUserUseReserveAsCollateral(tokenList.wbtc, false);
    vm.stopPrank();
  }

  function test_updateBridgeProtocolFee() public {}

  function test_reverts_modifiers_not_poolConfigurator(address caller) public {
    vm.assume(caller != report.poolConfiguratorProxy && caller != report.poolAddressesProvider);

    DataTypes.ReserveConfigurationMap memory configuration;

    DataTypes.EModeCategoryBaseConfiguration memory category;

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    pool.initReserve(address(0), address(0), address(0));

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    pool.dropReserve(address(0));

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    pool.setConfiguration(address(0), configuration);

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    pool.updateFlashloanPremium(1);

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    pool.configureEModeCategory(1, category);

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    pool.resetIsolationModeTotalDebt(address(0));

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    pool.setLiquidationGracePeriod(address(0), uint40(vm.getBlockTimestamp() + 3 hours));
  }

  function test_dropReserve() public {
    (address pA, address pS, address pV) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );
    assertTrue(pA != address(0));
    assertTrue(pS == address(0));
    assertTrue(pV != address(0));

    vm.prank(report.poolConfiguratorProxy);
    pool.dropReserve(tokenList.usdx);

    (address a, address s, address v) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );

    (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      ,
      bool isActive,
      bool isFrozen
    ) = contracts.protocolDataProvider.getReserveConfigurationData(tokenList.usdx);

    assertEq(a, address(0));
    assertEq(s, address(0));
    assertEq(v, address(0));
    assertEq(decimals, 0);
    assertEq(ltv, 0);
    assertEq(liquidationThreshold, 0);
    assertEq(liquidationBonus, 0);
    assertEq(reserveFactor, 0);
    assertEq(usageAsCollateralEnabled, false);
    assertEq(borrowingEnabled, false);
    assertEq(isActive, false);
    assertEq(isFrozen, false);
  }

  function test_setLiquidationGracePeriod(uint40 liquidationGracePeriod) public {
    vm.prank(report.poolConfiguratorProxy);
    pool.setLiquidationGracePeriod(tokenList.usdx, liquidationGracePeriod);

    assertEq(pool.getLiquidationGracePeriod(tokenList.usdx), liquidationGracePeriod);
  }

  function test_setLiquidationGracePeriod_assetNotListed(uint40 liquidationGracePeriod) public {
    address asset = address(25);

    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.AssetNotListed.selector));

    pool.setLiquidationGracePeriod(asset, liquidationGracePeriod);
  }

  function test_rescueTokens(uint256 rescueAmount) public {
    rescueAmount = bound(rescueAmount, 1, 100e6);

    vm.prank(poolAdmin);
    usdx.mint(report.poolProxy, rescueAmount);

    vm.prank(poolAdmin);
    pool.rescueTokens(address(usdx), poolAdmin, rescueAmount);

    assertEq(usdx.balanceOf(poolAdmin), rescueAmount);
  }

  function test_resetIsolationModeTotalDebt() public {
    _seedUsdxLiquidity();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    pool.supply(tokenList.wbtc, 0.5e8, alice, 0);
    pool.setUserUseReserveAsCollateral(tokenList.wbtc, true);
    pool.borrow(tokenList.usdx, 10e6, 2, 0, alice);
    vm.stopPrank();

    assertGt(pool.getReserveData(tokenList.wbtc).isolationModeTotalDebt, 0);

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 0);

    vm.expectEmit(report.poolProxy);
    emit IPool.IsolationModeTotalDebtUpdated(tokenList.wbtc, 0);
    vm.stopPrank();

    vm.prank(report.poolConfiguratorProxy);
    pool.resetIsolationModeTotalDebt(tokenList.wbtc);

    assertEq(pool.getReserveData(tokenList.wbtc).isolationModeTotalDebt, 0);
  }

  function test_getters_getUserAccountData() public {
    _seedUsdxLiquidity();

    DataTypes.ReserveConfigurationMap memory conf = pool.getConfiguration(tokenList.wbtc);

    vm.startPrank(bob);
    pool.supply(tokenList.wbtc, 0.4e8, bob, 0);
    pool.borrow(tokenList.usdx, 2000e6, 2, 0, bob);
    vm.stopPrank();

    (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      ,
      uint256 currentLiquidationThreshold,
      uint256 ltv,

    ) = pool.getUserAccountData(bob);

    assertEq(totalCollateralBase, 10800e8);
    assertEq(totalDebtBase, 2000e8);
    assertEq(currentLiquidationThreshold, conf.getLiquidationThreshold());
    assertEq(ltv, conf.getLtv());
  }

  function test_mintToTreasury() public {
    address varDebtUSDX = contracts.poolProxy.getReserveVariableDebtToken(tokenList.usdx);

    _seedUsdxLiquidity();

    vm.startPrank(bob);
    pool.supply(tokenList.wbtc, 0.4e8, bob, 0);
    pool.borrow(tokenList.usdx, 2000e6, 2, 0, bob);

    vm.warp(vm.getBlockTimestamp() + 30 days);

    pool.repay(tokenList.usdx, IERC20(varDebtUSDX).balanceOf(bob), 2, bob);
    vm.stopPrank();

    // distribute fees to treasury
    address[] memory assets = new address[](1);
    assets[0] = tokenList.usdx;

    uint256 accruedToTreasury = uint256(pool.getReserveData(tokenList.usdx).accruedToTreasury)
      .rayMul(pool.getReserveNormalizedIncome(tokenList.usdx), WadRayMath.Rounding.Floor);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.MintedToTreasury(tokenList.usdx, accruedToTreasury);

    pool.mintToTreasury(assets);

    assertEq(pool.getReserveData(tokenList.usdx).accruedToTreasury, 0);
  }

  function test_mintToTreasury_skip_invalid_addresses() public {
    address varDebtUSDX = contracts.poolProxy.getReserveVariableDebtToken(tokenList.usdx);

    _seedUsdxLiquidity();

    vm.startPrank(bob);
    pool.supply(tokenList.wbtc, 0.4e8, bob, 0);
    pool.borrow(tokenList.usdx, 2000e6, 2, 0, bob);

    vm.warp(vm.getBlockTimestamp() + 30 days);

    pool.repay(tokenList.usdx, IERC20(varDebtUSDX).balanceOf(bob), 2, bob);
    vm.stopPrank();

    // distribute fees to treasury
    address[] memory assets = new address[](2);
    assets[0] = makeAddr('OTHER_TOKEN');
    assets[1] = tokenList.usdx;

    uint256 accruedToTreasury = uint256(pool.getReserveData(tokenList.usdx).accruedToTreasury)
      .rayMul(pool.getReserveNormalizedIncome(tokenList.usdx), WadRayMath.Rounding.Floor);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.MintedToTreasury(tokenList.usdx, accruedToTreasury);

    pool.mintToTreasury(assets);

    assertEq(pool.getReserveData(tokenList.usdx).accruedToTreasury, 0);
  }

  function test_setUserEmode() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct.id, true);
    vm.stopPrank();
    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.UserEModeSet(alice, ct.id);

    vm.prank(alice);
    pool.setUserEMode(ct.id);
  }

  function test_setUserEModeOnBehalfOf() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct.id, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.approvePositionManager(address(this), true);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.UserEModeSet(alice, ct.id);

    pool.setUserEModeOnBehalfOf(ct.id, alice);
  }

  function test_revert_setUserEModeOnBehalfOf_not_position_manager(address caller) public {
    vm.assume(caller != address(this) && caller != report.poolAddressesProvider);

    EModeCategoryInput memory ct = _genCategoryOne();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct.id, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.approvePositionManager(address(this), true);

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPositionManager.selector));

    vm.prank(caller);
    pool.setUserEModeOnBehalfOf(ct.id, alice);
  }

  function test_setUserEmode_twice() public {
    EModeCategoryInput memory ct1 = _genCategoryOne();
    EModeCategoryInput memory ct2 = _genCategoryTwo();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setEModeCategory(ct2.id, ct2.ltv, ct2.lt, ct2.lb, ct2.label);

    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct2.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct2.id, true);
    vm.stopPrank();

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.UserEModeSet(alice, ct1.id);

    vm.prank(alice);
    pool.setUserEMode(ct1.id);

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.UserEModeSet(alice, ct2.id);

    vm.prank(alice);
    pool.setUserEMode(ct2.id);
  }

  function test_setUserEmode_twice_inconsistent_category() public {
    vm.prank(carol);
    pool.supply(tokenList.wbtc, 10e8, carol, 0);
    vm.prank(carol);
    pool.supply(tokenList.weth, 100e18, carol, 0);

    EModeCategoryInput memory ct1 = _genCategoryOne();
    EModeCategoryInput memory ct2 = _genCategoryTwo();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setEModeCategory(ct2.id, ct2.ltv, ct2.lt, ct2.lb, ct2.label);

    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.weth, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct2.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct2.id, true);
    vm.stopPrank();

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.UserEModeSet(alice, ct1.id);

    uint256 amount = 1e8;
    uint256 borrowAmount = 12e18;

    vm.startPrank(alice);
    pool.setUserEMode(ct1.id);

    pool.supply(tokenList.wbtc, amount, alice, 0);
    pool.borrow(tokenList.weth, borrowAmount, 2, 0, alice);

    vm.expectRevert(abi.encodeWithSelector(Errors.NotBorrowableInEMode.selector));

    pool.setUserEMode(ct2.id);
    vm.stopPrank();
  }

  function test_reverts_setUserEmode_0_bad_hf() public {
    vm.prank(carol);
    pool.supply(tokenList.wbtc, 10e8, carol, 0);
    vm.prank(carol);
    pool.supply(tokenList.weth, 100e18, carol, 0);

    EModeCategoryInput memory ct1 = _genCategoryOne();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);

    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.weth, ct1.id, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.setUserEMode(ct1.id);

    uint256 amount = 1e8;
    uint256 borrowAmount = 12e18;

    vm.startPrank(alice);
    pool.supply(tokenList.wbtc, amount, alice, 0);
    pool.borrow(tokenList.weth, borrowAmount, 2, 0, alice);

    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(tokenList.wbtc))
      .sig('_latestAnswer()')
      .checked_write(
        _calcPrice(IAaveOracle(report.aaveOracle).getAssetPrice(tokenList.wbtc), 70_00)
      );

    vm.expectRevert(
      abi.encodeWithSelector(Errors.HealthFactorLowerThanLiquidationThreshold.selector)
    );

    pool.setUserEMode(0);
    vm.stopPrank();
  }

  function test_getVirtualUnderlyingBalance() public {
    _seedUsdxLiquidity();

    uint256 virtualBalance = pool.getVirtualUnderlyingBalance(tokenList.usdx);
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);

    assertEq(IERC20(tokenList.usdx).balanceOf(aUSDX), virtualBalance);
    assertEq(50_000e6, virtualBalance);
  }

  function test_getFlashLoanLogic() public view {
    assertNotEq(pool.getFlashLoanLogic(), address(0));
  }

  function test_getBorrowLogic() public view {
    assertNotEq(pool.getBorrowLogic(), address(0));
  }

  function test_getEModeLogic() public view {
    assertNotEq(pool.getEModeLogic(), address(0));
  }

  function test_getLiquidationLogic() public view {
    assertNotEq(pool.getLiquidationLogic(), address(0));
  }

  function test_getPoolLogic() public view {
    assertNotEq(pool.getPoolLogic(), address(0));
  }

  function test_getSupplyLogic() public view {
    assertNotEq(pool.getSupplyLogic(), address(0));
  }

  function _seedUsdxLiquidity() internal {
    vm.prank(carol);
    pool.supply(tokenList.usdx, 50_000e6, carol, 0);
  }
}
