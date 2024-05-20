// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from 'aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract PoolConfiguratorPendingLtvTests is TestnetProcedures {
  event PendingLtvChanged(address indexed asset, uint256 ltv);

  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  function setUp() public {
    initTestEnvironment();
  }

  function test_freezeReserve_ltvSetTo0() public {
    // check current ltv
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

    assertTrue(ltv > 0);
    assertEq(isFrozen, false);

    // expect events to be emitted
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit PendingLtvChanged(tokenList.usdx, ltv);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit CollateralConfigurationChanged(tokenList.usdx, 0, liquidationThreshold, liquidationBonus);

    // freeze reserve
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    // check ltv = 0
    (, uint256 updatedltv, , , , , , , , bool updatedIsFrozen) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(tokenList.usdx);
    assertEq(updatedltv, 0);
    assertEq(updatedIsFrozen, true);

    // check pending ltv is set
    (uint256 pendingLtv, bool isPendingLtvSet) = contracts.poolConfiguratorProxy.getPendingLtv(
      tokenList.usdx
    );

    assertEq(pendingLtv, ltv);
    assertEq(isPendingLtvSet, true);
  }

  function test_unfreezeReserve_pendingSetToLtv() public {
    // check ltv
    (
      ,
      uint256 originalLtv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      ,
      ,
      ,
      ,
      ,

    ) = contracts.protocolDataProvider.getReserveConfigurationData(tokenList.usdx);

    // freeze reserve
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    // check ltv
    (, uint256 ltv, , , , , , , , bool isFrozen) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(tokenList.usdx);

    assertEq(ltv, 0);
    assertEq(isFrozen, true);

    // check pending ltv
    (uint256 pendingLtv, ) = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit CollateralConfigurationChanged(
      tokenList.usdx,
      originalLtv,
      liquidationThreshold,
      liquidationBonus
    );

    // unfreeze reserve
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, false);

    // check ltv is set back
    (, uint256 updatedLtv, , , , , , , , bool updatedIsFrozen) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(tokenList.usdx);

    assertEq(updatedLtv, originalLtv);
    assertEq(updatedLtv, pendingLtv);
    assertEq(updatedIsFrozen, false);

    // check pending ltv is set to zero
    (uint256 updatedPendingLtv, bool updatedIsPendingLtvSet) = contracts
      .poolConfiguratorProxy
      .getPendingLtv(tokenList.usdx);

    assertEq(updatedPendingLtv, 0);
    assertEq(updatedIsPendingLtvSet, false);

    vm.stopPrank();
  }

  function test_setLtvToFrozen_ltvSetToPending(uint256 originalLtv, uint256 ltvToSet) public {
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
    (uint256 pendingLtv, ) = contracts.poolConfiguratorProxy.getPendingLtv(tokenList.usdx);
    assertEq(pendingLtv, originalLtv);

    // expect events to be emitted
    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit PendingLtvChanged(tokenList.usdx, ltvToSet);

    vm.expectEmit(address(contracts.poolConfiguratorProxy));
    emit CollateralConfigurationChanged(tokenList.usdx, 0, liquidationThreshold, liquidationBonus);

    // setLtv
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      tokenList.usdx,
      ltvToSet,
      liquidationThreshold,
      liquidationBonus
    );

    // check ltv is still 0
    (, uint256 ltv, , , , , , , , ) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );

    assertEq(ltv, 0);

    // check pending ltv
    (uint256 updatedPendingLtv, bool updatedIsPendingLtvSet) = contracts
      .poolConfiguratorProxy
      .getPendingLtv(tokenList.usdx);

    assertEq(updatedPendingLtv, ltvToSet);
    assertEq(updatedIsPendingLtvSet, true);

    vm.stopPrank();
  }

  function test_setLtv_ltvSet(uint256 ltvToSet) public {
    uint256 liquidationThreshold = 86_00;
    uint256 liquidationBonus = 10_500;

    vm.assume(ltvToSet > 0);
    vm.assume(ltvToSet < liquidationThreshold);

    vm.startPrank(poolAdmin);

    // setLtv
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(
      tokenList.usdx,
      ltvToSet,
      liquidationThreshold,
      liquidationBonus
    );

    // check ltv is updated
    (, uint256 ltv, , , , , , , , ) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );

    assertEq(ltv, ltvToSet);

    vm.stopPrank();
  }
}
