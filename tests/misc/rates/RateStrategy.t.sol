// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import './RateStrategy.template.sol';

contract RateStrategyBaseTests is RateStrategyBase {
  //----------------------------------------------------------------------------------------------------
  //                                      INITIALIZATION TESTS
  //----------------------------------------------------------------------------------------------------
  function test_initialization() public view {
    assertEq(rateStrategy.MAX_OPTIMAL_POINT(), 99_00);
    assertEq(rateStrategy.MIN_OPTIMAL_POINT(), 1_00);
    assertEq(rateStrategy.MAX_BORROW_RATE(), 1000_00);
    assertEq(address(rateStrategy.ADDRESSES_PROVIDER()), address(report.poolAddressesProvider));

    assertEq(rateStrategy.getOptimalUsageRatio(tokenList.wbtc), 0);
    assertEq(rateStrategy.getVariableRateSlope1(tokenList.wbtc), 0);
    assertEq(rateStrategy.getVariableRateSlope2(tokenList.wbtc), 0);
    assertEq(rateStrategy.getBaseVariableBorrowRate(tokenList.wbtc), 0);
    assertEq(rateStrategy.getMaxVariableBorrowRate(tokenList.wbtc), 0);
  }

  function test_new_DefaultReserveInterestRateStrategy_wrong_provider() public {
    vm.expectRevert(bytes(Errors.INVALID_ADDRESSES_PROVIDER));
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
    vm.expectRevert(bytes("SafeCast: value doesn't fit in 128 bits"));
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 1000e6, alice, 0);
  }

  function test_overflow_variable_rates() public {
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);

    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);

    vm.mockCall(
      address(rateStrategy),
      abi.encodeWithSelector(rateStrategy.calculateInterestRates.selector),
      abi.encode(0, UINT256_MAX)
    );
    vm.expectRevert(bytes("SafeCast: value doesn't fit in 128 bits"));
    contracts.poolProxy.borrow(tokenList.usdx, 10e6, 2, 0, alice);
    vm.stopPrank();
  }
}
