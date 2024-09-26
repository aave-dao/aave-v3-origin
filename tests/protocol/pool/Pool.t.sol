// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'forge-std/StdStorage.sol';

import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {IPool, DataTypes} from '../../../src/contracts/interfaces/IPool.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {PoolInstance} from '../../../src/contracts/instances/PoolInstance.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract PoolTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;

  IPool internal pool;

  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );

  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  event UserEModeSet(address indexed user, uint8 categoryId);

  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 premium,
    uint16 indexed referralCode
  );

  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  function setUp() public virtual {
    initTestEnvironment();

    pool = PoolInstance(report.poolProxy);
  }

  function test_reverts_new_Pool_invalidAddressesProvider() public {
    PoolInstance p = new PoolInstance(IPoolAddressesProvider(report.poolAddressesProvider));

    vm.expectRevert(bytes(Errors.INVALID_ADDRESSES_PROVIDER));
    p.initialize(IPoolAddressesProvider(makeAddr('OTHER_CONTRACT')));
  }

  function test_pool_defaultValues() public {
    PoolInstance p = new PoolInstance(IPoolAddressesProvider(report.poolAddressesProvider));
    p.initialize(IPoolAddressesProvider(report.poolAddressesProvider));

    // Default values after deployment and initialized
    assertEq(p.MAX_NUMBER_RESERVES(), 128);
    assertEq(address(p.ADDRESSES_PROVIDER()), report.poolAddressesProvider);
    assertEq(p.FLASHLOAN_PREMIUM_TOTAL(), 0);
    assertEq(p.FLASHLOAN_PREMIUM_TO_PROTOCOL(), 0);
    assertEq(p.BRIDGE_PROTOCOL_FEE(), 0);
  }

  function test_reverts_initReserve_not_poolConfigurator(address caller) public {
    vm.assume(caller != report.poolConfiguratorProxy && caller != report.poolAddressesProvider);

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    vm.prank(caller);
    pool.initReserve(address(0), address(0), address(0), address(0));
  }

  function test_setUserUseReserveAsCollateral_false() public {
    vm.startPrank(alice);
    pool.supply(tokenList.usdx, 1e6, alice, 0);

    vm.expectEmit(address(contracts.poolProxy));
    emit ReserveUsedAsCollateralDisabled(tokenList.usdx, alice);

    pool.setUserUseReserveAsCollateral(tokenList.usdx, false);
    vm.stopPrank();
  }

  function test_setUserUseReserveAsCollateral_true() public {
    test_setUserUseReserveAsCollateral_false();

    vm.expectEmit(address(contracts.poolProxy));
    emit ReserveUsedAsCollateralEnabled(tokenList.usdx, alice);

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_noop_setUserUseReserveAsCollateral_true_when_already_is_activated() public {
    test_setUserUseReserveAsCollateral_true();

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_reverts_setUserUseReserveAsCollateral_true_ltv_zero() public {
    test_setUserUseReserveAsCollateral_false();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.configureReserveAsCollateral(tokenList.usdx, 0, 70_00, 105_00);

    vm.expectRevert(bytes(Errors.USER_IN_ISOLATION_MODE_OR_LTV_ZERO));

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_reverts_setUserUseReserveAsCollateral_true_user_isolation_mode() public {
    _seedUsdxLiquidity();

    test_setUserUseReserveAsCollateral_false();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    pool.supply(tokenList.wbtc, 0.5e8, alice, 0);

    pool.setUserUseReserveAsCollateral(tokenList.wbtc, true);

    pool.borrow(tokenList.usdx, 10e6, 2, 0, alice);

    vm.expectRevert(bytes(Errors.USER_IN_ISOLATION_MODE_OR_LTV_ZERO));

    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
    vm.stopPrank();
  }

  function test_reverts_setUserUseReserveAsCollateral_true_user_balance_zero() public {
    vm.expectRevert(bytes(Errors.UNDERLYING_BALANCE_ZERO));

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_reverts_setUserUseReserveAsCollateral_true_reserve_inactive() public {
    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.usdx, false);

    vm.prank(report.poolProxy);
    IAToken(aUSDX).mint(alice, alice, 100e6, 1e27);

    vm.expectRevert(bytes(Errors.RESERVE_INACTIVE));

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_reverts_setUserUseReserveAsCollateral_true_reserve_paused() public {
    test_setUserUseReserveAsCollateral_false();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.usdx, true, 0);

    vm.expectRevert(bytes(Errors.RESERVE_PAUSED));

    vm.prank(alice);
    pool.setUserUseReserveAsCollateral(tokenList.usdx, true);
  }

  function test_reverts_setUserUseReserveAsCollateral_false_hf_lower_lqt() public {
    _seedUsdxLiquidity();

    vm.startPrank(alice);
    pool.supply(tokenList.wbtc, 0.5e8, alice, 0);

    pool.borrow(tokenList.usdx, 10e6, 2, 0, alice);

    vm.expectRevert(bytes(Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD));
    pool.setUserUseReserveAsCollateral(tokenList.wbtc, false);
    vm.stopPrank();
  }

  function test_updateBridgeProtocolFee() public {}

  function test_reverts_modifiers_not_poolConfigurator(address caller) public {
    vm.assume(caller != report.poolConfiguratorProxy && caller != report.poolAddressesProvider);

    DataTypes.ReserveConfigurationMap memory configuration;

    DataTypes.EModeCategoryBaseConfiguration memory category;

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    pool.initReserve(address(0), address(0), address(0), address(0));

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    pool.dropReserve(address(0));

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    pool.setReserveInterestRateStrategyAddress(address(0), address(0));

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    pool.setConfiguration(address(0), configuration);

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    pool.updateBridgeProtocolFee(1);

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    pool.updateFlashloanPremiums(1, 1);

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    pool.configureEModeCategory(1, category);

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    pool.resetIsolationModeTotalDebt(address(0));

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    pool.setLiquidationGracePeriod(address(0), uint40(block.timestamp + 3 hours));
  }

  function test_dropReserve() public {
    (address pA, address pS, address pV) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );
    assertTrue(pA != address(0));
    assertTrue(pS == address(0));
    assertTrue(pV != address(0));

    vm.prank(report.poolConfiguratorProxy);
    pool.dropReserve(tokenList.usdx);

    (address a, address s, address v) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );

    (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      ,
      bool isActive,
      bool isFrozen
    ) = contracts.protocolDataProvider.getReserveConfigurationData(tokenList.usdx);

    assertEq(a, address(0));
    assertEq(s, address(0));
    assertEq(v, address(0));
    assertEq(decimals, 0);
    assertEq(ltv, 0);
    assertEq(liquidationThreshold, 0);
    assertEq(liquidationBonus, 0);
    assertEq(reserveFactor, 0);
    assertEq(usageAsCollateralEnabled, false);
    assertEq(borrowingEnabled, false);
    assertEq(isActive, false);
    assertEq(isFrozen, false);
  }

  function test_setLiquidationGracePeriod(uint40 liquidationGracePeriod) public {
    vm.prank(report.poolConfiguratorProxy);
    pool.setLiquidationGracePeriod(tokenList.usdx, liquidationGracePeriod);

    assertEq(pool.getLiquidationGracePeriod(tokenList.usdx), liquidationGracePeriod);
  }

  function test_setLiquidationGracePeriod_assetNotListed(uint40 liquidationGracePeriod) public {
    address asset = address(25);

    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(bytes(Errors.ASSET_NOT_LISTED));

    pool.setLiquidationGracePeriod(asset, liquidationGracePeriod);
  }

  function test_setReserveInterestRateStrategyAddress() public {
    address updatedInterestsRateStrategy = _deployInterestRateStrategy();

    vm.prank(report.poolConfiguratorProxy);
    pool.setReserveInterestRateStrategyAddress(tokenList.usdx, updatedInterestsRateStrategy);

    address newInterestRateStrategy = contracts.protocolDataProvider.getInterestRateStrategyAddress(
      tokenList.usdx
    );

    assertEq(newInterestRateStrategy, updatedInterestsRateStrategy);
  }

  function test_rescueTokens(uint256 rescueAmount) public {
    rescueAmount = bound(rescueAmount, 1, 100e6);

    vm.prank(poolAdmin);
    usdx.mint(report.poolProxy, rescueAmount);

    vm.prank(poolAdmin);
    pool.rescueTokens(address(usdx), poolAdmin, rescueAmount);

    assertEq(usdx.balanceOf(poolAdmin), rescueAmount);
  }

  function test_reverts_setReserveInterestRateStrategyAddress_ZeroAssetAddress(
    address strategy
  ) public {
    vm.expectRevert(bytes(Errors.ZERO_ADDRESS_NOT_VALID));
    vm.prank(address(contracts.poolConfiguratorProxy));
    contracts.poolProxy.setReserveInterestRateStrategyAddress(address(0), strategy);
  }

  function test_reverts_setReserveInterestRateStrategyAddress_AssetNotListed(
    address asset,
    address strategy
  ) public {
    address[] memory listedAssets = contracts.poolProxy.getReservesList();
    for (uint256 i = 0; i < listedAssets.length; i++) {
      vm.assume(asset != listedAssets[i]);
    }

    vm.assume(asset != address(0));
    vm.expectRevert(bytes(Errors.ASSET_NOT_LISTED));
    vm.prank(address(contracts.poolConfiguratorProxy));
    contracts.poolProxy.setReserveInterestRateStrategyAddress(asset, strategy);
  }

  function test_resetIsolationModeTotalDebt() public {
    _seedUsdxLiquidity();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 10_000);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    pool.supply(tokenList.wbtc, 0.5e8, alice, 0);
    pool.setUserUseReserveAsCollateral(tokenList.wbtc, true);
    pool.borrow(tokenList.usdx, 10e6, 2, 0, alice);
    vm.stopPrank();

    assertGt(pool.getReserveData(tokenList.wbtc).isolationModeTotalDebt, 0);

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 0);

    vm.expectEmit(report.poolProxy);
    emit IsolationModeTotalDebtUpdated(tokenList.wbtc, 0);
    vm.stopPrank();

    vm.prank(report.poolConfiguratorProxy);
    pool.resetIsolationModeTotalDebt(tokenList.wbtc);

    assertEq(pool.getReserveData(tokenList.wbtc).isolationModeTotalDebt, 0);
  }

  function test_getters_getUserAccountData() public {
    _seedUsdxLiquidity();

    DataTypes.ReserveConfigurationMap memory conf = pool.getConfiguration(tokenList.wbtc);

    vm.startPrank(bob);
    pool.supply(tokenList.wbtc, 0.4e8, bob, 0);
    pool.borrow(tokenList.usdx, 2000e6, 2, 0, bob);
    vm.stopPrank();

    (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      ,
      uint256 currentLiquidationThreshold,
      uint256 ltv,

    ) = pool.getUserAccountData(bob);

    assertEq(totalCollateralBase, 10800e8);
    assertEq(totalDebtBase, 2000e8);
    assertEq(currentLiquidationThreshold, conf.getLiquidationThreshold());
    assertEq(ltv, conf.getLtv());
  }

  function test_mintToTreasury() public {
    (, , address varDebtUSDX) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );

    _seedUsdxLiquidity();

    vm.startPrank(bob);
    pool.supply(tokenList.wbtc, 0.4e8, bob, 0);
    pool.borrow(tokenList.usdx, 2000e6, 2, 0, bob);

    vm.warp(block.timestamp + 30 days);

    pool.repay(tokenList.usdx, IERC20(varDebtUSDX).balanceOf(bob), 2, bob);
    vm.stopPrank();

    // distribute fees to treasury
    address[] memory assets = new address[](1);
    assets[0] = tokenList.usdx;

    uint256 accruedToTreasury = uint256(pool.getReserveData(tokenList.usdx).accruedToTreasury)
      .rayMul(pool.getReserveNormalizedIncome(tokenList.usdx));

    vm.expectEmit(address(contracts.poolProxy));
    emit MintedToTreasury(tokenList.usdx, accruedToTreasury);

    pool.mintToTreasury(assets);

    assertEq(pool.getReserveData(tokenList.usdx).accruedToTreasury, 0);
  }

  function test_mintToTreasury_skip_invalid_addresses() public {
    (, , address varDebtUSDX) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.usdx
    );

    _seedUsdxLiquidity();

    vm.startPrank(bob);
    pool.supply(tokenList.wbtc, 0.4e8, bob, 0);
    pool.borrow(tokenList.usdx, 2000e6, 2, 0, bob);

    vm.warp(block.timestamp + 30 days);

    pool.repay(tokenList.usdx, IERC20(varDebtUSDX).balanceOf(bob), 2, bob);
    vm.stopPrank();

    // distribute fees to treasury
    address[] memory assets = new address[](2);
    assets[0] = makeAddr('OTHER_TOKEN');
    assets[1] = tokenList.usdx;

    uint256 accruedToTreasury = uint256(pool.getReserveData(tokenList.usdx).accruedToTreasury)
      .rayMul(pool.getReserveNormalizedIncome(tokenList.usdx));

    vm.expectEmit(address(contracts.poolProxy));
    emit MintedToTreasury(tokenList.usdx, accruedToTreasury);

    pool.mintToTreasury(assets);

    assertEq(pool.getReserveData(tokenList.usdx).accruedToTreasury, 0);
  }

  function test_setUserEmode() public {
    EModeCategoryInput memory ct = _genCategoryOne();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct.id, ct.ltv, ct.lt, ct.lb, ct.label);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct.id, true);
    vm.stopPrank();
    vm.expectEmit(address(contracts.poolProxy));
    emit UserEModeSet(alice, ct.id);

    vm.prank(alice);
    pool.setUserEMode(ct.id);
  }

  function test_setUserEmode_twice() public {
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

    vm.expectEmit(address(contracts.poolProxy));
    emit UserEModeSet(alice, ct1.id);

    vm.prank(alice);
    pool.setUserEMode(ct1.id);

    vm.expectEmit(address(contracts.poolProxy));
    emit UserEModeSet(alice, ct2.id);

    vm.prank(alice);
    pool.setUserEMode(ct2.id);
  }

  function test_setUserEmode_twice_inconsistent_category() public {
    vm.prank(carol);
    pool.supply(tokenList.wbtc, 10e8, carol, 0);
    vm.prank(carol);
    pool.supply(tokenList.weth, 100e18, carol, 0);

    EModeCategoryInput memory ct1 = _genCategoryOne();
    EModeCategoryInput memory ct2 = _genCategoryTwo();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);
    contracts.poolConfiguratorProxy.setEModeCategory(ct2.id, ct2.ltv, ct2.lt, ct2.lb, ct2.label);

    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.weth, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct2.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.usdx, ct2.id, true);
    vm.stopPrank();

    vm.expectEmit(address(contracts.poolProxy));
    emit UserEModeSet(alice, ct1.id);

    uint256 amount = 1e8;
    uint256 borrowAmount = 12e18;

    vm.startPrank(alice);
    pool.setUserEMode(ct1.id);

    pool.supply(tokenList.wbtc, amount, alice, 0);
    pool.borrow(tokenList.weth, borrowAmount, 2, 0, alice);

    vm.expectRevert(bytes(Errors.NOT_BORROWABLE_IN_EMODE));

    pool.setUserEMode(ct2.id);
    vm.stopPrank();
  }

  function test_reverts_setUserEmode_0_bad_hf() public {
    vm.prank(carol);
    pool.supply(tokenList.wbtc, 10e8, carol, 0);
    vm.prank(carol);
    pool.supply(tokenList.weth, 100e18, carol, 0);

    EModeCategoryInput memory ct1 = _genCategoryOne();
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setEModeCategory(ct1.id, ct1.ltv, ct1.lt, ct1.lb, ct1.label);

    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.wbtc, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetCollateralInEMode(tokenList.weth, ct1.id, true);
    contracts.poolConfiguratorProxy.setAssetBorrowableInEMode(tokenList.weth, ct1.id, true);
    vm.stopPrank();

    vm.prank(alice);
    pool.setUserEMode(ct1.id);

    uint256 amount = 1e8;
    uint256 borrowAmount = 12e18;

    vm.startPrank(alice);
    pool.supply(tokenList.wbtc, amount, alice, 0);
    pool.borrow(tokenList.weth, borrowAmount, 2, 0, alice);

    stdstore
      .target(IAaveOracle(report.aaveOracle).getSourceOfAsset(tokenList.wbtc))
      .sig('_latestAnswer()')
      .checked_write(
        _calcPrice(IAaveOracle(report.aaveOracle).getAssetPrice(tokenList.wbtc), 70_00)
      );

    vm.expectRevert(bytes(Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD));

    pool.setUserEMode(0);
    vm.stopPrank();
  }

  function test_getVirtualUnderlyingBalance() public {
    _seedUsdxLiquidity();

    uint256 virtualBalance = pool.getVirtualUnderlyingBalance(tokenList.usdx);
    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);

    assertEq(IERC20(tokenList.usdx).balanceOf(aUSDX), virtualBalance);
    assertEq(50_000e6, virtualBalance);
  }

  function test_getFlashLoanLogic() public view {
    assertNotEq(pool.getFlashLoanLogic(), address(0));
  }

  function test_getBorrowLogic() public view {
    assertNotEq(pool.getBorrowLogic(), address(0));
  }

  function test_getBridgeLogic() public view {
    assertNotEq(pool.getBridgeLogic(), address(0));
  }

  function test_getEModeLogic() public view {
    assertNotEq(pool.getEModeLogic(), address(0));
  }

  function test_getLiquidationLogic() public view {
    assertNotEq(pool.getLiquidationLogic(), address(0));
  }

  function test_getPoolLogic() public view {
    assertNotEq(pool.getPoolLogic(), address(0));
  }

  function test_getSupplyLogic() public view {
    assertNotEq(pool.getSupplyLogic(), address(0));
  }

  function _seedUsdxLiquidity() internal {
    vm.prank(carol);
    pool.supply(tokenList.usdx, 50_000e6, carol, 0);
  }
}
