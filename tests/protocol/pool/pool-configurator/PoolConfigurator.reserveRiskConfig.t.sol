// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ReserveLogic} from '../../../../src/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {IPoolConfigurator} from '../../../../src/contracts/interfaces/IPoolConfigurator.sol';
import '../../../utils/TestnetProcedures.sol';

contract PoolConfiguratorReserveRiskConfigs is TestnetProcedures {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using ReserveLogic for DataTypes.ReserveData;

  DataTypes.ReserveData internal reserveData;
  DataTypes.ReserveData internal updatedReserveData;

  function setUp() public {
    initTestEnvironment();

    vm.startPrank(poolAdmin);
    wbtc.mint(bob, 100e8);
    vm.stopPrank();

    vm.prank(bob);
    contracts.poolProxy.supply(tokenList.wbtc, 100e8, bob, 0);
  }

  function test_enableBorrowing(TestVars memory t) public {
    ConfiguratorInputTypes.InitReserveInput[] memory input = _generateInitConfig(
      t,
      report,
      poolAdmin,
      true
    );

    // Perform action
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);
    (, , , , , , bool borrowingEnabledDefault, , , ) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(input[0].underlyingAsset);
    assertEq(borrowingEnabledDefault, false);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveBorrowing(input[0].underlyingAsset, true);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveBorrowing(input[0].underlyingAsset, true);

    (, , , , , , bool borrowingEnabledAfter, , , ) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(input[0].underlyingAsset);
    assertEq(borrowingEnabledAfter, true);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveBorrowing(input[0].underlyingAsset, false);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveBorrowing(input[0].underlyingAsset, false);

    (, , , , , , bool borrowingConfigAfter, , , ) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(input[0].underlyingAsset);
    assertEq(borrowingConfigAfter, false);
  }

  function test_enableFlashBorrow(TestVars memory t) public {
    ConfiguratorInputTypes.InitReserveInput[] memory input = _generateInitConfig(
      t,
      report,
      poolAdmin,
      true
    );

    // Perform action
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveFlashLoaning(input[0].underlyingAsset, true);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFlashLoaning(input[0].underlyingAsset, true);

    bool value = contracts.protocolDataProvider.getFlashLoanEnabled(input[0].underlyingAsset);
    assertEq(value, true);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFlashLoaning(input[0].underlyingAsset, false);

    bool valueAfter = contracts.protocolDataProvider.getFlashLoanEnabled(input[0].underlyingAsset);
    assertEq(valueAfter, false);
  }

  function test_setCollateralConfig(TestVars memory t) public {
    uint256 ltv = 80_00;
    uint256 liquidationThreshold = 85_00;
    uint256 liquidationBonus = 105_00;

    ConfiguratorInputTypes.InitReserveInput[] memory input = _generateInitConfig(
      t,
      report,
      poolAdmin,
      true
    );

    // Perform action
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.CollateralConfigurationChanged(
      input[0].underlyingAsset,
      ltv,
      liquidationThreshold,
      liquidationBonus
    );

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      input[0].underlyingAsset,
      ltv,
      liquidationThreshold,
      liquidationBonus
    );
    (, uint256 ltvConfig, uint256 liqThreshold, uint256 liqBonus, , , , , , ) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(input[0].underlyingAsset);

    assertEq(ltvConfig, ltv);
    assertEq(liqThreshold, liquidationThreshold);
    assertEq(liqBonus, liquidationBonus);
  }

  function test_reverts_setCollateralConfig_invalidParams(TestVars memory t) public {
    ConfiguratorInputTypes.InitReserveInput[] memory input = _generateInitConfig(
      t,
      report,
      poolAdmin,
      true
    );

    // Perform action
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.initReserves(input);

    // Revert due LTV > LQT
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidReserveParams.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      input[0].underlyingAsset,
      95_00,
      90_00,
      105_00
    );

    // Revert due LIQ BONUS < PERCENTAGE_FACTOR
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidReserveParams.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      input[0].underlyingAsset,
      90_00,
      95_00,
      99_00
    );

    // Revert due LQT does not cover bonus
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidReserveParams.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      input[0].underlyingAsset,
      90_00,
      95_00,
      200_00
    );

    // Revert due LQT == 0 == LQ_BONUS
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidReserveParams.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      input[0].underlyingAsset,
      90_00,
      0,
      1
    );

    // Revert due for LQT == 0 there should be no suppliers
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 10e6, alice, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveLiquidityNotZero.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(tokenList.usdx, 0, 0, 0);
  }

  function test_reverts_setReserveActive_false_if_suppliers() public {
    // Revert due for LQT == 0 there should be no suppliers
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 10e6, alice, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveLiquidityNotZero.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.usdx, false);
  }

  function test_setReserveActive_false() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveActive(tokenList.usdx, false);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.usdx, false);
    (, , , , , , , , bool isActive, ) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );
    assertEq(isActive, false);
  }

  function test_setReserveActive_true() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveActive(tokenList.usdx, true);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.usdx, true);
    (, , , , , , , , bool isActive, ) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );
    assertEq(isActive, true);
  }

  function test_PoolAdminSetReserveFreeze_true() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveFrozen(tokenList.usdx, true);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    (, , , , , , , , , bool isFrozen) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );
    assertEq(isFrozen, true);
  }

  function test_RiskAdminSetReserveFreeze_true() public {
    vm.prank(poolAdmin);
    contracts.aclManager.addRiskAdmin(bob);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveFrozen(tokenList.usdx, true);

    vm.prank(bob);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    (, , , , , , , , , bool isFrozen) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );
    assertEq(isFrozen, true);
  }

  function test_EmergencyAdminSetReserveFreeze_true() public {
    vm.prank(poolAdmin);
    contracts.aclManager.addEmergencyAdmin(bob);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveFrozen(tokenList.usdx, true);

    vm.prank(bob);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    (, , , , , , , , , bool isFrozen) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );
    assertEq(isFrozen, true);
  }

  function test_setReserveFreeze_false() public {
    vm.startPrank(poolAdmin);
    // freeze reserve
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    (, , , , , , , , , bool isFrozen) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );
    assertEq(isFrozen, true);

    // unfreeze reserve
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveFrozen(tokenList.usdx, false);

    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, false);
    (, , , , , , , , , isFrozen) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );
    assertEq(isFrozen, false);

    vm.stopPrank();
  }

  function test_setUnfrozenReserveFreeze_false_revert() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFreezeState.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, false);
  }

  function test_setFrozenReserveFreeze_true_revert() public {
    vm.startPrank(poolAdmin);

    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);
    (, , , , , , , , , bool isFrozen) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );
    assertEq(isFrozen, true);

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFreezeState.selector));
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    vm.stopPrank();
  }

  function test_setBorrowableInIsolation_true() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.BorrowableInIsolationChanged(tokenList.usdx, true);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    DataTypes.ReserveConfigurationMap memory config = contracts.poolProxy.getConfiguration(
      tokenList.usdx
    );
    assertEq(config.getBorrowableInIsolation(), true);
  }

  function test_setBorrowableInIsolation_false() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.BorrowableInIsolationChanged(tokenList.usdx, false);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, false);
    DataTypes.ReserveConfigurationMap memory config = contracts.poolProxy.getConfiguration(
      tokenList.usdx
    );
    assertEq(config.getBorrowableInIsolation(), false);
  }

  function test_setReservePause_false() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReservePaused(tokenList.usdx, false);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.usdx, false, 0);
    assertEq(contracts.protocolDataProvider.getPaused(tokenList.usdx), false);
  }

  function test_setReservePause_true() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReservePaused(tokenList.usdx, true);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.usdx, true, 0);
    assertEq(contracts.protocolDataProvider.getPaused(tokenList.usdx), true);
  }

  function test_reverts_setReserveFactor_gt_percentageFactor() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidReserveFactor.selector));
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFactor(tokenList.usdx, 101_00);
  }

  function test_setReserveFactor() public {
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);

    uint256 amount = 100_000e6;
    uint256 borrowAmount = 30_000e6;

    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);

    vm.stopPrank();

    reserveData = _getFullReserveData(tokenList.usdx);
    DataTypes.ReserveCache memory cache = reserveData.cache();
    uint40 initialTimestamp = uint40(vm.getBlockTimestamp());

    assertEq(cache.currVariableBorrowIndex, 1e27);
    assertEq(cache.currVariableBorrowRate, 13333333333333333333333333);
    assertEq(cache.reserveLastUpdateTimestamp, initialTimestamp);

    vm.warp(vm.getBlockTimestamp() + 365 days);

    // check that index is not changed after 1 year
    updatedReserveData = _getFullReserveData(tokenList.usdx);
    DataTypes.ReserveCache memory cacheAfterYear = updatedReserveData.cache();

    assertEq(cacheAfterYear.reserveLastUpdateTimestamp, initialTimestamp);
    assertEq(cacheAfterYear.currVariableBorrowIndex, 1e27);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveFactorChanged(tokenList.usdx, 10_00, 5_00);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFactor(tokenList.usdx, 5_00);
    (, , , , uint256 reserveFactor, , , , , ) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(tokenList.usdx);
    assertEq(reserveFactor, 5_00);

    // index and rate have changed after Reserve Factor update
    updatedReserveData = _getFullReserveData(tokenList.usdx);
    DataTypes.ReserveCache memory updatedCache = updatedReserveData.cache();

    assertNotEq(updatedCache.currVariableBorrowIndex, cacheAfterYear.currVariableBorrowIndex);
    assertNotEq(updatedCache.currVariableBorrowRate, cacheAfterYear.currVariableBorrowIndex);
    assertGt(updatedCache.reserveLastUpdateTimestamp, cacheAfterYear.reserveLastUpdateTimestamp);
  }

  function test_reverts_setDebtCeiling_suppliers() public {
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 10e6, alice, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveLiquidityNotZero.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.usdx, 100);
  }

  function test_setDebtCeiling_suppliers_ltZero() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(tokenList.usdx, 0, 0, 0);

    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 10e6, alice, 0);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.usdx, 100);
    assertEq(contracts.protocolDataProvider.getDebtCeiling(tokenList.usdx), 100);
  }

  function test_setDebtCeiling() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.DebtCeilingChanged(tokenList.usdx, 0, 100);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.usdx, 100);
    assertEq(contracts.protocolDataProvider.getDebtCeiling(tokenList.usdx), 100);
  }

  function test_setDebtCeiling_to_zero() public {
    test_setDebtCeiling();

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.DebtCeilingChanged(tokenList.usdx, 100, 0);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.usdx, 0);
    assertEq(contracts.protocolDataProvider.getDebtCeiling(tokenList.usdx), 0);
  }

  function test_setSiloedBorrowing() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.SiloedBorrowingChanged(tokenList.usdx, false, true);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setSiloedBorrowing(tokenList.usdx, true);
    assertEq(contracts.protocolDataProvider.getSiloedBorrowing(tokenList.usdx), true);
  }

  function test_reverts_setSiloedBorrowing_borrowers() public {
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, 10e6, 2, 0, alice);

    vm.stopPrank();

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveDebtNotZero.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setSiloedBorrowing(tokenList.usdx, true);
  }

  function test_reverts_setLiquidationProtocolFee_amount_gt_percentageFactor() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidLiquidationProtocolFee.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 100_01);
  }

  function test_setLiquidationProtocolFee_amount_gt_percentageFactor() public {
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.LiquidationProtocolFeeChanged(tokenList.usdx, 10_00, 6_00);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.usdx, 6_00);

    assertEq(contracts.protocolDataProvider.getLiquidationProtocolFee(tokenList.usdx), 6_00);
  }

  function test_setPoolPause() public {
    address[] memory reserves = contracts.poolProxy.getReservesList();
    for (uint16 x; x < reserves.length; ++x) {
      vm.expectEmit(address(contracts.poolConfiguratorProxy));
      emit IPoolConfigurator.ReservePaused(reserves[x], true);
    }
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setPoolPause(true);

    for (uint16 x; x < reserves.length; ++x) {
      bool isPaused = contracts.protocolDataProvider.getPaused(reserves[x]);
      assertEq(isPaused, true);
    }
  }

  function test_setPoolPause_unpause() public {
    test_setPoolPause();
    address[] memory reserves = contracts.poolProxy.getReservesList();
    for (uint16 x; x < reserves.length; ++x) {
      vm.expectEmit(address(contracts.poolConfiguratorProxy));
      emit IPoolConfigurator.ReservePaused(reserves[x], false);
    }
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setPoolPause(false);

    for (uint16 x; x < reserves.length; ++x) {
      bool isPaused = contracts.protocolDataProvider.getPaused(reserves[x]);
      assertEq(isPaused, false);
    }
  }

  function test_reverts_updateFlashloanPremium() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.FlashloanPremiumInvalid.selector));

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.updateFlashloanPremium(100_01);
  }

  function test_updateFlashloanPremium() public {
    vm.expectEmit(false, false, false, false, address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.FlashloanPremiumTotalUpdated(0, 10_00);

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.updateFlashloanPremium(10_00);
    assertEq(contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL(), 10_00);
  }

  function test_dropReserve() public {
    DataTypes.ReserveDataLegacy memory reserveDataUsdx = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.ReserveDropped(tokenList.usdx);

    (address pA, address pS, address pV) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );
    assertTrue(pA != address(0));
    assertTrue(pS == address(0));
    assertTrue(pV != address(0));

    uint256 lengthBefore = contracts.poolProxy.getReservesList().length;

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.dropReserve(tokenList.usdx);

    (address a, address s, address v) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );
    {
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
    {
      assertEq(contracts.poolProxy.getReservesList().length, lengthBefore - 1);
      assertEq(contracts.poolProxy.getReserveAddressById(reserveDataUsdx.id), address(0));
    }
  }

  function test_reverts_dropReserve_notListed() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.AssetNotListed.selector));
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.dropReserve(makeAddr('TOKEN_NOT_LISTED'));
  }

  function test_reverts_dropReserve_zeroAddress() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressNotValid.selector));
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.dropReserve(address(0));
  }

  function test_reverts_dropReserve_variableDebtNotZero() public {
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.001e8, 2, 0, alice);
    vm.stopPrank();

    vm.expectRevert(abi.encodeWithSelector(Errors.VariableDebtSupplyNotZero.selector));
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.dropReserve(tokenList.wbtc);
  }

  function test_reverts_dropReserve_supplyNotZero() public {
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 100e6, alice, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.UnderlyingClaimableRightsNotZero.selector));
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.dropReserve(tokenList.wbtc);
  }

  function test_setLiquidationGracePeriodReserve(uint40 gracePeriod) public {
    gracePeriod = uint40(bound(gracePeriod, 1, contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD()));

    address asset = tokenList.usdx;

    uint40 until = uint40(vm.getBlockTimestamp()) + gracePeriod;

    vm.startPrank(poolAdmin);

    // reserve unpause -> unpause, liquidationGracePeriod would be set
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.LiquidationGracePeriodChanged(asset, until);
    contracts.poolConfiguratorProxy.setReservePause(asset, false, gracePeriod);
    assertEq(contracts.poolProxy.getLiquidationGracePeriod(asset), until);

    // reserve unpause -> pause, liquidationGracePeriod would not be set
    contracts.poolConfiguratorProxy.setReservePause(asset, true, gracePeriod);
    assertEq(contracts.poolProxy.getLiquidationGracePeriod(asset), until);
    assertTrue(contracts.protocolDataProvider.getPaused(asset));

    // reserve pause -> pause, liquidationGracePeriod would not be set
    contracts.poolConfiguratorProxy.setReservePause(asset, true, gracePeriod);
    assertEq(contracts.poolProxy.getLiquidationGracePeriod(asset), until);

    // reserve pause -> unpause, liquidationGracePeriod would be set
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.LiquidationGracePeriodChanged(asset, until);
    contracts.poolConfiguratorProxy.setReservePause(asset, false, gracePeriod);
    assertEq(contracts.poolProxy.getLiquidationGracePeriod(asset), until);

    vm.stopPrank();
  }

  function test_disableLiquidationGracePeriod() public {
    uint40 gracePeriod = 2 hours;
    address asset = tokenList.usdx;
    uint40 until = uint40(vm.getBlockTimestamp()) + 2 hours;

    vm.startPrank(poolAdmin);

    contracts.poolConfiguratorProxy.setReservePause(asset, false, gracePeriod);
    assertEq(contracts.poolProxy.getLiquidationGracePeriod(asset), until);

    contracts.poolConfiguratorProxy.disableLiquidationGracePeriod(asset);
    assertEq(contracts.poolProxy.getLiquidationGracePeriod(asset), vm.getBlockTimestamp() - 1);

    vm.stopPrank();
  }

  function test_setLiquidationGracePeriodPool(uint40 gracePeriod) public {
    vm.assume(gracePeriod <= contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD());

    address[] memory allReserves = contracts.poolProxy.getReservesList();

    uint40 until = uint40(vm.getBlockTimestamp()) + gracePeriod;

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setPoolPause(false, gracePeriod);

    for (uint256 i = 0; i < allReserves.length; i++) {
      if (gracePeriod != 0) {
        assertEq(contracts.poolProxy.getLiquidationGracePeriod(allReserves[i]), until);
      }
    }
  }

  function test_setLiquidationGracePeriodAboveCap(uint40 gracePeriod) public {
    vm.assume(
      gracePeriod > contracts.poolConfiguratorProxy.MAX_GRACE_PERIOD() &&
        gracePeriod < type(uint40).max - vm.getBlockTimestamp()
    );

    address asset = tokenList.usdx;

    vm.prank(poolAdmin);

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidGracePeriod.selector));
    contracts.poolConfiguratorProxy.setReservePause(asset, false, gracePeriod);
  }

  function _getFullReserveData(address asset) internal view returns (DataTypes.ReserveData memory) {
    DataTypes.ReserveDataLegacy memory reserveDataLegacy = contracts.poolProxy.getReserveData(
      asset
    );
    DataTypes.ReserveData memory tempReserveData;
    tempReserveData.configuration = reserveDataLegacy.configuration;
    tempReserveData.liquidityIndex = reserveDataLegacy.liquidityIndex;
    tempReserveData.currentLiquidityRate = reserveDataLegacy.currentLiquidityRate;
    tempReserveData.variableBorrowIndex = reserveDataLegacy.variableBorrowIndex;
    tempReserveData.currentVariableBorrowRate = reserveDataLegacy.currentVariableBorrowRate;
    tempReserveData.lastUpdateTimestamp = reserveDataLegacy.lastUpdateTimestamp;
    tempReserveData.id = reserveDataLegacy.id;
    tempReserveData.aTokenAddress = reserveDataLegacy.aTokenAddress;
    tempReserveData.variableDebtTokenAddress = reserveDataLegacy.variableDebtTokenAddress;
    tempReserveData.__deprecatedInterestRateStrategyAddress = reserveDataLegacy
      .interestRateStrategyAddress;
    tempReserveData.accruedToTreasury = reserveDataLegacy.accruedToTreasury;
    tempReserveData.isolationModeTotalDebt = reserveDataLegacy.isolationModeTotalDebt;
    tempReserveData.virtualUnderlyingBalance = uint128(
      contracts.poolProxy.getVirtualUnderlyingBalance(asset)
    );
    tempReserveData.deficit = uint128(contracts.poolProxy.getReserveDeficit(asset));
    return tempReserveData;
  }
}
