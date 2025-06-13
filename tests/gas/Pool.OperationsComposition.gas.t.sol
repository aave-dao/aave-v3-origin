// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Multicall} from 'openzeppelin-contracts/contracts/utils/Multicall.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';

/**
 * Scenario suite for common operations supply/borrow/repay/withdraw/liquidationCall.
 */
/// forge-config: default.isolate = true
contract PoolOperationsComposition_gas_Tests is Testhelpers {
  address supplier = makeAddr('supplier');
  address borrower = makeAddr('borrower');
  address liquidator = makeAddr('liquidator');

  function test_supplyAndBorrow() external {
    vm.startPrank(supplier);
    deal(tokenList.weth, supplier, 1e18);
    IERC20(tokenList.weth).approve(report.poolProxy, 1e18);
    bytes[] memory calls = new bytes[](2);
    calls[0] = abi.encodeWithSelector(IPool.supply.selector, tokenList.weth, 1e18, supplier, 0);
    // excluded for more fair comparison with the pure supply. Might change in a future version :)
    // calls[1] = abi.encodeWithSelector(IPool.setUserUseReserveAsCollateral.selector, asset, true);
    calls[1] = abi.encodeWithSelector(IPool.borrow.selector, tokenList.usdx, 100e6, 2, 0, supplier);
    Multicall(address(contracts.poolProxy)).multicall(calls);
    vm.snapshotGasLastCall(
      'Pool.OperationsComposition',
      'supplyAndBorrow: first supply->collateralEnabled, first borrow'
    );
  }

  function test_repayAndWithdraw() external {
    _supplyOnReserve(supplier, 100 ether, tokenList.weth);
    uint256 amountToBorrow = 100e6;
    vm.startPrank(supplier);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, supplier);

    _skip(100);

    deal(tokenList.usdx, supplier, amountToBorrow * 2);
    IERC20(tokenList.usdx).approve(report.poolProxy, amountToBorrow * 2);
    bytes[] memory calls = new bytes[](2);
    calls[0] = abi.encodeWithSelector(
      IPool.repay.selector,
      tokenList.usdx,
      type(uint256).max,
      2,
      supplier
    );
    calls[1] = abi.encodeWithSelector(
      IPool.withdraw.selector,
      tokenList.weth,
      type(uint256).max,
      supplier
    );
    Multicall(address(contracts.poolProxy)).multicall(calls);
    vm.snapshotGasLastCall(
      'Pool.OperationsComposition',
      'repayAndWithdraw: borrow disabled, collateral disabled'
    );
  }

  function test_batchLiquidation() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (((price * 1e6) / 1e8) * 90) / 100, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 1 ether, tokenList.weth);
    _supplyOnReserve(supplier, (((price * 1e6) / 1e8) * 90) / 100, tokenList.usdx);
    _borrowArbitraryAmount(supplier, 1 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 4 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    bytes[] memory calls = new bytes[](2);
    calls[0] = abi.encodeWithSelector(
      IPool.liquidationCall.selector,
      tokenList.usdx,
      tokenList.weth,
      borrower,
      type(uint256).max,
      false
    );
    calls[1] = abi.encodeWithSelector(
      IPool.liquidationCall.selector,
      tokenList.usdx,
      tokenList.weth,
      supplier,
      type(uint256).max,
      false
    );
    Multicall(address(contracts.poolProxy)).multicall(calls);
    vm.snapshotGasLastCall('Pool.OperationsComposition', 'batchLiquidate: liquidate 2 users');
  }
}
