// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'forge-std/StdStorage.sol';

import {IPriceOracleGetter} from '../../../src/contracts/interfaces/IPriceOracleGetter.sol';
import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {IPool, DataTypes} from '../../../src/contracts/interfaces/IPool.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {PoolInstance} from '../../../src/contracts/instances/PoolInstance.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {EModeConfiguration} from '../../../src/contracts/protocol/libraries/configuration/EModeConfiguration.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {PercentageMath} from '../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {LiquidationHelper} from '../../helpers/LiquidationHelper.sol';

contract PoolEModeLtvzeroTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  address rando = makeAddr('randomUser');

  /**
   * All tests assume a:
   * eMode 1 collaterals wbtc, usdx
   * eMode 2 collaterals usdx, usdx is ltv0 though
   */
  function setUp() public virtual {
    initTestEnvironment(false);

    vm.startPrank(poolAdmin);
    EModeCategoryInput memory ct1 = _genCategoryOne();
    EModeCategoryInput memory ct2 = _genCategoryTwo();

    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setEModeCategory(ct2.id, ct2.ltv, ct2.lt, ct2.lb, ct2.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 1, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, 1, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 2, true);
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, 2, true);
    vm.stopPrank();
  }

  function test_shouldApplyEmodeLtv0Lt() external {
    _supplyAndEnableAsCollateral(tokenList.usdx, 30_000e6, alice);

    (, , , uint256 ltBefore, , ) = contracts.poolProxy.getUserAccountData(alice);

    vm.prank(alice);
    contracts.poolProxy.setUserEMode(1);
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, 1, true);

    (, , , uint256 ltAfter, uint256 ltvAfter, ) = contracts.poolProxy.getUserAccountData(alice);
    assertGt(ltAfter, ltBefore);
    assertEq(ltvAfter, 0);

    EModeCategoryInput memory ct1 = _genCategoryOne();
    assertEq(ltAfter, ct1.lt);
  }

  /**
   * @dev You should be able to enter and leave eModes as long as the ltv0asset is not enabled as collateral.
   */
  function test_shouldAllow_enteringEmodeWhenLtv0AssetIsNoCollateral() external {
    _supply(tokenList.usdx, 30_000e6, alice);
    vm.startPrank(alice);
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.usdx, false);

    // as long as it's not enabled as collateral, swithcing eModes is permitted
    contracts.poolProxy.setUserEMode(1);
    contracts.poolProxy.setUserEMode(2); // usdc is ltvzero here, but asset is disabled as collateral
    contracts.poolProxy.setUserEMode(0);
  }

  /**
   * @dev You should be able to enter and leave eModes as long as the ltv0asset is not enabled as collateral.
   */
  function test_shouldRevert_enteringEmodeWhenLtv0AssetIsCollateral() external {
    _supplyAndEnableAsCollateral(tokenList.usdx, 30_000e6, alice);
    vm.startPrank(alice);

    // will revert when entering eMode 2, because it's ltvzero there
    contracts.poolProxy.setUserEMode(1);
    vm.expectRevert(
      abi.encodeWithSelector(Errors.InvalidCollateralInEmode.selector, tokenList.usdx)
    );
    contracts.poolProxy.setUserEMode(2);
    contracts.poolProxy.setUserEMode(0);
  }

  function test_shouldAllow_leavingEmodeToANonLtv0Emode() external {
    _supplyAndEnableAsCollateral(tokenList.usdx, 30_000e6, alice);
    vm.prank(alice);
    contracts.poolProxy.setUserEMode(1);

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, 2, false);
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, 1, true);
    vm.stopPrank();

    vm.startPrank(alice);
    // leaving the eMode is fine
    contracts.poolProxy.setUserEMode(2);
    contracts.poolProxy.setUserEMode(0);
    // reentering is not
    vm.expectRevert(
      abi.encodeWithSelector(Errors.InvalidCollateralInEmode.selector, tokenList.usdx)
    );
    contracts.poolProxy.setUserEMode(1);
  }

  function test_shouldRevert_leavingToEmode0IfLtv0() external {
    _supplyAndEnableAsCollateral(tokenList.usdx, 30_000e6, alice);
    vm.prank(alice);
    contracts.poolProxy.setUserEMode(1);

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(tokenList.usdx, 0, 100, 10050);
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, 1, true);
    vm.stopPrank();

    vm.startPrank(alice);
    vm.expectRevert(
      abi.encodeWithSelector(Errors.InvalidCollateralInEmode.selector, tokenList.usdx)
    );
    contracts.poolProxy.setUserEMode(2);
    vm.expectRevert(
      abi.encodeWithSelector(Errors.InvalidCollateralInEmode.selector, tokenList.usdx)
    );
    contracts.poolProxy.setUserEMode(0);
  }

  /**
   * When a user has multiple collaterals, he must withdraw the ltv0 first
   */
  function test_ltvzero_shouldEnforcePriorityWithdrawal() external {
    _supplyAndEnableAsCollateral(tokenList.usdx, 30_000e6, alice);
    _supplyAndEnableAsCollateral(tokenList.wbtc, 1e8, alice);
    vm.prank(alice);
    contracts.poolProxy.setUserEMode(1);

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, 1, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.usdx, 1, true);
    vm.stopPrank();

    // should allow as alice has no borrows
    vm.startPrank(alice);
    contracts.poolProxy.withdraw(tokenList.wbtc, 0.1e8, alice);

    contracts.poolProxy.borrow(tokenList.usdx, 1e6, 2, 0, alice);
    // should now revert as ltvzero asset has to be withdrawn or disabled first
    vm.expectRevert(abi.encodeWithSelector(Errors.LtvValidationFailed.selector));
    contracts.poolProxy.withdraw(tokenList.wbtc, 0.1e8, alice);

    // should allow as withdrawing ltv0 assets is fine
    contracts.poolProxy.withdraw(tokenList.usdx, 1e6, alice);

    // with collateral being disabled, withdrawing is allowed again
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.usdx, false);
    contracts.poolProxy.withdraw(tokenList.wbtc, 0.1e8, alice);
  }

  function test_freezingLTV0Asset() external {
    vm.startPrank(poolAdmin);
    // create eMode without usdx as collateral
    EModeCategoryInput memory ct2 = _genCategoryTwo();
    contracts.poolConfiguratorProxy.setEModeCategory(3, ct2.ltv, ct2.lt, ct2.lb, ct2.label);

    // freezing should set ltv0 to true, on all eModes with the collateral enabled
    contracts.poolConfiguratorProxy.setReserveFreeze(tokenList.usdx, true);

    uint128 eMode1 = contracts.poolProxy.getEModeCategoryLtvzeroBitmap(1); // was collateral
    uint128 eMode2 = contracts.poolProxy.getEModeCategoryLtvzeroBitmap(2); // was already ltvzero
    uint128 eMode3 = contracts.poolProxy.getEModeCategoryLtvzeroBitmap(3); // does not have the asset as collateral at all

    _checkFlag(eMode1, tokenList.usdx, true);
    _checkFlag(eMode2, tokenList.usdx, true);
    _checkFlag(eMode3, tokenList.usdx, false);

    // changing the ltv0 flag should revert
    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveFrozen.selector));
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, 1, false);
    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveFrozen.selector));
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, 2, false);
    vm.expectRevert(abi.encodeWithSelector(Errors.MustBeEmodeCollateral.selector, tokenList.usdx));
    contracts.poolConfiguratorProxy.setAssetLtvzeroInEMode(tokenList.usdx, 3, false);

    // enabeling as collateral should revert
    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveFrozen.selector));
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 1, true);
  }

  function _checkFlag(uint128 bitmap, address reserve, bool enabled) internal view {
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(reserve);
    assertEq(EModeConfiguration.isReserveEnabledOnBitmap(bitmap, reserveData.id), enabled);
  }
}
