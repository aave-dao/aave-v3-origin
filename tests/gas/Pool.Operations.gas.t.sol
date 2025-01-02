// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';

/**
 * Scenario suite for common operations supply/borrow/repay/withdraw/liquidationCall.
 */
contract PoolOperations_gas_Tests is Testhelpers {
  address supplier = makeAddr('supplier');
  address borrower = makeAddr('borrower');
  address liquidator = makeAddr('liquidator');

  function test_supply() external {
    // borrow some, so hf checks are not skipped
    _supplyOnReserve(supplier, 1 ether, tokenList.weth);
    _borrowArbitraryAmount(supplier, 1e5, tokenList.wbtc);

    _supplyOnReserve(supplier, 100e6, tokenList.usdx);
    vm.snapshotGasLastCall('Pool.Operations', 'supply: first supply->collateralEnabled');

    _skip(100);

    _supplyOnReserve(supplier, 100e6, tokenList.usdx);
    vm.snapshotGasLastCall('Pool.Operations', 'supply: collateralEnabled');
    vm.prank(supplier);
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.usdx, false);

    _skip(100);

    _supplyOnReserve(supplier, 100e6, tokenList.usdx);
    vm.snapshotGasLastCall('Pool.Operations', 'supply: collateralDisabled');
  }

  function test_withdraw() external {
    _supplyOnReserve(supplier, 100e6, tokenList.usdx);
    vm.startPrank(supplier);
    _skip(100);

    contracts.poolProxy.withdraw(tokenList.usdx, 50e6, supplier);
    vm.snapshotGasLastCall('Pool.Operations', 'withdraw: partial withdraw');

    _skip(100);

    contracts.poolProxy.withdraw(tokenList.usdx, type(uint256).max, supplier);
    vm.snapshotGasLastCall('Pool.Operations', 'withdraw: full withdraw');
  }

  function test_withdraw_with_active_borrows() external {
    _supplyOnReserve(borrower, 100 ether, tokenList.weth);
    uint256 amountToBorrow = 1000e6;
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    _skip(100);

    contracts.poolProxy.withdraw(tokenList.weth, 1 ether, supplier);
    vm.snapshotGasLastCall('Pool.Operations', 'withdraw: partial withdraw with active borrows');
  }

  function test_borrow() external {
    _supplyOnReserve(borrower, 100 ether, tokenList.weth);
    uint256 amountToBorrow = 1000e6;
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'borrow: first borrow->borrowingEnabled');

    _skip(100);

    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'borrow: recurrent borrow');
  }

  function test_repay() external {
    _supplyOnReserve(borrower, 100 ether, tokenList.weth);
    uint256 amountToBorrow = 1000e6;
    deal(tokenList.usdx, borrower, amountToBorrow);
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    IERC20(tokenList.usdx).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.repay(tokenList.usdx, amountToBorrow / 2, 2, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'repay: partial repay');

    _skip(100);

    contracts.poolProxy.repay(tokenList.usdx, type(uint256).max, 2, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'repay: full repay');
  }

  function test_repay_with_ATokens() external {
    _supplyOnReserve(borrower, 1_000_000e6, tokenList.usdx);
    uint256 amountToBorrow = 1000e6;
    deal(tokenList.usdx, borrower, amountToBorrow);
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    IERC20(tokenList.usdx).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.repayWithATokens(tokenList.usdx, amountToBorrow / 2, 2);
    vm.snapshotGasLastCall('Pool.Operations', 'repay: partial repay with ATokens');

    _skip(100);

    contracts.poolProxy.repayWithATokens(tokenList.usdx, type(uint256).max, 2);
    vm.snapshotGasLastCall('Pool.Operations', 'repay: full repay with ATokens');
  }

  function test_liquidationCall_partial() external {
    // on v3.3 the amounts need to be adjusted to not cause error 103 (min leftover) issues
    uint256 scalingFactor = 10;
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(
      borrower,
      ((((price * 1e6) / 1e8) * 90) / 100) * scalingFactor,
      tokenList.usdx
    );
    _borrowArbitraryAmount(borrower, 1 ether * scalingFactor, tokenList.weth);
    deal(tokenList.weth, liquidator, 0.5 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, 0.5 ether);

    _skip(100);

    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.weth, borrower, 0.5 ether, false);
    vm.snapshotGasLastCall('Pool.Operations', 'liquidationCall: partial liquidation');
  }

  function test_liquidationCall_full() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (((price * 1e6) / 1e8) * 90) / 100, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 1 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 2 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.weth,
      borrower,
      type(uint256).max,
      false
    );
    vm.snapshotGasLastCall('Pool.Operations', 'liquidationCall: full liquidation');
  }

  function test_liquidationCall_receive_ATokens_partial() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (((price * 3e6) / 1e8) * 90) / 100, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 3 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 0.5 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, 0.5 ether);

    _skip(100);

    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.weth, borrower, 0.5 ether, true);
    vm.snapshotGasLastCall(
      'Pool.Operations',
      'liquidationCall: partial liquidation and receive ATokens'
    );
  }

  function test_liquidationCall_receive_ATokens_full() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (((price * 1e6) / 1e8) * 90) / 100, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 1 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 2 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.weth,
      borrower,
      type(uint256).max,
      true
    );
    vm.snapshotGasLastCall(
      'Pool.Operations',
      'liquidationCall: full liquidation and receive ATokens'
    );
  }

  function test_liquidationCall_deficit() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (price * 1e6) / 1e8, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 1 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 2 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.weth,
      borrower,
      type(uint256).max,
      false
    );
    vm.snapshotGasLastCall('Pool.Operations', 'liquidationCall: deficit on liquidated asset');
  }

  function test_liquidationCall_deficitInAdditionalReserve() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (price * 1e6) / 1e8, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 1e5, tokenList.wbtc); // additional deficit
    _borrowArbitraryAmount(borrower, 1 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 2 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.weth,
      borrower,
      type(uint256).max,
      false
    );
    vm.snapshotGasLastCall(
      'Pool.Operations',
      'liquidationCall: deficit on liquidated asset + other asset'
    );
  }
}
