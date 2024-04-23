// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {Errors} from 'aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import {WadRayMath} from 'aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol';
import {DefaultReserveInterestRateStrategyV2, IDefaultInterestRateStrategyV2, PercentageMath, IPoolAddressesProvider} from 'aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategyV2.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract RateStrategyBase is TestnetProcedures {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  struct Params {
    uint256 currentLiquidityRate;
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
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData,
    address token
  ) {
    _setRateParams(rateData, token);
    _;
  }

  function _validateSetRateParams(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData
  ) internal view {
    vm.assume(
      rateData.optimalUsageRatio >= rateStrategy.MIN_OPTIMAL_POINT() &&
        rateData.optimalUsageRatio <= rateStrategy.MAX_OPTIMAL_POINT()
    );

    vm.assume(rateData.variableRateSlope1 < rateData.variableRateSlope2);
    vm.assume(
      uint256(rateData.baseVariableBorrowRate) +
        uint256(rateData.variableRateSlope1) +
        uint256(rateData.variableRateSlope2) <=
        rateStrategy.MAX_BORROW_RATE()
    );
  }

  function _setRateParams(
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData,
    address token
  ) internal {
    _validateSetRateParams(rateData);

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
}
