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

contract PoolEModeTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  event UserEModeSet(address indexed user, uint8 categoryId);

  IPool internal pool;

  function setUp() public virtual {
    initTestEnvironment(false);

    pool = PoolInstance(report.poolProxy);
  }

  function test_setUserEMode_shouldRevertForNonExistingEmode() public {
    vm.prank(alice);
    vm.expectRevert(bytes(Errors.INCONSISTENT_EMODE_CATEGORY));
    pool.setUserEMode(1);
  }

  function test_getUserEMode_shouldReflectEMode() public {
    vm.startPrank(poolAdmin);
    EModeCategoryInput memory ct1 = _genCategoryOne();
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct1.id, true);
    vm.stopPrank();

    vm.expectEmit(address(pool));
    emit UserEModeSet(alice, ct1.id);
    vm.prank(alice);
    pool.setUserEMode(ct1.id);

    assertEq(pool.getUserEMode(alice), ct1.id);
  }

  function test_reenterSameEmode_shouldSucceed() public {
    test_getUserEMode_shouldReflectEMode();

    assertEq(pool.getUserEMode(alice), 1);
    vm.prank(alice);
    pool.setUserEMode(1);
    assertEq(pool.getUserEMode(alice), 1);
  }

  function test_getUserAccountData_shouldReflectEmodeParams() public {
    vm.startPrank(poolAdmin);
    EModeCategoryInput memory ct1 = _genCategoryOne();
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct1.id, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.setUserEMode(ct1.id);
    // supply some dust so the eMode asset is the only collateral
    _mintTestnetToken(tokenList.usdx, alice, 1);
    _supplyToPool(tokenList.usdx, alice, 1);

    (, , , uint256 emodeLT, uint256 emodeLTV, ) = contracts.poolProxy.getUserAccountData(alice);
    assertEq(emodeLT, ct1.lt);
    assertEq(emodeLTV, ct1.ltv);

    vm.prank(alice);
    pool.setUserEMode(0);
    (, uint256 assetBaseLTV, uint256 assetBaseLT, , , , , , , ) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(tokenList.usdx);
    (, , , uint256 baseLT, uint256 baseLTV, ) = contracts.poolProxy.getUserAccountData(alice);
    assertEq(assetBaseLTV, baseLTV);
    assertEq(assetBaseLT, baseLT);
  }

  function test_getUserAccountData_shouldReflectMixedCollateral() public {
    vm.startPrank(poolAdmin);
    EModeCategoryInput memory ct1 = _genCategoryOne();
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct1.id, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.setUserEMode(ct1.id);
    // supply some dust so the eMode asset is the only collateral
    _mintTestnetToken(tokenList.usdx, alice, 1e6);
    _supplyToPool(tokenList.usdx, alice, 1e6);
    // supply some non eMode asset
    _mintTestnetToken(tokenList.wbtc, alice, 1e8);
    _supplyToPool(tokenList.wbtc, alice, 1e8);

    (, , , uint256 realLT, uint256 realLTV, ) = contracts.poolProxy.getUserAccountData(alice);
    assertLt(realLT, ct1.lt);
    assertLt(realLTV, ct1.ltv);
  }

  function test_setUserEMode_shouldAllowSwitchingIfNoBorrows(uint8 eMode) public {
    uint256 AVAILABLE_EMODES = 2;
    EModeCategoryInput memory ct1 = _genCategoryOne();
    EModeCategoryInput memory ct2 = _genCategoryTwo();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setEModeCategory(ct2.id, ct2.ltv, ct2.lt, ct2.lb, ct2.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct2.id, true);
    vm.stopPrank();

    eMode = uint8(bound(eMode, 0, AVAILABLE_EMODES));
    vm.prank(alice);
    pool.setUserEMode(eMode);
    eMode = uint8(bound(eMode + 1, 0, AVAILABLE_EMODES));
    vm.prank(alice);
    pool.setUserEMode(eMode);
    assertEq(pool.getUserEMode(alice), eMode);
  }

  function test_setUserEmode_shouldAllowSwitchingWhenAssetIsBorrowableInEmode(
    uint104 amount
  ) public {
    amount = uint104(bound(amount, 1 ether, type(uint104).max));
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 9000, 9200, 10050, 'usdx eMode low');
    contracts.poolConfiguratorProxy.setEModeCategory(2, 9000, 9700, 10050, 'usdx eMode high');
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 1, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 2, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 1, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 2, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.setUserEMode(1);
    _mintTestnetToken(tokenList.usdx, alice, amount);
    _supplyToPool(tokenList.usdx, alice, amount);
    _borrowMaxLt(tokenList.wbtc, alice);

    (, , , , , uint256 hfBefore) = contracts.poolProxy.getUserAccountData(alice);
    vm.prank(alice);
    pool.setUserEMode(2);
    (, , , , , uint256 hfAfter) = contracts.poolProxy.getUserAccountData(alice);
    assertLt(hfBefore, hfAfter);
  }

  function test_setUserEmode_shouldRevertIfHfWouldFallBelow1(uint104 amount) public {
    amount = uint104(bound(amount, 1 ether, type(uint104).max));
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 9000, 9200, 10050, 'usdx eMode low');
    contracts.poolConfiguratorProxy.setEModeCategory(2, 9000, 9700, 10050, 'usdx eMode high');
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 1, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 2, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 1, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 2, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.setUserEMode(2);
    _mintTestnetToken(tokenList.usdx, alice, amount);
    _supplyToPool(tokenList.usdx, alice, amount);
    _borrowMaxLt(tokenList.wbtc, alice);

    vm.prank(alice);
    vm.expectRevert(bytes(Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD));
    pool.setUserEMode(1);
  }

  function test_setUserEmode_shouldRevertIfAssetNoLongerBorrowable(uint104 amount) public {
    amount = uint104(bound(amount, 1 ether, type(uint104).max));
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(1, 9000, 9200, 10050, 'usdx eMode low');
    contracts.poolConfiguratorProxy.setEModeCategory(2, 9000, 9700, 10050, 'usdx eMode high');
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 1, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 2, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 1, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.setUserEMode(1);
    _mintTestnetToken(tokenList.usdx, alice, amount);
    _supplyToPool(tokenList.usdx, alice, amount);
    _borrowMaxLt(tokenList.wbtc, alice);

    vm.prank(alice);
    vm.expectRevert(bytes(Errors.NOT_BORROWABLE_IN_EMODE));
    pool.setUserEMode(2);
  }

  function test_borrowing_shouldRevert_ifNonBorrowableOutsideEmode(uint256 amount) public {
    amount = bound(amount, 1 ether, type(uint104).max);
    vm.startPrank(poolAdmin);
    uint16 liquidationBonus = 10050;
    contracts.poolConfiguratorProxy.setEModeCategory(
      1,
      9000,
      9200,
      liquidationBonus,
      'usdx eMode low'
    );
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 1, true);
    contracts.poolConfiguratorProxy.setReserveBorrowing(tokenList.wbtc, false);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 1, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.setUserEMode(1);
    _mintTestnetToken(tokenList.usdx, alice, amount);
    _supplyToPool(tokenList.usdx, alice, amount);

    vm.prank(alice);
    vm.expectRevert(bytes(Errors.BORROWING_NOT_ENABLED));
    contracts.poolProxy.borrow(tokenList.wbtc, 1, 2, 0, alice);
  }

  function test_liquidations_shouldApplyEModeLBForEmodeAssets(uint256 amount) public {
    amount = bound(amount, 1 ether, type(uint104).max);
    vm.startPrank(poolAdmin);
    uint16 liquidationBonus = 10050;
    contracts.poolConfiguratorProxy.setEModeCategory(
      1,
      9000,
      9200,
      liquidationBonus,
      'usdx eMode low'
    );
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, 1, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.wbtc, 1, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.setUserEMode(1);
    _mintTestnetToken(tokenList.usdx, alice, amount);
    _supplyToPool(tokenList.usdx, alice, amount);
    (uint256 totalCollateralBase, , , , , ) = contracts.poolProxy.getUserAccountData(alice);
    uint256 debtPrice = contracts.aaveOracle.getAssetPrice(tokenList.wbtc);
    uint256 borrowAmount = (totalCollateralBase * 1e8) / debtPrice;
    _borrowArbitraryAmount(tokenList.wbtc, alice, borrowAmount);

    address liquidator = address(0x0f0f0f);
    _mintTestnetToken(tokenList.wbtc, liquidator, borrowAmount);
    vm.startPrank(liquidator);
    IERC20(tokenList.wbtc).approve(address(contracts.poolProxy), borrowAmount);
    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.wbtc,
      alice,
      type(uint256).max,
      false
    );

    DataTypes.ReserveConfigurationMap memory reserveConfig = contracts.poolProxy.getConfiguration(
      tokenList.usdx
    );
    uint256 bonus = amount - amount.percentDiv(liquidationBonus);
    uint256 protocolFee = bonus.percentMul(reserveConfig.getLiquidationProtocolFee());
    assertEq(IERC20(tokenList.usdx).balanceOf(liquidator), amount - protocolFee);
  }

  function _mintTestnetToken(address erc20, address user, uint256 amount) internal {
    vm.prank(poolAdmin);
    TestnetERC20(erc20).mint(user, amount);
  }

  function _supplyToPool(address erc20, address user, uint256 amount) internal {
    vm.startPrank(user);
    IERC20(erc20).approve(address(contracts.poolProxy), amount);
    contracts.poolProxy.supply(erc20, amount, user, 0);
    vm.stopPrank();
  }

  function _borrowMaxLt(address erc20, address user) internal {
    (uint256 totalCollateralBase, , , uint256 currentLt, , ) = contracts
      .poolProxy
      .getUserAccountData(user);
    uint256 maxBorrowInBase = (totalCollateralBase * currentLt) / 1e4;
    uint256 debtPrice = contracts.aaveOracle.getAssetPrice(erc20);
    uint256 borrowAmount = (maxBorrowInBase / debtPrice) * 10 ** TestnetERC20(erc20).decimals();
    _borrowArbitraryAmount(erc20, user, borrowAmount);
  }

  function _borrowArbitraryAmount(address erc20, address user, uint256 amount) internal {
    _mintTestnetToken(erc20, bob, amount); // todo: better not bob
    _supplyToPool(erc20, bob, amount);

    vm.mockCall(
      address(contracts.aaveOracle),
      abi.encodeWithSelector(IPriceOracleGetter.getAssetPrice.selector, address(erc20)),
      abi.encode(0)
    );
    vm.prank(user);
    contracts.poolProxy.borrow(erc20, amount, 2, 0, user);
    vm.clearMockedCalls();
  }
}
