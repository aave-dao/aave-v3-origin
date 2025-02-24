// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {IPriceOracleGetter} from '../../../src/contracts/interfaces/IPriceOracleGetter.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {ReserveLogic} from '../../../src/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {IERC20Detailed} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {PriceOracleSentinel} from '../../../src/contracts/misc/PriceOracleSentinel.sol';
import {SequencerOracle, ISequencerOracle} from '../../../src/contracts/mocks/oracle/SequencerOracle.sol';
import {MockAggregator} from '../../../src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {LiquidationLogic} from '../../../src/contracts/protocol/libraries/logic/LiquidationLogic.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from '../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {LiquidationDataProvider} from '../../../src/contracts/helpers/LiquidationDataProvider.sol';
import {LiquidationHelper} from '../../helpers/LiquidationHelper.sol';

contract PoolLiquidationCloseFactorTests is TestnetProcedures {
  using stdStorage for StdStorage;

  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using PercentageMath for uint256;
  using WadRayMath for uint256;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;

  address internal whale = makeAddr('whale');
  address internal liquidator = makeAddr('liquidator');

  PriceOracleSentinel internal priceOracleSentinel;
  SequencerOracle internal sequencerOracleMock;
  LiquidationDataProvider internal liquidationDataProvider;

  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  function setUp() public {
    initTestEnvironment(false);

    _addBorrowableLiquidity();
    _fundLiquidator();

    liquidationDataProvider = new LiquidationDataProvider(
      address(contracts.poolProxy),
      address(contracts.poolAddressesProvider)
    );
  }

  // ## Fuzzing suite ##
  function test_hf_helper(uint256 desiredHf) public {
    // bounding to 0.01 as otherwise required amount spiral out of control
    desiredHf = bound(desiredHf, 0.01 ether, 1 ether);
    _supplyToPool(tokenList.weth, bob, 10 ether);
    _borrowToBeBelowHf(bob, tokenList.usdx, desiredHf);
    (, , , , , uint256 hf) = contracts.poolProxy.getUserAccountData(bob);
    assertLt(hf, desiredHf);
    // it's not possible to be exact here, because not every point on the scala is reachable
    assertApproxEqAbs(hf, desiredHf, 0.001 ether);
  }

  /**
   * If the hf is below 0.95 the close factor should be 100%
   */
  function test_fuzz_hf_lte_095_supply_gt_threshold_closeFactorShouldBe100(
    uint256 desiredHf,
    uint256 supplyAmount
  ) public {
    address collateralAsset = tokenList.weth;
    uint256 oraclePrice = contracts.aaveOracle.getAssetPrice(collateralAsset);
    uint256 lowerBound = (LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD *
      10 ** IERC20Detailed(collateralAsset).decimals()) / oraclePrice;
    supplyAmount = bound(supplyAmount, lowerBound, 1_000 ether);
    desiredHf = bound(desiredHf, 0.01 ether, 0.95 ether);
    _supplyToPool(collateralAsset, bob, supplyAmount);
    _borrowToBeBelowHf(bob, tokenList.usdx, desiredHf);
    _liquidateAndValidateCloseFactor(collateralAsset, tokenList.usdx, type(uint256).max, 1e4);
  }

  /**
   * If hf is above 0.95, but collateral is below threshold - cf should be 100%
   */
  function test_fuzz_hf_gt_095_supply_lt_threshold_closeFactorShouldBe100(
    uint256 desiredHf,
    uint256 supplyAmount
  ) public {
    address collateralAsset = tokenList.weth;
    uint256 oraclePrice = contracts.aaveOracle.getAssetPrice(collateralAsset);
    uint256 upperBound = (LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD *
      10 ** IERC20Detailed(collateralAsset).decimals()) / oraclePrice;
    supplyAmount = bound(supplyAmount, 0.01 ether, upperBound);
    desiredHf = bound(desiredHf, 0.96 ether, 0.99 ether);
    _supplyToPool(collateralAsset, bob, supplyAmount);
    _borrowToBeBelowHf(bob, tokenList.usdx, desiredHf);
    _liquidateAndValidateCloseFactor(collateralAsset, tokenList.usdx, type(uint256).max, 1e4);
  }

  /**
   * If hf is above 0.95, but collateral is below threshold - cf should be 50%
   */
  function test_fuzz_hf_gt_095_supply_gt_threshold_closeFactorShouldBe50(
    uint256 desiredHf,
    uint256 supplyAmount
  ) public {
    address collateralAsset = tokenList.weth;
    uint256 oraclePrice = contracts.aaveOracle.getAssetPrice(collateralAsset);
    uint256 lowerBound = (LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD *
      10 ** IERC20Detailed(collateralAsset).decimals()) / oraclePrice;
    supplyAmount = bound(supplyAmount, lowerBound * 2, 10_000 ether);
    desiredHf = bound(desiredHf, 0.96 ether, 0.99 ether);
    _supplyToPool(collateralAsset, bob, supplyAmount);
    _borrowToBeBelowHf(bob, tokenList.usdx, desiredHf);
    _liquidateAndValidateCloseFactor(collateralAsset, tokenList.usdx, type(uint256).max, 0.5e4);
  }

  // ## unit test suite for coverage without fuzz
  function test_hf_lte_095_supply_gt_threshold_closeFactorShouldBe100() external {
    test_fuzz_hf_lte_095_supply_gt_threshold_closeFactorShouldBe100(0.94 ether, 100 ether);
  }

  function test_hf_gt_095_supply_lt_threshold_closeFactorShouldBe100() external {
    test_fuzz_hf_gt_095_supply_lt_threshold_closeFactorShouldBe100(0.97 ether, 0.5 ether);
  }

  function test_hf_gt_095_supply_gt_threshold_closeFactorShouldBe50() external {
    test_fuzz_hf_gt_095_supply_gt_threshold_closeFactorShouldBe50(0.97 ether, 100 ether);
  }

  function test_hf_gt_095_borrow_gt_threshold_collateral_lt_threshold_closeFactorShouldBe100()
    external
  {
    // supply slightly less then threshold as usdx and weth collateral
    _supplyToPool(
      tokenList.usdx,
      bob,
      (LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD - 1e8) / 1e2
    );
    uint256 oraclePrice = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    uint256 supplyLtThreshold = ((LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD - 1e8) *
      10 ** IERC20Detailed(tokenList.weth).decimals()) / oraclePrice;
    _supplyToPool(tokenList.weth, bob, supplyLtThreshold);
    // borrow above threshold
    _borrowToBeBelowHf(bob, tokenList.usdx, 0.97 ether);
    (, uint256 debtInBaseCurrency, , , , uint256 hf) = contracts.poolProxy.getUserAccountData(bob);
    assertGt(debtInBaseCurrency, LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD);
    assertGt(hf, 0.95 ether);
    _liquidateAndValidateCloseFactor(tokenList.weth, tokenList.usdx, type(uint256).max, 1e4);
  }

  function test_shouldRevertIfCloseFactorIs100ButCollateralIsBelowThreshold() external {
    uint256 usdxSupply = LiquidationLogic.MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD / 1e2;
    // supply collateral below threshold
    _supplyToPool(tokenList.usdx, bob, usdxSupply);
    // supply differe collateral to increase borrowing power
    _supplyToPool(tokenList.weth, bob, 4 ether);
    // borrow enough so close factor is at 100%
    _borrowToBeBelowHf(bob, tokenList.usdx, 0.93 ether);

    // this test is a bit fragile as it's implicitly assuming that 44e6 is the bonus, without the fee
    uint256 liquidationAmount = (usdxSupply / 2) - 44e6;
    vm.prank(liquidator);
    IERC20Detailed(tokenList.usdx).approve(address(contracts.poolProxy), type(uint256).max);
    vm.prank(liquidator);
    vm.expectRevert(bytes(Errors.MUST_NOT_LEAVE_DUST));
    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.usdx,
      bob,
      liquidationAmount,
      false
    );
  }

  // on aave v3.3 in certain edge scenarios, liquidation uint.max reverts on cf 50%
  // the liquidationprovider should always return valid values
  function test_liquidationdataprovider_edge_range() external {
    // borrow supply 4k
    _supplyToPool(tokenList.usdx, bob, 8000e6);
    vm.prank(bob);
    contracts.poolProxy.borrow(tokenList.usdx, 4200e6, 2, 0, bob);
    _borrowToBeBelowHf(bob, tokenList.weth, 0.98 ether);

    vm.startPrank(liquidator);
    IERC20Detailed(tokenList.usdx).approve(address(contracts.poolProxy), type(uint256).max);

    vm.expectRevert(bytes(Errors.MUST_NOT_LEAVE_DUST));
    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.usdx,
      bob,
      type(uint256).max,
      false
    );

    // call with exact input
    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = liquidationDataProvider
      .getLiquidationInfo(bob, tokenList.usdx, tokenList.usdx);
    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.usdx,
      bob,
      liquidationInfo.maxDebtToLiquidate,
      false
    );
  }

  // on aave v3.3 in certain edge scenarios, liquidation uint.max reverts on cf 50%
  // the liquidationprovider should always return valid values
  function test_liquidationdataprovider_edge_range_reverse() external {
    // borrow supply 4k
    _supplyToPool(tokenList.usdx, bob, 4200e6);
    uint256 amount = (4000e8 * (10 ** IERC20Detailed(tokenList.weth).decimals())) /
      contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyToPool(tokenList.weth, bob, amount);
    vm.prank(bob);
    _borrowToBeBelowHf(bob, tokenList.usdx, 0.98 ether);

    vm.startPrank(liquidator);
    IERC20Detailed(tokenList.usdx).approve(address(contracts.poolProxy), type(uint256).max);

    vm.expectRevert(bytes(Errors.MUST_NOT_LEAVE_DUST));
    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.usdx,
      bob,
      type(uint256).max,
      false
    );

    // call with exact input
    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = liquidationDataProvider
      .getLiquidationInfo(bob, tokenList.usdx, tokenList.usdx);
    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.usdx,
      bob,
      liquidationInfo.maxDebtToLiquidate,
      false
    );
  }

  function _liquidateAndValidateCloseFactor(
    address collateralAsset,
    address debtAsset,
    uint256 amountToLiquidate,
    uint256 closeFactor
  ) internal {
    (, uint256 debtInBaseCurrency, , , , ) = contracts.poolProxy.getUserAccountData(bob);
    // first we calculate the maximal possible liquidatable
    (, uint256 debtAmountAt100, , ) = LiquidationHelper._getLiquidationParams(
      contracts.poolProxy,
      bob,
      collateralAsset,
      debtAsset,
      amountToLiquidate,
      // assuming all debt is the asset we wanna liquidate
      (debtInBaseCurrency * 10 ** IERC20Detailed(debtAsset).decimals()) /
        contracts.aaveOracle.getAssetPrice(debtAsset)
    );
    // then we calculate the exact amounts
    LiquidationDataProvider.LiquidationInfo memory liquidationInfo = liquidationDataProvider
      .getLiquidationInfo(bob, collateralAsset, debtAsset, amountToLiquidate);
    uint256 balanceBefore = IERC20Detailed(collateralAsset).balanceOf(liquidator);
    vm.prank(liquidator);
    IERC20Detailed(debtAsset).approve(address(contracts.poolProxy), type(uint256).max);
    vm.prank(liquidator);
    contracts.poolProxy.liquidationCall(collateralAsset, debtAsset, bob, amountToLiquidate, false);
    uint256 balanceAfter = IERC20Detailed(collateralAsset).balanceOf(liquidator);
    assertEq(
      balanceAfter - balanceBefore,
      liquidationInfo.maxCollateralToLiquidate,
      'WRONG_BALANCE'
    );
    assertApproxEqAbs(
      debtAmountAt100.percentMul(closeFactor),
      liquidationInfo.maxDebtToLiquidate,
      1,
      'WRONG_CLOSE_FACTOR'
    );
  }

  function _borrowToBeBelowHf(address user, address assetToBorrow, uint256 desiredhf) internal {
    uint256 requiredBorrowsInBase = _getRequiredBorrowsForHfBelow(user, desiredhf);
    uint256 amount = (requiredBorrowsInBase * (10 ** IERC20Detailed(assetToBorrow).decimals())) /
      contracts.aaveOracle.getAssetPrice(assetToBorrow);
    vm.mockCall(
      address(contracts.aaveOracle),
      abi.encodeWithSelector(IPriceOracleGetter.getAssetPrice.selector, assetToBorrow),
      abi.encode(0)
    );
    vm.prank(user);
    contracts.poolProxy.borrow(assetToBorrow, amount, 2, 0, user);
    vm.clearMockedCalls();
  }

  function _addBorrowableLiquidity() internal {
    _supplyToPool(tokenList.weth, whale, 1_000_000e18);
    _supplyToPool(tokenList.usdx, whale, 1_000_000_000e6);
    _supplyToPool(tokenList.wbtc, whale, 10_000e8);
  }

  function _fundLiquidator() internal {
    deal(tokenList.weth, liquidator, 1_000_000e18);
    deal(tokenList.usdx, liquidator, 1_000_000_000e6);
    deal(tokenList.wbtc, liquidator, 10_000e8);
  }

  function _supplyToPool(address erc20, address user, uint256 amount) internal {
    deal(erc20, user, amount);
    vm.startPrank(user);
    IERC20(erc20).approve(address(contracts.poolProxy), amount);
    contracts.poolProxy.supply(erc20, amount, user, 0);
    vm.stopPrank();
  }

  /**
   * @notice Returns the required amount of borrows in base currency to reach a certain healthfactor
   */
  function _getRequiredBorrowsForHfBelow(
    address user,
    uint256 desiredHf
  ) internal view returns (uint256) {
    (
      uint256 totalCollateralBase,
      uint256 totalBorrowsBase,
      ,
      uint256 currentLiquidationThreshold,
      ,

    ) = contracts.poolProxy.getUserAccountData(user);
    return
      ((totalCollateralBase.percentMul(currentLiquidationThreshold + 1) * 1e18) / desiredHf) -
      totalBorrowsBase;
  }
}
