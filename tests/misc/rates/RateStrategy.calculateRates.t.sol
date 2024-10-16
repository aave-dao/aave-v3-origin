// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import './RateStrategy.template.sol';

contract RateStrategyCalculateRatesTests is RateStrategyBase {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  //----------------------------------------------------------------------------------------------------
  //                         Test Calculate Rates with specific conditions
  //----------------------------------------------------------------------------------------------------
  function test_calculate_rates_80_percent_usage()
    public
    setRateParams(
      IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: uint16(80_00),
        baseVariableBorrowRate: uint32(1_00),
        variableRateSlope1: uint32(4_00),
        variableRateSlope2: uint32(60_00)
      }),
      tokenList.usdx
    )
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalDebt: 800000000000000000,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 200000000000000000
    });
    (params.currentLiquidityRate, params.currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx);

    assertEq(
      params.currentLiquidityRate,
      expectedVariableRate.percentMul(8000).percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );
    assertEq(params.currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_calculate_rates_100_percent_usage()
    public
    setRateParams(
      IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: uint16(80_00),
        baseVariableBorrowRate: uint32(1_00),
        variableRateSlope1: uint32(4_00),
        variableRateSlope2: uint32(60_00)
      }),
      tokenList.usdx
    )
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalDebt: 1000000000000000000,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 0
    });

    (uint256 currentLiquidityRate, uint256 currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx) +
      rateStrategy.getVariableRateSlope2(tokenList.usdx);

    assertEq(
      currentLiquidityRate,
      expectedVariableRate.percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );
    assertEq(currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_calculate_rates_80_percent_usage_and_50_percent_supply_usage_due_minted_tokens()
    public
    setRateParams(
      IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: uint16(80_00),
        baseVariableBorrowRate: uint32(1_00),
        variableRateSlope1: uint32(4_00),
        variableRateSlope2: uint32(60_00)
      }),
      tokenList.usdx
    )
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 600000000000000000,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalDebt: 800000000000000000,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 200000000000000000
    });

    (uint256 currentLiquidityRate, uint256 currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx);

    assertEq(
      currentLiquidityRate,
      expectedVariableRate.percentMul(5000).percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );

    assertEq(currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_calculate_rates_80_percent_usage_and_80_bps_supply_usage_due_minted_tokens()
    public
    setRateParams(
      IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: uint16(80_00),
        baseVariableBorrowRate: uint32(1_00),
        variableRateSlope1: uint32(4_00),
        variableRateSlope2: uint32(60_00)
      }),
      tokenList.usdx
    )
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 800000000000000000 * 124 - 200000000000000000,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalDebt: 800000000000000000,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 200000000000000000
    });

    (uint256 currentLiquidityRate, uint256 currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx);

    assertEq(
      currentLiquidityRate,
      expectedVariableRate.percentMul(80).percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );

    assertEq(currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_calculate_rates_80_bps_usage()
    public
    setRateParams(
      IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: uint16(80_00),
        baseVariableBorrowRate: uint32(1_00),
        variableRateSlope1: uint32(4_00),
        variableRateSlope2: uint32(60_00)
      }),
      tokenList.usdx
    )
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalDebt: 80000000000000000000,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 9920000000000000000000
    });
    (uint256 currentLiquidityRate, uint256 currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    uint256 usageRatio = _bpsToRay(80);
    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx).rayMul(
        usageRatio.rayDiv(rateStrategy.getOptimalUsageRatio(tokenList.usdx))
      );
    assertEq(
      currentLiquidityRate,
      expectedVariableRate.percentMul(80).percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );
    assertEq(currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_fuzz_calculate_rates_80_percent_usage_added_and_virtual_equal(
    uint256 virtualBalanceAmount
  ) public view {
    virtualBalanceAmount = bound(virtualBalanceAmount, 0, 200000000000000000);
    uint256 liquidityAddedAmount = 200000000000000000 - virtualBalanceAmount;

    // First, calculate using only virtual balance
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      reserve: tokenList.usdx,
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalDebt: 800000000000000000,
      reserveFactor: reserveFactor,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 200000000000000000
    });

    (uint256 currentLiquidityRateOne, uint256 currentVariableBorrowRateOne) = rateStrategy
      .calculateInterestRates(input);

    // Second, calculate using the fuzzed values, totaling the same utilization
    input = DataTypes.CalculateInterestRatesParams({
      reserve: tokenList.usdx,
      unbacked: 0,
      liquidityAdded: liquidityAddedAmount,
      liquidityTaken: 0,
      totalDebt: 800000000000000000,
      reserveFactor: reserveFactor,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });

    (uint256 currentLiquidityRateTwo, uint256 currentVariableBorrowRateTwo) = rateStrategy
      .calculateInterestRates(input);

    assertEq(currentLiquidityRateOne, currentLiquidityRateTwo, 'Invalid liquidity rate');

    assertEq(currentVariableBorrowRateOne, currentVariableBorrowRateTwo, 'Invalid variable rate');

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx);

    assertEq(
      currentLiquidityRateTwo,
      expectedVariableRate.percentMul(8000).percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );

    assertEq(currentVariableBorrowRateTwo, expectedVariableRate, 'Invalid variable rate');
  }

  //----------------------------------------------------------------------------------------------------
  //                         Test Calculate Rates with FUZZING
  //----------------------------------------------------------------------------------------------------
  function test_calculate_rates_empty_reserve(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) public setRateParams(rateData, tokenList.usdx) {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalDebt: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 0
    });

    (uint256 currentLiquidityRate, uint256 currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    assertEq(currentLiquidityRate, 0);
    assertEq(currentVariableBorrowRate, rateStrategy.getBaseVariableBorrowRate(tokenList.usdx));
  }

  function test_calculate_rates_when_not_using_virtual_valance(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData,
    uint256 availableLiquidity,
    uint256 virtualBalanceAmount
  ) public setRateParams(rateData, tokenList.usdx) {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalDebt: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: false,
      virtualUnderlyingBalance: virtualBalanceAmount
    });
    (params.currentLiquidityRate, params.currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    assertEq(params.currentLiquidityRate, 0, 'Invalid liquidity rate');
    assertEq(
      params.currentVariableBorrowRate,
      rateStrategy.getBaseVariableBorrowRate(tokenList.usdx),
      'Invalid variable rate'
    );
  }

  function test_calculate_rates_when_total_debt_0(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData,
    uint256 availableLiquidity,
    uint256 virtualBalanceAmount
  ) public setRateParams(rateData, tokenList.usdx) {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalDebt: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });
    (params.currentLiquidityRate, params.currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    assertEq(params.currentLiquidityRate, 0, 'Invalid liquidity rate');
    assertEq(
      params.currentVariableBorrowRate,
      rateStrategy.getBaseVariableBorrowRate(tokenList.usdx),
      'Invalid variable rate'
    );
  }

  function test_calculate_rates_below_op_usage(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData,
    uint256 totalDebt,
    uint256 availableLiquidity,
    uint256 virtualBalanceAmount
  ) public setRateParams(rateData, tokenList.usdx) {
    availableLiquidity = bound(availableLiquidity, 2, 1e28 - 1);
    totalDebt = bound(totalDebt, 1, availableLiquidity - 1);
    virtualBalanceAmount = bound(virtualBalanceAmount, 0, 1e28);
    uint256 availableLiquidityPlusDebt = totalDebt + availableLiquidity + virtualBalanceAmount;
    borrowUsageRatio = totalDebt.rayDiv(availableLiquidityPlusDebt);
    vm.assume(borrowUsageRatio < (uint256(rateData.optimalUsageRatio) * 1e23));

    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalDebt: totalDebt,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });

    (params.currentLiquidityRate, params.currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx).rayMul(
        borrowUsageRatio.rayDiv(rateStrategy.getOptimalUsageRatio(tokenList.usdx))
      );

    assertApproxEqAbs(
      params.currentVariableBorrowRate,
      expectedVariableRate,
      100,
      'Invalid variable rate'
    );

    assertApproxEqAbs(
      params.currentLiquidityRate,
      expectedVariableRate.rayMul(input.totalDebt.rayDiv(availableLiquidityPlusDebt)).percentMul(
        100_00 - input.reserveFactor
      ),
      100,
      'Invalid liquidity rate'
    );
  }

  function test_calculate_rates_below_op_usage_when_no_debt(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData,
    uint256 availableLiquidity,
    uint256 virtualBalanceAmount
  ) public setRateParams(rateData, tokenList.usdx) {
    uint256 totalDebt = 0;
    vm.assume(totalDebt < availableLiquidity && availableLiquidity < 1e28);
    uint256 availableLiquidityPlusDebt = totalDebt + availableLiquidity;
    borrowUsageRatio = totalDebt.rayDiv(availableLiquidityPlusDebt);
    vm.assume(borrowUsageRatio < (uint256(rateData.optimalUsageRatio) * 1e23));

    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalDebt: totalDebt,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });

    (params.currentLiquidityRate, params.currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx).rayMul(
        borrowUsageRatio.rayDiv(rateStrategy.getOptimalUsageRatio(tokenList.usdx))
      );

    assertApproxEqAbs(
      params.currentVariableBorrowRate,
      expectedVariableRate,
      100,
      'Invalid variable rate'
    );

    assertEq(params.currentLiquidityRate, 0, 'Invalid liquidity rate');
  }

  function test_calculate_rates_above_op_usage(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData,
    uint256 totalDebt,
    uint256 availableLiquidity,
    uint256 virtualBalanceAmount
  ) public setRateParams(rateData, tokenList.usdx) {
    availableLiquidity = bound(availableLiquidity, 1, 1e28 - 1);
    totalDebt = bound(totalDebt, 1, availableLiquidity);
    virtualBalanceAmount = bound(virtualBalanceAmount, 0, 1e28 - 1);
    uint256 availableLiquidityPlusDebt = totalDebt + availableLiquidity + virtualBalanceAmount;

    borrowUsageRatio = totalDebt.rayDiv(availableLiquidityPlusDebt);
    vm.assume(borrowUsageRatio > (uint256(rateData.optimalUsageRatio) * 1e23));

    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalDebt: totalDebt,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });

    (params.currentLiquidityRate, params.currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    uint256 excessBorrowUsageRatio = (borrowUsageRatio -
      rateStrategy.getOptimalUsageRatio(tokenList.usdx)).rayDiv(
        WadRayMath.RAY - rateStrategy.getOptimalUsageRatio(tokenList.usdx)
      );

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx) +
      rateStrategy.getVariableRateSlope2(tokenList.usdx).rayMul(excessBorrowUsageRatio);

    assertEq(params.currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');

    assertEq(
      params.currentLiquidityRate,
      expectedVariableRate.rayMul(input.totalDebt.rayDiv(availableLiquidityPlusDebt)).percentMul(
        100_00 - input.reserveFactor
      ),
      'Invalid liquidity rate'
    );
  }

  function test_zero_rates_strategy_calculate_rates() public view {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 10,
      liquidityAdded: 1000,
      liquidityTaken: 50,
      totalDebt: 20,
      reserveFactor: reserveFactor,
      reserve: tokenList.wbtc,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 30000
    });

    (uint256 currentLiquidityRate, uint256 currentVariableBorrowRate) = rateStrategy
      .calculateInterestRates(input);

    assertEq(currentLiquidityRate, 0);
    assertEq(currentVariableBorrowRate, 0);
  }
}
