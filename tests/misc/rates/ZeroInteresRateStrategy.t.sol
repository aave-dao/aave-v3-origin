// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken} from '../../../src/contracts/protocol/tokenization/AToken.sol';
import {DefaultReserveInterestRateStrategyV2, DataTypes, IPoolAddressesProvider, IDefaultInterestRateStrategyV2} from '../../../src/contracts/misc/DefaultReserveInterestRateStrategyV2.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

// @dev Ignored from coverage report, due Foundry Coverage can not detect functions if they return 0.
contract ZeroReserveInterestRateStrategyTests is TestnetProcedures {
  IAToken public aToken;

  function setUp() public {
    initTestEnvironment();

    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
    aToken = IAToken(aUSDX);
  }

  function test_new_ZeroReserveInterestRateStrategy()
    public
    returns (IDefaultInterestRateStrategyV2)
  {
    IDefaultInterestRateStrategyV2 rateStrategy = new DefaultReserveInterestRateStrategyV2(
      report.poolAddressesProvider
    );

    assertEq(address(rateStrategy.ADDRESSES_PROVIDER()), report.poolAddressesProvider);
    assertEq(rateStrategy.getOptimalUsageRatio(tokenList.usdx), 0);
    assertEq(rateStrategy.getVariableRateSlope1(tokenList.usdx), 0);
    assertEq(rateStrategy.getVariableRateSlope2(tokenList.usdx), 0);
    assertEq(rateStrategy.getBaseVariableBorrowRate(tokenList.usdx), 0);
    assertEq(rateStrategy.getMaxVariableBorrowRate(tokenList.usdx), 0);
    return rateStrategy;
  }

  function test_calculate_rates() public {
    (, , , , uint256 reserveFactor, , , , , ) = contracts
      .protocolDataProvider
      .getReserveConfigurationData(tokenList.usdx);
    IDefaultInterestRateStrategyV2 rateStrategy = test_new_ZeroReserveInterestRateStrategy();

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
    assertEq(currentVariableBorrowRate, 0);
  }
}
