// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import './RateStrategy.template.sol';

contract RateStrategyBaseTests is RateStrategyBase {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  //----------------------------------------------------------------------------------------------------
  //                                      INITIALIZATION TESTS
  //----------------------------------------------------------------------------------------------------
  function test_initialization() public {
    assertEq(rateStrategy.MAX_OPTIMAL_POINT(), 99_00);
    assertEq(rateStrategy.MIN_OPTIMAL_POINT(), 1_00);
    assertEq(rateStrategy.MAX_BORROW_RATE(), 1000_00);
    assertEq(address(rateStrategy.ADDRESSES_PROVIDER()), address(report.poolAddressesProvider));

    address newToken = makeAddr('newToken');
    assertEq(rateStrategy.getOptimalUsageRatio(newToken), 0);
    assertEq(rateStrategy.getVariableRateSlope1(newToken), 0);
    assertEq(rateStrategy.getVariableRateSlope2(newToken), 0);
    assertEq(rateStrategy.getBaseVariableBorrowRate(newToken), 0);
    assertEq(rateStrategy.getMaxVariableBorrowRate(newToken), 0);
  }

  function test_new_DefaultReserveInterestRateStrategy_wrong_provider() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddressesProvider.selector));
    rateStrategy = new DefaultReserveInterestRateStrategyV2(address(0));
  }

  //----------------------------------------------------------------------------------------------------
  //                                         Test Getters
  //----------------------------------------------------------------------------------------------------
  function test_getInterestRateDataRay(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public setRateParams(rateDataToSet, tokenList.usdx) {
    IDefaultInterestRateStrategyV2.InterestRateDataRay memory rateData = rateStrategy
      .getInterestRateData(tokenList.usdx);
    assertEq(uint256(rateDataToSet.optimalUsageRatio) * 1e23, rateData.optimalUsageRatio);
    assertEq(uint256(rateDataToSet.baseVariableBorrowRate) * 1e23, rateData.baseVariableBorrowRate);
    assertEq(uint256(rateDataToSet.variableRateSlope1) * 1e23, rateData.variableRateSlope1);
    assertEq(uint256(rateDataToSet.variableRateSlope2) * 1e23, rateData.variableRateSlope2);
  }

  function test_getInterestRateDataBps(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public setRateParams(rateDataToSet, tokenList.usdx) {
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = rateStrategy
      .getInterestRateDataBps(tokenList.usdx);
    assertEq(rateDataToSet.optimalUsageRatio, rateData.optimalUsageRatio);
    assertEq(rateDataToSet.baseVariableBorrowRate, rateData.baseVariableBorrowRate);
    assertEq(rateDataToSet.variableRateSlope1, rateData.variableRateSlope1);
    assertEq(rateDataToSet.variableRateSlope2, rateData.variableRateSlope2);
  }

  function test_getMaxVariableBorrowRate(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public setRateParams(rateDataToSet, tokenList.usdx) {
    uint256 maxVariableBorrowRate = rateStrategy.getMaxVariableBorrowRate(tokenList.usdx);
    assertEq(
      uint256(
        rateDataToSet.baseVariableBorrowRate +
          rateDataToSet.variableRateSlope1 +
          rateDataToSet.variableRateSlope2
      ) * 1e23,
      maxVariableBorrowRate
    );
  }

  function test_overflow_liquidity_rates() public {
    vm.mockCall(
      address(rateStrategy),
      abi.encodeWithSelector(rateStrategy.calculateInterestRates.selector),
      abi.encode(UINT256_MAX, 0)
    );
    vm.expectRevert(
      abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 128, UINT256_MAX)
    );
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 1000e6, alice, 0);
  }

  function test_overflow_variable_rates() public {
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);

    _supplyAndEnableAsCollateral(alice, 1e8, tokenList.wbtc);

    vm.mockCall(
      address(rateStrategy),
      abi.encodeWithSelector(rateStrategy.calculateInterestRates.selector),
      abi.encode(0, UINT256_MAX)
    );
    vm.expectRevert(
      abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 128, UINT256_MAX)
    );
    vm.startPrank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 10e6, 2, 0, alice);
    vm.stopPrank();
  }

  function test_new_SetReserveInterestRateParams_when_not_configurator(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public {
    _validateSetRateParams(rateDataToSet);

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateDataToSet));
  }

  function test_new_SetReserveInterestRateParams_override_method(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public setRateParams(rateDataToSet, tokenList.usdx) {
    assertEq(address(rateStrategy.ADDRESSES_PROVIDER()), report.poolAddressesProvider);
    assertEq(
      rateStrategy.getOptimalUsageRatio(tokenList.usdx),
      uint256(rateDataToSet.optimalUsageRatio) * 1e23
    );
    assertEq(
      rateStrategy.getVariableRateSlope1(tokenList.usdx),
      uint256(rateDataToSet.variableRateSlope1) * 1e23
    );
    assertEq(
      rateStrategy.getVariableRateSlope2(tokenList.usdx),
      uint256(rateDataToSet.variableRateSlope2) * 1e23
    );
    assertEq(
      rateStrategy.getBaseVariableBorrowRate(tokenList.usdx),
      uint256(rateDataToSet.baseVariableBorrowRate) * 1e23
    );
    assertEq(
      rateStrategy.getMaxVariableBorrowRate(tokenList.usdx),
      uint256(
        rateDataToSet.baseVariableBorrowRate +
          rateDataToSet.variableRateSlope1 +
          rateDataToSet.variableRateSlope2
      ) * 1e23
    );
  }

  function test_new_SetReserveInterestRateParams(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public {
    _validateSetRateParams(rateDataToSet);

    vm.prank(report.poolConfiguratorProxy);
    vm.expectEmit(true, false, false, true);
    emit IDefaultInterestRateStrategyV2.RateDataUpdate(
      tokenList.usdx,
      uint256(rateDataToSet.optimalUsageRatio),
      uint256(rateDataToSet.baseVariableBorrowRate),
      uint256(rateDataToSet.variableRateSlope1),
      uint256(rateDataToSet.variableRateSlope2)
    );
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateDataToSet));

    assertEq(address(rateStrategy.ADDRESSES_PROVIDER()), report.poolAddressesProvider);
    assertEq(
      rateStrategy.getOptimalUsageRatio(tokenList.usdx),
      uint256(rateDataToSet.optimalUsageRatio) * 1e23
    );
    assertEq(
      rateStrategy.getVariableRateSlope1(tokenList.usdx),
      uint256(rateDataToSet.variableRateSlope1) * 1e23
    );
    assertEq(
      rateStrategy.getVariableRateSlope2(tokenList.usdx),
      uint256(rateDataToSet.variableRateSlope2) * 1e23
    );
    assertEq(
      rateStrategy.getBaseVariableBorrowRate(tokenList.usdx),
      uint256(rateDataToSet.baseVariableBorrowRate) * 1e23
    );
    assertEq(
      rateStrategy.getMaxVariableBorrowRate(tokenList.usdx),
      uint256(
        rateDataToSet.baseVariableBorrowRate +
          rateDataToSet.variableRateSlope1 +
          rateDataToSet.variableRateSlope2
      ) * 1e23
    );
  }

  function test_reverts_SetReserveInterestRateParams_when_reserve_0(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public {
    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressNotValid.selector));
    rateStrategy.setInterestRateParams(address(0), abi.encode(rateDataToSet));
    // Override
    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressNotValid.selector));
    rateStrategy.setInterestRateParams(address(0), rateDataToSet);
  }

  function test_reverts_SetReserveInterestRateParams_when_gt_max_op(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public {
    vm.assume(rateDataToSet.optimalUsageRatio > rateStrategy.MAX_OPTIMAL_POINT());

    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidOptimalUsageRatio.selector));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateDataToSet));

    // Override
    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidOptimalUsageRatio.selector));
    rateStrategy.setInterestRateParams(tokenList.usdx, rateDataToSet);
  }

  function test_reverts_SetReserveInterestRateParams_when_lt_min_op(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public {
    vm.assume(rateDataToSet.optimalUsageRatio < rateStrategy.MIN_OPTIMAL_POINT());

    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidOptimalUsageRatio.selector));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateDataToSet));

    // Override
    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidOptimalUsageRatio.selector));
    rateStrategy.setInterestRateParams(tokenList.usdx, rateDataToSet);
  }

  function test_reverts_SetReserveInterestRateParams_when_gt_maxRate(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateDataToSet
  ) public {
    vm.assume(
      rateDataToSet.optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        rateDataToSet.optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(rateDataToSet.variableRateSlope1 <= rateDataToSet.variableRateSlope2);
    vm.assume(
      uint256(rateDataToSet.baseVariableBorrowRate) +
        uint256(rateDataToSet.variableRateSlope1) +
        uint256(rateDataToSet.variableRateSlope2) >
        rateStrategy.MAX_BORROW_RATE()
    );

    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidMaxRate.selector));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateDataToSet));

    // Override
    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidMaxRate.selector));
    rateStrategy.setInterestRateParams(tokenList.usdx, rateDataToSet);
  }

  function test_reverts_SetReserveInterestRateParams_when_slope1_gt_slope2(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(
      optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(variableRateSlope1 > variableRateSlope2);

    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.Slope2MustBeGteSlope1.selector));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateData));

    // Override
    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.Slope2MustBeGteSlope1.selector));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateData));
  }
}
