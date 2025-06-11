// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'tests/protocol/pool/Pool.Liquidations.t.sol';

contract PoolLiquidationRwaTests is PoolLiquidationTests {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using PercentageMath for uint256;
  using WadRayMath for uint256;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;

  function setUp() public override {
    super.setUp();
    _upgradeToRwaAToken(tokenList.wbtc, 'aWbtc');

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.wbtc, 0);
  }

  /// @dev overwriting to make `params.receiveAToken` false
  function test_full_liquidate_multiple_variable_borrows() public override {
    uint256 amount = 1e8;
    uint256 borrowAmountUsdx = 200e6;
    uint256 borrowAmountWeth = 10e18;
    vm.startPrank(alice);

    contracts.poolProxy.supply(tokenList.wbtc, amount, alice, 0);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmountUsdx - 1, 2, 0, alice);
    contracts.poolProxy.borrow(tokenList.weth, borrowAmountWeth, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      30_00
    );
    params.receiveAToken = false;

    uint256 liquidatorBalanceBefore = IERC20(params.collateralAsset).balanceOf(bob);

    vm.expectEmit(address(contracts.poolProxy));
    emit LiquidationLogic.LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.actualDebtToLiquidate,
      params.actualCollateralToLiquidate,
      bob,
      params.receiveAToken
    );
    // Liquidate
    vm.prank(bob);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      params.liquidationAmountInput,
      params.receiveAToken
    );
    (, , address variableDebtToken) = contracts.protocolDataProvider.getReserveTokensAddresses(
      params.debtAsset
    );

    assertEq(
      IERC20(params.collateralAsset).balanceOf(bob),
      liquidatorBalanceBefore + params.actualCollateralToLiquidate
    );
    assertEq(IERC20(variableDebtToken).balanceOf(params.user), 0);
  }

  /// @dev overwriting to make wbtc a standard aToken: test is borrowing wbtc
  /// @dev we also need to turn back on the liquidation fees
  function test_liquidate_borrow_burn_multiple_assets_bad_debt() public override {
    _upgradeToStandardAToken(tokenList.wbtc, 'aWbtc');
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.wbtc, 10_00);
    super.test_liquidate_borrow_burn_multiple_assets_bad_debt();
  }

  /// @dev overwriting to make wbtc a standard aToken: test is borrowing wbtc
  /// @dev we also need to turn back on the liquidation fees
  function test_liquidate_variable_borrow_repro() public override {
    _upgradeToStandardAToken(tokenList.wbtc, 'aWbtc');
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setLiquidationProtocolFee(tokenList.wbtc, 10_00);
    super.test_liquidate_borrow_burn_multiple_assets_bad_debt();
  }

  /// @dev skipping as it is not applicable for RWAs
  function test_partial_liquidate_atokens_variable_borrow() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev overwriting to make `params.receiveAToken` false
  function test_self_liquidate_isolated_position_shoulDisableCollateral() public override {
    uint256 borrowAmount = 11000e6;
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setDebtCeiling(tokenList.wbtc, 12_000_00);
    contracts.poolConfiguratorProxy.setBorrowableInIsolation(tokenList.usdx, true);
    vm.stopPrank();

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.wbtc, true);
    contracts.poolProxy.borrow(tokenList.usdx, borrowAmount, 2, 0, alice);
    vm.stopPrank();

    LiquidationInput memory params = _loadLiquidationInput(
      alice,
      tokenList.wbtc,
      tokenList.usdx,
      UINT256_MAX,
      tokenList.wbtc,
      40_00
    );
    params.receiveAToken = false;

    vm.expectEmit(true, true, false, false);
    emit IsolationModeTotalDebtUpdated(
      params.collateralAsset,
      ((borrowAmount - params.actualDebtToLiquidate) / 1e4)
    );

    // Liquidate
    vm.prank(alice);
    contracts.poolProxy.liquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      type(uint256).max,
      params.receiveAToken
    );
    uint256 id = contracts.poolProxy.getReserveData(params.collateralAsset).id;
    assertEq(contracts.poolProxy.getUserConfiguration(alice).isUsingAsCollateral(id), false);
  }

  /// @dev overwriting to skip: test only applies if receiveAToken is true,
  /// @dev which is not applicable for RWAs
  function test_self_liquidate_isolated_position_shoulEnableCollateralIfIsolatedSupplier()
    public
    override
  {
    vm.skip(true, 'Not applicable to RWAs');
  }

  /// @dev overwriting to skip: test only applies if receiveAToken is true,
  /// @dev which is not applicable for RWAs
  function test_self_liquidate_position_shoulKeepCollateralEnabled() public override {
    vm.skip(true, 'Not applicable to RWAs');
  }
}
