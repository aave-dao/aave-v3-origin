// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import './RateStrategy.template.sol';

contract RateStrategySettersTests is RateStrategyBase {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  // @dev we override it to test second version of setInterestRateParams later
  function _setInterestRateParams(
    address token,
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) internal virtual {
    rateStrategy.setInterestRateParams(token, abi.encode(rateData));
  }

  //----------------------------------------------------------------------------------------------------
  //                         Test Set interest Rate params Using FUZZING
  //----------------------------------------------------------------------------------------------------
  function test_new_SetReserveInterestRateParams_when_not_configurator(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) public {
    _validateSetRateParams(rateData);

    vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotPoolConfigurator.selector));
    _setInterestRateParams(tokenList.usdx, rateData);
  }

  function test_new_SetReserveInterestRateParams(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) public {
    _validateSetRateParams(rateData);

    vm.prank(report.poolConfiguratorProxy);
    vm.expectEmit(true, false, false, true);
    emit IDefaultInterestRateStrategyV2.RateDataUpdate(
      tokenList.usdx,
      rateData.optimalUsageRatio,
      rateData.baseVariableBorrowRate,
      rateData.variableRateSlope1,
      rateData.variableRateSlope2
    );
    _setInterestRateParams(tokenList.usdx, rateData);

    assertEq(address(rateStrategy.ADDRESSES_PROVIDER()), report.poolAddressesProvider);
    assertEq(
      rateStrategy.getOptimalUsageRatio(tokenList.usdx),
      uint256(rateData.optimalUsageRatio) * 1e23
    );
    assertEq(
      rateStrategy.getVariableRateSlope1(tokenList.usdx),
      uint256(rateData.variableRateSlope1) * 1e23
    );
    assertEq(
      rateStrategy.getVariableRateSlope2(tokenList.usdx),
      uint256(rateData.variableRateSlope2) * 1e23
    );
    assertEq(
      rateStrategy.getBaseVariableBorrowRate(tokenList.usdx),
      uint256(rateData.baseVariableBorrowRate) * 1e23
    );
    assertEq(
      rateStrategy.getMaxVariableBorrowRate(tokenList.usdx),
      uint256(
        rateData.baseVariableBorrowRate + rateData.variableRateSlope1 + rateData.variableRateSlope2
      ) * 1e23
    );
  }

  function test_reverts_SetReserveInterestRateParams_when_reserve_0(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) public {
    _validateSetRateParams(rateData);

    vm.prank(report.poolConfiguratorProxy);
    vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressNotValid.selector));
    _setInterestRateParams(address(0), rateData);
  }

  function test_reverts_SetReserveInterestRateParams_when_gt_max_op(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) public {
    vm.assume(rateData.optimalUsageRatio > rateStrategy.MAX_OPTIMAL_POINT());

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidOptimalUsageRatio.selector));
    _setInterestRateParams(tokenList.usdx, rateData);
  }

  function test_reverts_SetReserveInterestRateParams_when_lt_min_op(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) public {
    vm.assume(rateData.optimalUsageRatio < rateStrategy.MIN_OPTIMAL_POINT());

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidOptimalUsageRatio.selector));
    _setInterestRateParams(tokenList.usdx, rateData);
  }

  function test_reverts_SetReserveInterestRateParams_when_gt_maxRate(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) public {
    rateData.optimalUsageRatio = uint16(
      bound(
        rateData.optimalUsageRatio,
        rateStrategy.MIN_OPTIMAL_POINT(),
        rateStrategy.MAX_OPTIMAL_POINT()
      )
    );
    rateData.variableRateSlope1 = uint32(
      bound(rateData.variableRateSlope1, 0, rateData.variableRateSlope2)
    );
    vm.assume(
      uint256(rateData.baseVariableBorrowRate) +
        uint256(rateData.variableRateSlope1) +
        uint256(rateData.variableRateSlope2) >
        rateStrategy.MAX_BORROW_RATE()
    );

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidMaxRate.selector));
    _setInterestRateParams(tokenList.usdx, rateData);
  }

  function test_reverts_SetReserveInterestRateParams_when_slope1_gt_slope2(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) public {
    vm.assume(
      rateData.optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        rateData.optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(rateData.variableRateSlope1 > rateData.variableRateSlope2);

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(abi.encodeWithSelector(Errors.Slope2MustBeGteSlope1.selector));
    _setInterestRateParams(tokenList.usdx, rateData);
  }
}

contract RateStrategySettersTestsOverride is RateStrategySettersTests {
  function _setInterestRateParams(
    address token,
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) internal override {
    rateStrategy.setInterestRateParams(token, rateData);
  }
}
