// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {DefaultReserveInterestRateStrategyV2, IDefaultInterestRateStrategyV2, PercentageMath, IPoolAddressesProvider} from '../../../src/contracts/misc/DefaultReserveInterestRateStrategyV2.sol';
import {IPoolConfigurator} from '../../../src/contracts/interfaces/IPoolConfigurator.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

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

    aToken = contracts.poolProxy.getReserveAToken(tokenList.usdx);

    rateStrategy = DefaultReserveInterestRateStrategyV2(
      address(contracts.defaultInterestRateStrategy)
    );
    (, , , , reserveFactor, , , , , ) = contracts.protocolDataProvider.getReserveConfigurationData(
      tokenList.usdx
    );

    vm.startPrank(poolAdmin);
    IPoolConfigurator(report.poolConfiguratorProxy).setReserveInterestRateData(
      tokenList.usdx,
      _getDefaultInterestRatesStrategyData()
    );
    vm.stopPrank();
  }
}
