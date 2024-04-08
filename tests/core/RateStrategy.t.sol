// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {Errors} from 'aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import {WadRayMath} from 'aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol';
import {DefaultReserveInterestRateStrategyV2, IDefaultInterestRateStrategyV2, PercentageMath, IPoolAddressesProvider} from 'aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategyV2.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract RateStrategyTests is TestnetProcedures {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  struct Params {
    uint256 currentLiquidityRate;
    uint256 currentStableBorrowRate;
    uint256 currentVariableBorrowRate;
  }

  uint256 public reserveFactor;
  address public aToken;
  DefaultReserveInterestRateStrategyV2 public rateStrategy;
  Params public params;
  uint256 public borrowUsageRatio;

  event RateDataUpdate(
    address indexed reserve,
    uint256 optimalUsageRatio,
    uint256 baseVariableBorrowRate,
    uint256 variableRateSlope1,
    uint256 variableRateSlope2
  );

  // sets limits for the fuzzing parameters and sets them on the interest rate strategy
  modifier setRateParams(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2,
    address token
  ) {
    _setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      token
    );
    _;
  }

  function _setRateParams(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2,
    address token
  ) internal {
    vm.assume(
      optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(variableRateSlope1 < variableRateSlope2);
    vm.assume(
      uint256(baseVariableBorrowRate) + uint256(variableRateSlope1) + uint256(variableRateSlope2) <=
        rateStrategy.MAX_BORROW_RATE()
    );
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);
    rateStrategy.setInterestRateParams(token, abi.encode(rateData));
  }

  function setUp() public {
    initTestEnvironment();

    (aToken, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
    rateStrategy = new DefaultReserveInterestRateStrategyV2(report.poolAddressesProvider);
    (, , , , reserveFactor, , , , , ) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );
  }

  //----------------------------------------------------------------------------------------------------
  //                                      INITIALIZATION TESTS
  //----------------------------------------------------------------------------------------------------
  function test_initialization() public view {
    assertEq(rateStrategy.MAX_OPTIMAL_POINT(), 99_00);
    assertEq(rateStrategy.MIN_OPTIMAL_POINT(), 1_00);
    assertEq(rateStrategy.MAX_BORROW_RATE(), 1000_00);
    assertEq(address(rateStrategy.ADDRESSES_PROVIDER()), address(report.poolAddressesProvider));
  }

  function test_new_DefaultReserveInterestRateStrategy_wrong_provider() public {
    vm.expectRevert(bytes(Errors.INVALID_ADDRESSES_PROVIDER));
    rateStrategy = new DefaultReserveInterestRateStrategyV2(address(0));
  }

  //----------------------------------------------------------------------------------------------------
  //                                         Test Getters
  //----------------------------------------------------------------------------------------------------
  function test_getInterestRateDataRay(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  )
    public
    setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      tokenList.usdx
    )
  {
    IDefaultInterestRateStrategyV2.InterestRateDataRay memory rateData = rateStrategy
      .getInterestRateData(tokenList.usdx);
    assertEq(uint256(optimalUsageRatio) * 1e23, rateData.optimalUsageRatio);
    assertEq(uint256(baseVariableBorrowRate) * 1e23, rateData.baseVariableBorrowRate);
    assertEq(uint256(variableRateSlope1) * 1e23, rateData.variableRateSlope1);
    assertEq(uint256(variableRateSlope2) * 1e23, rateData.variableRateSlope2);
  }

  function test_getInterestRateDataBps(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  )
    public
    setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      tokenList.usdx
    )
  {
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = rateStrategy
      .getInterestRateDataBps(tokenList.usdx);
    assertEq(optimalUsageRatio, rateData.optimalUsageRatio);
    assertEq(baseVariableBorrowRate, rateData.baseVariableBorrowRate);
    assertEq(variableRateSlope1, rateData.variableRateSlope1);
    assertEq(variableRateSlope2, rateData.variableRateSlope2);
  }

  function test_getMaxVariableBorrowRate(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  )
    public
    setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      tokenList.usdx
    )
  {
    uint256 maxVariableBorrowRate = rateStrategy.getMaxVariableBorrowRate(tokenList.usdx);
    assertEq(
      uint256(baseVariableBorrowRate + variableRateSlope1 + variableRateSlope2) * 1e23,
      maxVariableBorrowRate
    );
  }

  //----------------------------------------------------------------------------------------------------
  //                         Test Set interest Rate params Using FUZZING
  //----------------------------------------------------------------------------------------------------
  function test_new_SetReserveInterestRateParams_override_method_when_not_configurator(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(
      optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(variableRateSlope1 <= variableRateSlope2);
    vm.assume(
      uint256(baseVariableBorrowRate) + uint256(variableRateSlope1) + uint256(variableRateSlope2) <=
        rateStrategy.MAX_BORROW_RATE()
    );
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    rateStrategy.setInterestRateParams(tokenList.usdx, rateData);
  }

  function test_new_SetReserveInterestRateParams_when_not_configurator(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(
      optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(variableRateSlope1 <= variableRateSlope2);
    vm.assume(
      uint256(baseVariableBorrowRate) + uint256(variableRateSlope1) + uint256(variableRateSlope2) <=
        rateStrategy.MAX_BORROW_RATE()
    );
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_CONFIGURATOR));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateData));
  }

  function test_new_SetReserveInterestRateParams_override_method(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(
      optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(variableRateSlope1 <= variableRateSlope2);
    vm.assume(
      uint256(baseVariableBorrowRate) + uint256(variableRateSlope1) + uint256(variableRateSlope2) <=
        rateStrategy.MAX_BORROW_RATE()
    );
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);
    vm.expectEmit(true, false, false, true);
    emit RateDataUpdate(
      tokenList.usdx,
      uint256(rateData.optimalUsageRatio),
      uint256(rateData.baseVariableBorrowRate),
      uint256(rateData.variableRateSlope1),
      uint256(rateData.variableRateSlope2)
    );
    rateStrategy.setInterestRateParams(tokenList.usdx, rateData);

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

  function test_new_SetReserveInterestRateParams(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(
      optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );
    vm.assume(variableRateSlope1 <= variableRateSlope2);
    vm.assume(
      uint256(baseVariableBorrowRate) + uint256(variableRateSlope1) + uint256(variableRateSlope2) <=
        rateStrategy.MAX_BORROW_RATE()
    );

    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);
    vm.expectEmit(true, false, false, true);
    emit RateDataUpdate(
      tokenList.usdx,
      uint256(rateData.optimalUsageRatio),
      uint256(rateData.baseVariableBorrowRate),
      uint256(rateData.variableRateSlope1),
      uint256(rateData.variableRateSlope2)
    );
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateData));

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
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(bytes(Errors.ZERO_ADDRESS_NOT_VALID));
    rateStrategy.setInterestRateParams(address(0), abi.encode(rateData));
  }

  function test_reverts_SetReserveInterestRateParams_when_reserve_0_override_method(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(bytes(Errors.ZERO_ADDRESS_NOT_VALID));
    rateStrategy.setInterestRateParams(address(0), rateData);
  }

  function test_reverts_SetReserveInterestRateParams_when_gt_max_op(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(optimalUsageRatio > rateStrategy.MAX_OPTIMAL_POINT());

    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(bytes(Errors.INVALID_OPTIMAL_USAGE_RATIO));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateData));
  }

  function test_reverts_SetReserveInterestRateParams_when_gt_max_op_override_method(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(optimalUsageRatio > rateStrategy.MAX_OPTIMAL_POINT());

    //<<<<<<< HEAD
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });
    //=======
    //    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
    //      unbacked: 0,
    //      liquidityAdded: 0,
    //      liquidityTaken: 0,
    //      totalStableDebt: 0,
    //      totalVariableDebt: 0,
    //      averageStableBorrowRate: 0,
    //      reserveFactor: reserveFactor,
    //      reserve: tokenList.usdx,
    //      usingVirtualBalance: true,
    //      virtualUnderlyingBalance: 0
    //    });
    //>>>>>>> 44cf8077687ba552e6cbcbba7c7cdbbb4c68e34f

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(bytes(Errors.INVALID_OPTIMAL_USAGE_RATIO));
    rateStrategy.setInterestRateParams(tokenList.usdx, rateData);
  }

  function test_reverts_SetReserveInterestRateParams_when_lt_min_op(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(optimalUsageRatio < rateStrategy.MIN_OPTIMAL_POINT());

    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(bytes(Errors.INVALID_OPTIMAL_USAGE_RATIO));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateData));
  }

  function test_reverts_SetReserveInterestRateParams_when_lt_min_op_override_method(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(optimalUsageRatio < rateStrategy.MIN_OPTIMAL_POINT());

    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(bytes(Errors.INVALID_OPTIMAL_USAGE_RATIO));
    rateStrategy.setInterestRateParams(tokenList.usdx, rateData);
  }

  function test_reverts_SetReserveInterestRateParams_when_gt_maxRate(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(
      optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(variableRateSlope1 <= variableRateSlope2);
    vm.assume(
      uint256(baseVariableBorrowRate) + uint256(variableRateSlope1) + uint256(variableRateSlope2) >
        rateStrategy.MAX_BORROW_RATE()
    );

    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(bytes(Errors.INVALID_MAXRATE));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateData));
  }

  function test_reverts_SetReserveInterestRateParams_when_gt_maxRate_override_method(
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  ) public {
    vm.assume(
      optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(variableRateSlope1 <= variableRateSlope2);
    vm.assume(
      uint256(baseVariableBorrowRate) + uint256(variableRateSlope1) + uint256(variableRateSlope2) >
        rateStrategy.MAX_BORROW_RATE()
    );

    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: optimalUsageRatio,
        baseVariableBorrowRate: baseVariableBorrowRate,
        variableRateSlope1: variableRateSlope1,
        variableRateSlope2: variableRateSlope2
      });

    vm.prank(report.poolConfiguratorProxy);

    vm.expectRevert(bytes(Errors.INVALID_MAXRATE));
    rateStrategy.setInterestRateParams(tokenList.usdx, rateData);
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

    vm.expectRevert(bytes(Errors.SLOPE_2_MUST_BE_GTE_SLOPE_1));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateData));
  }

  function test_reverts_SetReserveInterestRateParams_when_slope1_gt_slope2_override_method(
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

    vm.expectRevert(bytes(Errors.SLOPE_2_MUST_BE_GTE_SLOPE_1));
    rateStrategy.setInterestRateParams(tokenList.usdx, abi.encode(rateData));
  }

  //----------------------------------------------------------------------------------------------------
  //                         Test Calculate Rates with specific conditions
  //----------------------------------------------------------------------------------------------------
  function test_calculate_rates_80_percent_usage()
    public
    setRateParams(uint16(80_00), uint32(1_00), uint32(4_00), uint32(60_00), tokenList.usdx)
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 800000000000000000,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 200000000000000000
    });
    (
      params.currentLiquidityRate,
      params.currentStableBorrowRate,
      params.currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx);

    assertEq(
      params.currentLiquidityRate,
      expectedVariableRate.percentMul(8000).percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );
    assertEq(params.currentStableBorrowRate, 0);
    assertEq(params.currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_calculate_rates_100_percent_usage()
    public
    setRateParams(uint16(80_00), uint32(1_00), uint32(4_00), uint32(60_00), tokenList.usdx)
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 1000000000000000000,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 0
    });

    (
      uint256 currentLiquidityRate,
      uint256 currentStableBorrowRate,
      uint256 currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx) +
      rateStrategy.getVariableRateSlope2(tokenList.usdx);

    assertEq(
      currentLiquidityRate,
      expectedVariableRate.percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );
    assertEq(currentStableBorrowRate, 0);
    assertEq(currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_calculate_rates_100_percent_usage_50_percent_stable_debt_50_percent_variable_debt_10_percent_avg_stable_rate()
    public
    setRateParams(uint16(80_00), uint32(1_00), uint32(4_00), uint32(60_00), tokenList.usdx)
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalStableDebt: 400000000000000000,
      totalVariableDebt: 400000000000000000,
      averageStableBorrowRate: 100000000000000000000000000,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 0
    });

    (
      uint256 currentLiquidityRate,
      uint256 currentStableBorrowRate,
      uint256 currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx) +
      rateStrategy.getVariableRateSlope2(tokenList.usdx);

    uint256 expectedLiquidityRate = ((currentVariableBorrowRate + 1e26) / 2).percentMul(
      100_00 - input.reserveFactor
    );

    assertEq(currentVariableBorrowRate, expectedVariableRate, 'Invalid variable  rate');
    assertEq(currentStableBorrowRate, 0);

    assertEq(currentLiquidityRate, expectedLiquidityRate, 'Invalid liquidity rate');
  }

  function test_calculate_rates_80_percent_usage_and_50_percent_supply_usage_due_minted_tokens()
    public
    setRateParams(uint16(80_00), uint32(1_00), uint32(4_00), uint32(60_00), tokenList.usdx)
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 600000000000000000,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 800000000000000000,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 200000000000000000
    });

    (
      uint256 currentLiquidityRate,
      uint256 currentStableBorrowRate,
      uint256 currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx);

    assertEq(
      currentLiquidityRate,
      expectedVariableRate.percentMul(5000).percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );

    assertEq(currentStableBorrowRate, 0);
    assertEq(currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_calculate_rates_80_percent_usage_and_80_bps_supply_usage_due_minted_tokens()
    public
    setRateParams(uint16(80_00), uint32(1_00), uint32(4_00), uint32(60_00), tokenList.usdx)
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 800000000000000000 * 124 - 200000000000000000,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 800000000000000000,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 200000000000000000
    });

    (
      uint256 currentLiquidityRate,
      uint256 currentStableBorrowRate,
      uint256 currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx);

    assertEq(
      currentLiquidityRate,
      expectedVariableRate.percentMul(80).percentMul(100_00 - input.reserveFactor),
      'Invalid liquidity rate'
    );

    assertEq(currentStableBorrowRate, 0);
    assertEq(currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_calculate_rates_80_bps_usage()
    public
    setRateParams(uint16(80_00), uint32(1_00), uint32(4_00), uint32(60_00), tokenList.usdx)
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 80000000000000000000,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 9920000000000000000000
    });
    (
      uint256 currentLiquidityRate,
      uint256 currentStableBorrowRate,
      uint256 currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

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
    assertEq(currentStableBorrowRate, 0);
    assertEq(currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');
  }

  function test_fuzz_calculate_rates_80_percent_usage_added_and_virtual_equal(
    uint256 virtualBalanceAmount
  ) public view {
    vm.assume(virtualBalanceAmount <= 200000000000000000);
    uint256 liquidityAddedAmount = 200000000000000000 - virtualBalanceAmount;

    // First, calculate using only virtual balance
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      reserve: tokenList.usdx,
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 800000000000000000,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 200000000000000000
    });

    (
      uint256 currentLiquidityRateOne,
      uint256 currentStableBorrowRateOne,
      uint256 currentVariableBorrowRateOne
    ) = rateStrategy.calculateInterestRates(input);

    // Second, calculate using the fuzzed values, totaling the same utilization
    input = DataTypes.CalculateInterestRatesParams({
      reserve: tokenList.usdx,
      unbacked: 0,
      liquidityAdded: liquidityAddedAmount,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 800000000000000000,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });

    (
      uint256 currentLiquidityRateTwo,
      uint256 currentStableBorrowRateTwo,
      uint256 currentVariableBorrowRateTwo
    ) = rateStrategy.calculateInterestRates(input);

    assertEq(currentLiquidityRateOne, currentLiquidityRateTwo, 'Invalid liquidity rate');

    assertEq(currentStableBorrowRateOne, currentStableBorrowRateTwo, 'Invalid stable rate');

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
    uint16 optimalUsageRatio,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2
  )
    public
    setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      tokenList.usdx
    )
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: 0,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 0,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: 0
    });

    (
      uint256 currentLiquidityRate,
      uint256 currentStableBorrowRate,
      uint256 currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

    assertEq(currentLiquidityRate, 0);
    assertEq(currentStableBorrowRate, 0);
    assertEq(currentVariableBorrowRate, rateStrategy.getBaseVariableBorrowRate(tokenList.usdx));
  }

  function test_calculate_rates_when_not_using_virtual_valance(
    uint16 optimalUsageRatio,
    uint256 availableLiquidity,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2,
    uint256 virtualBalanceAmount
  )
    public
    setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      tokenList.usdx
    )
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 0,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: false,
      virtualUnderlyingBalance: virtualBalanceAmount
    });
    (
      params.currentLiquidityRate,
      params.currentStableBorrowRate,
      params.currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

    assertEq(params.currentLiquidityRate, 0, 'Invalid liquidity rate');
    assertEq(params.currentStableBorrowRate, 0);
    assertEq(
      params.currentVariableBorrowRate,
      rateStrategy.getBaseVariableBorrowRate(tokenList.usdx),
      'Invalid variable rate'
    );
  }

  function test_calculate_rates_when_total_debt_0(
    uint16 optimalUsageRatio,
    uint256 availableLiquidity,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2,
    uint256 virtualBalanceAmount
  )
    public
    setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      tokenList.usdx
    )
  {
    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: 0,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });
    (
      params.currentLiquidityRate,
      params.currentStableBorrowRate,
      params.currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

    assertEq(params.currentLiquidityRate, 0, 'Invalid liquidity rate');
    assertEq(params.currentStableBorrowRate, 0);
    assertEq(
      params.currentVariableBorrowRate,
      rateStrategy.getBaseVariableBorrowRate(tokenList.usdx),
      'Invalid variable rate'
    );
  }

  function test_calculate_rates_below_op_usage(
    uint16 optimalUsageRatio,
    uint256 totalDebt,
    uint256 availableLiquidity,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2,
    uint256 virtualBalanceAmount
  ) public {
    _setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      tokenList.usdx
    );
    vm.assume(totalDebt > 0);
    vm.assume(totalDebt < availableLiquidity && availableLiquidity < 1e28);
    vm.assume(virtualBalanceAmount < 1e28);
    uint256 availableLiquidityPlusDebt = totalDebt + availableLiquidity + virtualBalanceAmount;
    borrowUsageRatio = totalDebt.rayDiv(availableLiquidityPlusDebt);
    vm.assume(borrowUsageRatio < (uint256(optimalUsageRatio) * 1e23));

    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: totalDebt,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });

    (
      params.currentLiquidityRate,
      params.currentStableBorrowRate,
      params.currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

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
    assertEq(params.currentStableBorrowRate, 0);

    assertApproxEqAbs(
      params.currentLiquidityRate,
      (
        input.totalVariableDebt.wadToRay().rayMul(expectedVariableRate).rayDiv(
          input.totalVariableDebt.wadToRay()
        )
      ).rayMul(input.totalVariableDebt.rayDiv(availableLiquidityPlusDebt)).percentMul(
          100_00 - input.reserveFactor
        ),
      100,
      'Invalid liquidity rate'
    );
  }

  function test_calculate_rates_below_op_usage_when_no_debt(
    uint16 optimalUsageRatio,
    uint256 availableLiquidity,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2,
    uint256 virtualBalanceAmount
  )
    public
    setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      tokenList.usdx
    )
  {
    uint256 totalDebt = 0;
    vm.assume(totalDebt < availableLiquidity && availableLiquidity < 1e28);
    uint256 availableLiquidityPlusDebt = totalDebt + availableLiquidity;
    borrowUsageRatio = totalDebt.rayDiv(availableLiquidityPlusDebt);
    vm.assume(borrowUsageRatio < (uint256(optimalUsageRatio) * 1e23));

    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: totalDebt,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });

    (
      params.currentLiquidityRate,
      params.currentStableBorrowRate,
      params.currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

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
    assertEq(params.currentStableBorrowRate, 0);

    assertEq(params.currentLiquidityRate, 0, 'Invalid liquidity rate');
  }

  function test_calculate_rates_above_op_usage(
    uint16 optimalUsageRatio,
    uint256 totalDebt,
    uint256 availableLiquidity,
    uint32 baseVariableBorrowRate,
    uint32 variableRateSlope1,
    uint32 variableRateSlope2,
    uint256 virtualBalanceAmount
  )
    public
    setRateParams(
      optimalUsageRatio,
      baseVariableBorrowRate,
      variableRateSlope1,
      variableRateSlope2,
      tokenList.usdx
    )
  {
    availableLiquidity = bound(availableLiquidity, 1, 1e28);
    totalDebt = bound(totalDebt, 1, availableLiquidity);
    vm.assume(virtualBalanceAmount < 1e28);
    uint256 availableLiquidityPlusDebt = totalDebt + availableLiquidity + virtualBalanceAmount;

    borrowUsageRatio = totalDebt.rayDiv(availableLiquidityPlusDebt);
    vm.assume(borrowUsageRatio > (uint256(optimalUsageRatio) * 1e23));

    DataTypes.CalculateInterestRatesParams memory input = DataTypes.CalculateInterestRatesParams({
      unbacked: 0,
      liquidityAdded: availableLiquidity,
      liquidityTaken: 0,
      totalStableDebt: 0,
      totalVariableDebt: totalDebt,
      averageStableBorrowRate: 0,
      reserveFactor: reserveFactor,
      reserve: tokenList.usdx,
      usingVirtualBalance: true,
      virtualUnderlyingBalance: virtualBalanceAmount
    });

    (
      params.currentLiquidityRate,
      params.currentStableBorrowRate,
      params.currentVariableBorrowRate
    ) = rateStrategy.calculateInterestRates(input);

    uint256 excessBorrowUsageRatio = (borrowUsageRatio -
      rateStrategy.getOptimalUsageRatio(tokenList.usdx)).rayDiv(
        WadRayMath.RAY - rateStrategy.getOptimalUsageRatio(tokenList.usdx)
      );

    uint256 expectedVariableRate = rateStrategy.getBaseVariableBorrowRate(tokenList.usdx) +
      rateStrategy.getVariableRateSlope1(tokenList.usdx) +
      rateStrategy.getVariableRateSlope2(tokenList.usdx).rayMul(excessBorrowUsageRatio);

    assertEq(params.currentVariableBorrowRate, expectedVariableRate, 'Invalid variable rate');

    assertEq(params.currentStableBorrowRate, 0);
    assertEq(
      params.currentLiquidityRate,
      (
        input.totalVariableDebt.wadToRay().rayMul(expectedVariableRate).rayDiv(
          input.totalVariableDebt.wadToRay()
        )
      ).rayMul(input.totalVariableDebt.rayDiv(availableLiquidityPlusDebt)).percentMul(
          100_00 - input.reserveFactor
        ),
      'Invalid liquidity rate'
    );
  }
}
