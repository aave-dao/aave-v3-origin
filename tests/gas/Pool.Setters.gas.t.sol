// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';

/**
 * Scenario suite for pool setter operations.
 */
/// forge-config: default.isolate = true
contract PoolSetters_gas_Tests is Testhelpers {
  // mock users to supply and borrow liquidity
  address user = makeAddr('user');

  function test_setUserEMode() external {
    vm.startPrank(poolAdmin);
    EModeCategoryInput memory ct1 = _genCategoryOne();
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.weth, ct1.id, true);
    vm.stopPrank();
    _supplyOnReserve(address(this), 0.5 ether, tokenList.weth);

    _supplyOnReserve(user, 5000e6, tokenList.usdx);
    vm.startPrank(user);
    contracts.poolProxy.borrow(tokenList.weth, 0.5 ether, 2, 0, user);

    _skip(100);

    contracts.poolProxy.setUserEMode(1);
    vm.snapshotGasLastCall('Pool.Setters', 'setUserEMode: enter eMode, 1 borrow, 1 supply');

    _skip(100);

    contracts.poolProxy.setUserEMode(0);
    vm.snapshotGasLastCall('Pool.Setters', 'setUserEMode: leave eMode, 1 borrow, 1 supply');
  }

  function test_setUserEModeOnBehalfOf() external {
    vm.startPrank(poolAdmin);
    EModeCategoryInput memory ct1 = _genCategoryOne();
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.weth, ct1.id, true);
    vm.stopPrank();

    _supplyAndEnableAsCollateral(user, 5000e6, tokenList.usdx);

    vm.startPrank(user);
    contracts.poolProxy.borrow(tokenList.weth, 0.5 ether, 2, 0, user);

    contracts.poolProxy.approvePositionManager(address(this), true);
    vm.stopPrank();

    _skip(100);

    contracts.poolProxy.setUserEModeOnBehalfOf(1, user);
    vm.snapshotGasLastCall(
      'Pool.Setters',
      'setUserEModeOnBehalfOf: enter eMode, 1 borrow, 1 supply'
    );

    _skip(100);

    contracts.poolProxy.setUserEModeOnBehalfOf(0, user);
    vm.snapshotGasLastCall(
      'Pool.Setters',
      'setUserEModeOnBehalfOf: leave eMode, 1 borrow, 1 supply'
    );
  }

  function test_setUserUseReserveAsCollateral() external {
    _supplyOnReserve(address(this), 5000e6, tokenList.usdx);

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.usdx, false);
    vm.snapshotGasLastCall(
      'Pool.Setters',
      'setUserUseReserveAsCollateral: disableCollateral, 1 supply'
    );

    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.usdx, true);
    vm.snapshotGasLastCall(
      'Pool.Setters',
      'setUserUseReserveAsCollateral: enableCollateral, 1 supply'
    );
  }

  function test_setUserUseReserveAsCollateralonBehalfOf() external {
    _supplyOnReserve(user, 5000e6, tokenList.usdx);

    vm.prank(user);
    contracts.poolProxy.approvePositionManager(address(this), true);

    contracts.poolProxy.setUserUseReserveAsCollateralOnBehalfOf(tokenList.usdx, false, user);
    vm.snapshotGasLastCall(
      'Pool.Setters',
      'setUserUseReserveAsCollateralOnBehalfOf: disableCollateral, 1 supply'
    );

    contracts.poolProxy.setUserUseReserveAsCollateralOnBehalfOf(tokenList.usdx, true, user);
    vm.snapshotGasLastCall(
      'Pool.Setters',
      'setUserUseReserveAsCollateralOnBehalfOf: enableCollateral, 1 supply'
    );
  }
}
