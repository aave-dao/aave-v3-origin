// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {DataTypes} from '../../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {IPoolConfigurator} from '../../../../src/contracts/interfaces/IPoolConfigurator.sol';
import {TestnetProcedures} from '../../../utils/TestnetProcedures.sol';

contract PoolConfiguratorPendingLtvTests is TestnetProcedures {
  function setUp() public {
    initTestEnvironment();
  }

  function test_freezeReserve_ltvSetTo0() public {
    // check current ltv
    (uint256 ltv, , , bool isFrozen) = _getReserveParams();

    assertTrue(ltv > 0);
    assertEq(isFrozen, false);

    // freeze reserve
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    // check ltv = 0
    (uint256 updatedltv, , , bool updatedIsFrozen) = _getReserveParams();
    assertEq(updatedltv, 0);
    assertEq(updatedIsFrozen, true);

    // check pending ltv is set
    uint256 pendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);

    assertEq(pendingLtv, ltv);
  }

  function test_freezeAndSet() public {
    (, uint256 lt, uint256 lb, ) = _getReserveParams();

    uint256 originalLTV = 100;

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    // changing the ltv on a frozen reserve should alter the pending ltv, but not the actual ltv
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      tokenList.usdx,
      originalLTV,
      lt,
      lb
    );
    (uint256 ltv, , , ) = _getReserveParams();
    assertEq(ltv, 0);
    uint256 pendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);
    assertEq(pendingLtv, originalLTV);

    // ltvzero cannot be removed from a frozen reserve
    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveFrozen.selector));
    contracts.poolConfiguratorProxy.setReserveLtvzero(tokenList.usdx, false);

    // ltv should not be restored automatically
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, false);
    (ltv, , , ) = _getReserveParams();
    assertEq(ltv, 0);

    uint256 snapshot = vm.snapshotState();

    // once unfrozen, setting the ltv should remove the pending ltv
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.PendingLtvChanged(tokenList.usdx, 0);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(tokenList.usdx, 500, lt, lb);
    (ltv, , , ) = _getReserveParams();
    assertEq(ltv, 500);
    pendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);
    assertEq(pendingLtv, 0);

    // disabling ltv0 should revert (as it's no longer ltv zero)
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidLtvzeroState.selector));
    contracts.poolConfiguratorProxy.setReserveLtvzero(tokenList.usdx, false);

    vm.revertToState(snapshot);

    // disabling ltv0 should apply the previous ltv and remove the pending ltv
    contracts.poolConfiguratorProxy.setReserveLtvzero(tokenList.usdx, false);
    (ltv, , , ) = _getReserveParams();
    assertEq(ltv, originalLTV);
    pendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);
    assertEq(pendingLtv, 0);
  }

  function test_freezingLTV0Asset() external {
    vm.startPrank(poolAdmin);
    (, uint256 lt, uint256 lb, ) = _getReserveParams();
    // freezing an asset with ltv0 already should not revert and pending should be 0
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(tokenList.usdx, 0, lt, lb);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);
    uint256 pendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);
    assertEq(pendingLtv, 0);
  }

  function test_unfreezeReserve_pendingSetToLtv() public {
    // check ltv
    (uint256 originalLtv, , , ) = _getReserveParams();

    // freeze reserve
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    // check ltv
    (uint256 ltv, , , bool isFrozen) = _getReserveParams();

    assertEq(ltv, 0);
    assertEq(isFrozen, true);

    // unfreeze reserve
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, false);

    // check ltv is set back
    (uint256 updatedLtv, , , bool updatedIsFrozen) = _getReserveParams();

    assertEq(updatedLtv, 0);
    assertEq(updatedIsFrozen, false);

    // check pending ltv is set to previous ltv
    uint256 updatedPendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);

    assertEq(updatedPendingLtv, originalLtv);

    // reset ltvzero
    contracts.poolConfiguratorProxy.setReserveLtvzero(tokenList.usdx, false);

    (uint256 updated2Ltv, , , bool updated2IsFrozen) = _getReserveParams();

    assertEq(updated2Ltv, originalLtv);
    assertEq(updated2IsFrozen, false);

    // check pending ltv is set to zero
    uint256 updated2PendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);

    assertEq(updated2PendingLtv, 0);

    vm.stopPrank();
  }

  function test_setLtvZero() external {
    (uint256 originalLtv, , , ) = _getReserveParams();

    vm.startPrank(poolAdmin);

    vm.expectRevert();
    contracts.poolConfiguratorProxy.setReserveLtvzero(tokenList.usdx, false);
    contracts.poolConfiguratorProxy.setReserveLtvzero(tokenList.usdx, true);

    (uint256 currentLtv, , , ) = _getReserveParams();
    uint256 pendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);

    assertEq(currentLtv, 0);
    assertEq(pendingLtv, originalLtv);

    vm.expectRevert();
    contracts.poolConfiguratorProxy.setReserveLtvzero(tokenList.usdx, true);
    contracts.poolConfiguratorProxy.setReserveLtvzero(tokenList.usdx, false);

    (currentLtv, , , ) = _getReserveParams();
    pendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);

    assertEq(currentLtv, originalLtv);
    assertEq(pendingLtv, 0);

    vm.stopPrank();
  }

  // freeze reserve, set ltv, unfreeze reserve
  function test_setLtv_ltvSetPendingLtvSet(uint256 originalLtv, uint256 ltvToSet) public {
    uint256 liquidationThreshold = 86_00;
    uint256 liquidationBonus = 10_500;

    vm.assume(originalLtv > 0);
    vm.assume(originalLtv < liquidationThreshold);

    vm.assume(ltvToSet > 0);
    vm.assume(ltvToSet < liquidationThreshold);
    vm.assume(ltvToSet != originalLtv);

    // set original ltv
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      tokenList.usdx,
      originalLtv,
      liquidationThreshold,
      liquidationBonus
    );

    // freeze reserve
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    // check pending ltv
    uint256 pendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);
    assertEq(pendingLtv, originalLtv);

    // expect events to be emitted
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.PendingLtvChanged(tokenList.usdx, ltvToSet);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit IPoolConfigurator.CollateralConfigurationChanged(
      tokenList.usdx,
      0,
      liquidationThreshold,
      liquidationBonus
    );

    // setLtv
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      tokenList.usdx,
      ltvToSet,
      liquidationThreshold,
      liquidationBonus
    );

    // check ltv is still 0
    (uint256 ltv, , , ) = _getReserveParams();
    assertEq(ltv, 0);

    // check pending ltv
    uint256 updatedPendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);
    assertEq(updatedPendingLtv, ltvToSet);

    // unfreeze reserve
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, false);

    // check pending ltv is set to zero
    uint256 finalPendingLtv = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);
    assertEq(finalPendingLtv, ltvToSet);

    vm.stopPrank();
  }

  function _getReserveParams() internal view returns (uint256, uint256, uint256, bool) {
    (
      ,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      ,
      ,
      ,
      ,
      ,
      bool isFrozen
    ) = contracts.protocolDataProvider.getReserveConfigurationData(tokenList.usdx);

    return (ltv, liquidationThreshold, liquidationBonus, isFrozen);
  }
}
