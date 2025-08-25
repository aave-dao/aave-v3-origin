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

contract PoolEModeBorrowableTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  address rando = makeAddr('randomUser');

  /**
   * All tests assume a:
   * eMode 1 borrowable wbtc, usdx
   * eMode 2 borrowable wbtc
   */
  function setUp() public virtual {
    initTestEnvironment(false);

    vm.startPrank(poolAdmin);
    EModeCategoryInput memory ct1 = _genCategoryOne();
    EModeCategoryInput memory ct2 = _genCategoryTwo();

    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setEModeCategory(ct2.id, ct2.ltv, ct2.lt, ct2.lb, ct2.label);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.usdx, 1, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 1, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 2, true);
    vm.stopPrank();

    _supplyAndEnableAsCollateral(rando, 100 ether, tokenList.weth);
    _supplyAndEnableAsCollateral(rando, 1_000_000e6, tokenList.usdx);
    _supplyAndEnableAsCollateral(rando, 100e8, tokenList.wbtc);
  }

  /**
   * @dev You should be able to enter and leave eModes if all your borrowed assets are supported.
   */
  function test_shouldAllow_switchingEmodesIfAssetAllowedInTargetEmode() external {
    _supplyAndEnableAsCollateral(alice, 30_000e6, tokenList.usdx);
    vm.startPrank(alice);

    // both eMode 1 and 2 allow wbtc borrowing
    contracts.poolProxy.setUserEMode(1);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 2, 0, alice);
    contracts.poolProxy.setUserEMode(2);
    contracts.poolProxy.setUserEMode(0);
  }

  /**
   * @dev You should not be able to enter and leave eModes if any of your borrowed assets is not supported.
   */
  function test_shouldRevert_switchingEmodesIfAssetNotAllowedInTargetEmode() external {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveBorrowing(tokenList.usdx, false);
    _supplyAndEnableAsCollateral(alice, 30_000e6, tokenList.usdx);
    vm.startPrank(alice);

    contracts.poolProxy.setUserEMode(1);
    contracts.poolProxy.borrow(tokenList.usdx, 100e6, 2, 0, alice);
    // not borrowable insode eMode 2
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidDebtInEmode.selector, tokenList.usdx));
    contracts.poolProxy.setUserEMode(2);
    // not borrowable outside eMode
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidDebtInEmode.selector, tokenList.usdx));
    contracts.poolProxy.setUserEMode(0);
  }

  /**
   * @dev You should only be able to borrow assets allowed in your eMode.
   */
  function test_shouldRevert_BorrowingIfNotBorrowableInEmode() external {
    _supplyAndEnableAsCollateral(alice, 30_000e6, tokenList.usdx);
    vm.startPrank(alice);

    contracts.poolProxy.setUserEMode(2);
    vm.expectRevert(abi.encodeWithSelector(Errors.NotBorrowableInEMode.selector));
    contracts.poolProxy.borrow(tokenList.usdx, 100e6, 2, 0, alice);
  }

  /**
   * @dev It should be possible to borrow an asset inside eMode,
   * even if it is not possible to borrow the asset outside.
   * This behavior was introduced in Aave v3.4
   */
  function test_shouldAllow_borrowingWithinEmodeWhenNotBorrowablOutside() external {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveBorrowing(tokenList.wbtc, false);
    _supplyAndEnableAsCollateral(alice, 30_000e6, tokenList.usdx);
    vm.startPrank(alice);

    // reverts outside eMode
    vm.expectRevert(abi.encodeWithSelector(Errors.BorrowingNotEnabled.selector));
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 2, 0, alice);

    // succeeds within
    contracts.poolProxy.setUserEMode(1);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 2, 0, alice);
  }

  /**
   * @dev While it is possible that an asset becomes non borrowable inside an eMode,
   * it should be impossible to increase exposure.
   */
  function test_shouldRevert_borrowingAssetThatIsNoLongerBorrowable() external {
    _supplyAndEnableAsCollateral(alice, 30_000e6, tokenList.usdx);
    vm.startPrank(alice);
    contracts.poolProxy.setUserEMode(1);
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 2, 0, alice);
    vm.stopPrank();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 1, false);

    vm.startPrank(alice);
    vm.expectRevert(abi.encodeWithSelector(Errors.NotBorrowableInEMode.selector));
    contracts.poolProxy.borrow(tokenList.wbtc, 0.2e8, 2, 0, alice);
  }
}
