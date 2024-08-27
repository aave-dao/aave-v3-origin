// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ConfiguratorInputTypes} from '../../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {TestnetProcedures, TestVars} from '../../../utils/TestnetProcedures.sol';

contract PoolConfiguratorACLModifiersTest is TestnetProcedures {
  function setUp() public {
    initTestEnvironment();
  }

  function test_reverts_notAdmin_initReserves(TestVars memory t, address caller) public {
    ConfiguratorInputTypes.InitReserveInput[] memory input = _generateInitConfig(
      t,
      report,
      poolAdmin,
      true
    );
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isAssetListingAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.initReserves(input);
  }

  function test_reverts_notAdmin_dropReserve(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.dropReserve(tokenList.usdx);
  }

  function test_reverts_notAdmin_updateAToken(address caller) public {
    ConfiguratorInputTypes.UpdateATokenInput memory input;
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.updateAToken(input);
  }

  function test_reverts_notAdmin_updateVariableDebtToken(address caller) public {
    ConfiguratorInputTypes.UpdateDebtTokenInput memory input;
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.updateVariableDebtToken(input);
  }

  function test_reverts_notAdmin_setReserveActive(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.usdx, true);
  }

  function test_reverts_notAdmin_updateFlashLoanPremiumTotal(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.updateFlashloanPremiumTotal(1);
  }

  function test_reverts_notAdmin_updateFlashLoanPremiumProtocol(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.updateFlashloanPremiumToProtocol(1);
  }

  function test_reverts_notRiskAdmin_setReserveBorrowing(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setReserveBorrowing(address(0), true);
  }

  function test_reverts_notRiskAdmin_configureReserveAsCollateral(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(address(0), 1, 1, 1);
  }

  function test_reverts_notRiskOrPoolOrEmergencyAdmin_setReserveFreeze(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        !contracts.aclManager.isEmergencyAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setReserveFreeze(address(0), true);
  }

  function test_reverts_notRiskAdmin_setReserveFactor(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setReserveFactor(address(0), 10);
  }

  function test_reverts_notRiskAdmin_setBorrowCap(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setBorrowCap(address(0), 10);
  }

  function test_reverts_notRiskAdmin_setSupplyCap(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setSupplyCap(address(0), 10);
  }

  function test_reverts_notRiskAdmin_setReserveInterestRateStrategyAddress(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setReserveInterestRateStrategyAddress(
      address(0),
      address(0),
      bytes('0')
    );
  }

  function test_reverts_notRiskAdmin_setReserveInterestRateData(
    address caller,
    address asset
  ) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setReserveInterestRateData(asset, bytes('0'));
  }

  function test_reverts_notRiskAdmin_setEModeCategory(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 1, 1, 1, '');
  }

  function test_reverts_notRiskAdmin_setAssetCollateralInEMode(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(address(0), 1, true);
  }

  function test_reverts_setDebtCeiling(address caller) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isRiskAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(caller);
    contracts.poolConfiguratorProxy.setDebtCeiling(address(0), 1);
  }

  function test_reverts_setReservePause_on_unauth(
    address caller,
    address asset,
    bool paused,
    uint40 gracePeriod
  ) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isEmergencyAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.prank(caller);
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN));
    contracts.poolConfiguratorProxy.setReservePause(asset, paused, gracePeriod);
  }

  function test_reverts_setReservePause_off_unauth(
    address caller,
    address asset,
    bool paused,
    uint40 gracePeriod
  ) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isEmergencyAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.prank(caller);
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN));
    contracts.poolConfiguratorProxy.setReservePause(asset, paused, gracePeriod);
  }

  function test_reverts_setReservePause_noGracePeriod_off_unauth(
    address caller,
    address asset,
    bool paused
  ) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isEmergencyAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.prank(caller);
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN));
    contracts.poolConfiguratorProxy.setReservePause(asset, paused);
  }

  function test_reverts_disableLiquidationGracePeriod_on_unauth(
    address caller,
    address asset
  ) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isEmergencyAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.prank(caller);

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN));
    contracts.poolConfiguratorProxy.disableLiquidationGracePeriod(asset);
  }

  function test_reverts_setPoolPause_unauth(
    address caller,
    bool paused,
    uint40 gracePeriod
  ) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isEmergencyAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.prank(caller);
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN));
    contracts.poolConfiguratorProxy.setPoolPause(paused, gracePeriod);

    vm.prank(caller);
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN));
    contracts.poolConfiguratorProxy.setPoolPause(paused);
  }

  function test_reverts_setPoolPause_noGracePeriod_unauth(address caller, bool paused) public {
    vm.assume(
      !contracts.aclManager.isPoolAdmin(caller) &&
        !contracts.aclManager.isEmergencyAdmin(caller) &&
        caller != address(contracts.poolAddressesProvider)
    );

    vm.prank(caller);
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN));
    contracts.poolConfiguratorProxy.setPoolPause(paused);
  }
}
