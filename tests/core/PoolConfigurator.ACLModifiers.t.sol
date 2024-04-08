// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from 'aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import {ConfiguratorInputTypes} from 'aave-v3-core/contracts/protocol/pool/PoolConfigurator.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract PoolConfiguratorACLModifiersTest is TestnetProcedures {
  function setUp() public {
    initTestEnvironment();
  }

  function test_reverts_notAdmin_initReserves() public {
    ConfiguratorInputTypes.InitReserveInput[] memory input;
    vm.expectRevert(bytes(Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.initReserves(input);
  }

  function test_reverts_notAdmin_dropReserve() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.dropReserve(tokenList.usdx);
  }

  function test_reverts_notAdmin_updateAToken() public {
    ConfiguratorInputTypes.UpdateATokenInput memory input;

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.updateAToken(input);
  }

  function test_reverts_notAdmin_updateVariableDebtToken() public {
    ConfiguratorInputTypes.UpdateDebtTokenInput memory input;

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.updateVariableDebtToken(input);
  }

  function test_reverts_notAdmin_updateStableDebtToken() public {
    ConfiguratorInputTypes.UpdateDebtTokenInput memory input;

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.updateStableDebtToken(input);
  }

  function test_reverts_notAdmin_setReserveActive() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.usdx, true);
  }

  function test_reverts_notAdmin_updateFlashLoanPremiumTotal() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.updateFlashloanPremiumTotal(1);
  }

  function test_reverts_notAdmin_updateFlashLoanPremiumProtocol() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.updateFlashloanPremiumToProtocol(1);
  }

  function test_reverts_notRiskAdmin_setReserveBorrowing() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setReserveBorrowing(address(0), true);
  }

  function test_reverts_notRiskAdmin_configureReserveAsCollateral() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(address(0), 1, 1, 1);
  }

  function test_reverts_notRiskAdmin_setReserveStableRateBorrowing() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setReserveStableRateBorrowing(address(0), true);
  }

  function test_reverts_notRiskOrPoolOrEmergencyAdmin_setReserveFreeze() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setReserveFreeze(address(0), true);
  }

  function test_reverts_notRiskAdmin_setReserveFactor() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setReserveFactor(address(0), 10);
  }

  function test_reverts_notRiskAdmin_setBorrowCap() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setBorrowCap(address(0), 10);
  }

  function test_reverts_notRiskAdmin_setSupplyCap() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setSupplyCap(address(0), 10);
  }

  function test_reverts_notRiskAdmin_setReserveInterestRateStrategyAddress() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setReserveInterestRateStrategyAddress(
      address(0),
      address(0),
      bytes('0')
    );
  }

  function test_reverts_notRiskAdmin_setEModeCategory() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 1, 1, 1, address(0), '');
  }

  function test_reverts_notRiskAdmin_setAssetEModeCategory() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
    contracts.poolConfiguratorProxy.setAssetEModeCategory(address(0), 1);
  }

  function test_reverts_setDebtCeiling() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_RISK_OR_POOL_ADMIN));

    vm.prank(alice);
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
