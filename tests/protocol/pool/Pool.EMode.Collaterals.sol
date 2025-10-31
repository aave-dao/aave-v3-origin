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
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {PercentageMath} from '../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {LiquidationHelper} from '../../helpers/LiquidationHelper.sol';

contract PoolEModeCollateralsTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  address rando = makeAddr('randomUser');

  /**
   * All tests assume a:
   * eMode 1 collaterals wbtc, usdx
   * eMode 2 collaterals usdx
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
    vm.stopPrank();
  }

  function test_shouldApplyEmodeLtvLt() external {
    _supplyAndEnableAsCollateral(tokenList.usdx, 30_000e6, alice);

    // in eMode 0 the default parameters should apply
    (, , , uint256 ltBefore, uint256 ltvBefore, ) = contracts.poolProxy.getUserAccountData(alice);
    (, uint256 assetBaseLTV, uint256 assetBaseLT, , , , , , , ) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(tokenList.usdx);
    assertEq(ltBefore, assetBaseLT);
    assertEq(ltvBefore, assetBaseLTV);

    // in eMode != 0 the eMode parameters should apply
    vm.startPrank(alice);
    contracts.poolProxy.setUserEMode(1);
    (, , , uint256 ltAfter, uint256 ltvAfter, ) = contracts.poolProxy.getUserAccountData(alice);
    assertGt(ltAfter, ltBefore);
    assertGt(ltvAfter, ltvBefore);

    EModeCategoryInput memory ct1 = _genCategoryOne();
    assertEq(ltAfter, ct1.lt);
    assertEq(ltvAfter, ct1.ltv);
  }

  /**
   * @dev You should be able to enter and leave eModes if all your collateral assets are supported.
   */
  function test_shouldAllow_switchingEmodesIfAssetAllowedInTargetEmode() external {
    _supplyAndEnableAsCollateral(tokenList.usdx, 30_000e6, alice);
    vm.startPrank(alice);

    // all eModes support usdx collateral
    contracts.poolProxy.setUserEMode(1);
    contracts.poolProxy.setUserEMode(2);
    contracts.poolProxy.setUserEMode(0);
  }

  /**
   * @dev You should not be able to enter and leave eModes if any of your collateral assets is not supported.
   */
  function test_shouldRevert_switchingEmodesIfAssetNotAllowedInTargetEmode() external {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(tokenList.wbtc, 0, 0, 0);
    _supply(tokenList.wbtc, 30_000e6, alice);
    vm.startPrank(alice);

    /**
     * It should be possible to enable an asset as collateral inside eMode,
     * even if it is not possible to enable the asset as collateral outside.
     * This behavior was introduced in Aave v3.4
     */
    vm.expectRevert(abi.encodeWithSelector(Errors.UserInIsolationModeOrLtvZero.selector));
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);
    contracts.poolProxy.setUserEMode(1);
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    // not collateral inside eMode 2
    vm.expectRevert(
      abi.encodeWithSelector(Errors.InvalidCollateralInEmode.selector, tokenList.wbtc)
    );
    contracts.poolProxy.setUserEMode(2);
    // not collateral outside eMode
    vm.expectRevert(
      abi.encodeWithSelector(Errors.InvalidCollateralInEmode.selector, tokenList.wbtc)
    );
    contracts.poolProxy.setUserEMode(0);
  }
}
