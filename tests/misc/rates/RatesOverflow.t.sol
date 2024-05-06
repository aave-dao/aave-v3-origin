// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {MockReserveInterestRateStrategy} from '../../../src/contracts/mocks/tests/MockReserveInterestRateStrategy.sol';
import {IPoolConfigurator} from '../../../src/contracts/interfaces/IPoolConfigurator.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

// @dev Ignored from coverage report, due Foundry Coverage can not detect functions if they return 0.
contract RatesOverflowCheckTests is TestnetProcedures {
  MockReserveInterestRateStrategy internal mockRateStrategy;

  function setUp() public {
    initTestEnvironment();

    mockRateStrategy = new MockReserveInterestRateStrategy(report.poolAddressesProvider);

    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);

    vm.startPrank(poolAdmin);
    IPoolConfigurator(report.poolConfiguratorProxy).setReserveInterestRateStrategyAddress(
      tokenList.usdx,
      address(mockRateStrategy),
      _getDefaultInterestRatesStrategyData()
    );

    IPoolConfigurator(report.poolConfiguratorProxy).setReserveStableRateBorrowing(
      tokenList.usdx,
      true
    );
    vm.stopPrank();
  }

  function test_overflow_liquidity_rates() public {
    mockRateStrategy.setLiquidityRate(UINT256_MAX);

    vm.expectRevert(bytes("SafeCast: value doesn't fit in 128 bits"));
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.usdx, 1000e6, alice, 0);
  }

  function test_overflow_variable_rates() public {
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 1e8, alice, 0);

    mockRateStrategy.setVariableBorrowRate(UINT256_MAX);

    vm.expectRevert(bytes("SafeCast: value doesn't fit in 128 bits"));

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, 10e6, 2, 0, alice);
  }
}
