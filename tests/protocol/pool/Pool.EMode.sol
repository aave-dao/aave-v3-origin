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
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';

contract PoolEModeTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;

  event UserEModeSet(address indexed user, uint8 categoryId);

  IPool internal pool;
  // @notice number of eModes that are created per default
  uint256 constant E_MODES_SETUP = 2;

  function setUp() public virtual {
    initTestEnvironment(false);

    pool = PoolInstance(report.poolProxy);
  }

  function test_setUserEMode_shouldApplyLtLtv() public {
    vm.startPrank(poolAdmin);
    EModeCategoryInput memory ct1 = _genCategoryOne();
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct1.id, true);
    vm.stopPrank();

    vm.prank(alice);
    vm.expectEmit(address(pool));
    emit UserEModeSet(alice, ct1.id);
    pool.setUserEMode(ct1.id);
    _mintTestnetToken(tokenList.usdx, alice, 1);
    _supplyToPool(tokenList.usdx, alice, 1);

    (, , , uint256 currentLt, uint256 currentLtv, ) = contracts.poolProxy.getUserAccountData(alice);
    assertEq(currentLt, ct1.lt);
    assertEq(currentLtv, ct1.ltv);
  }

  function test_setUserEMode_switchShouldWorkIfNoBorrows(uint8 eMode) public {
    // create 2 emodes
    // 1) wbtc/weth collateral;
    // 2) wbtc/usdc collateral;
    EModeCategoryInput memory ct1 = _genCategoryOne();
    EModeCategoryInput memory ct2 = _genCategoryTwo();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setEModeCategory(ct2.id, ct2.ltv, ct2.lt, ct2.lb, ct2.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct2.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct2.id, true);
    vm.stopPrank();

    eMode = uint8(bound(eMode, 0, E_MODES_SETUP));
    vm.expectEmit(address(pool));
    emit UserEModeSet(alice, eMode);

    vm.prank(alice);
    pool.setUserEMode(eMode);
    assertEq(pool.getUserEMode(alice), eMode);

    // switching eMode should work as well
    eMode = uint8(bound(eMode + 1, 0, E_MODES_SETUP));
    vm.prank(alice);
    pool.setUserEMode(eMode);
    assertEq(pool.getUserEMode(alice), eMode);
  }

  function test_setUserEmode_switchToBetterEModeShouldBePossible(uint104 amount) public {
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
    uint256 debtPrice = contracts.aaveOracle.getAssetPrice(tokenList.wbtc);
    uint256 borrowAmount = (maxBorrowInBase / debtPrice) * 10 ** TestnetERC20(erc20).decimals();
    _mintTestnetToken(erc20, bob, borrowAmount); // todo: better not bob
    _supplyToPool(erc20, bob, borrowAmount);

    vm.mockCall(
      address(contracts.aaveOracle),
      abi.encodeWithSelector(IPriceOracleGetter.getAssetPrice.selector, address(erc20)),
      abi.encode(0)
    );
    vm.prank(user);
    contracts.poolProxy.borrow(erc20, borrowAmount, 2, 0, user);
    vm.clearMockedCalls();
  }
}
