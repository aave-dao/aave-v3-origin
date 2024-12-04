// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';

/**
 * Scenario suite for borrow/repay operations.
 */
contract PoolBorrow_gas_Tests is Testhelpers {
  // mock users to supply and borrow liquidity
  address borrower = makeAddr('borrower');

  function setUp() public override {
    super.setUp();
    // setup testUser with some collateral
    _supplyOnReserve(borrower, 100 ether, tokenList.weth);
  }

  function test_borrow() external {
    uint256 amountToBorrow = 1000e6;
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    vm.snapshotGasLastCall('Pool.Borrow', 'first borrow');

    _skip(100); // skip some blocks to allow interest to accrue & the block to be cold
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    vm.snapshotGasLastCall('Pool.Borrow', 'second borrow');
  }

  function test_repay() external {
    uint256 amountToBorrow = 1000e6;
    deal(tokenList.usdx, borrower, amountToBorrow);
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    IERC20(tokenList.usdx).approve(report.poolProxy, type(uint256).max);

    _skip(100); // skip some blocks to allow interest to accrue & the block to be cold
    contracts.poolProxy.repay(tokenList.usdx, amountToBorrow / 2, 2, borrower);
    vm.snapshotGasLastCall('Pool.Borrow', 'repay partial');

    _skip(100); // skip some blocks to allow interest to accrue & the block to be cold
    contracts.poolProxy.repay(tokenList.usdx, type(uint256).max, 2, borrower);
    vm.snapshotGasLastCall('Pool.Borrow', 'repay full');
  }
}
