// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ReentrancyGuardTransient} from 'openzeppelin-contracts/contracts/utils/ReentrancyGuardTransient.sol';

import {L2Encoder} from '../../../src/contracts/helpers/L2Encoder.sol';
import {IL2Pool} from '../../../src/contracts/interfaces/IL2Pool.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {LiquidationCallbackToken} from './Pool.LiquidationReentrancy.t.sol';

/// @dev The compact L2Pool entry points call the guarded Pool functions, so they are blocked while
/// another Pool action holds the lock.
contract L2PoolReentrancyTests is TestnetProcedures {
  IPool internal pool;
  L2Encoder internal l2Encoder;
  LiquidationCallbackToken internal callbackToken;

  function setUp() public {
    initL2TestEnvironment();
    pool = IPool(report.poolProxy);
    l2Encoder = L2Encoder(report.l2Encoder);

    vm.etch(tokenList.wbtc, address(new LiquidationCallbackToken(pool)).code);
    callbackToken = LiquidationCallbackToken(tokenList.wbtc);

    vm.prank(poolAdmin);
    TestnetERC20(tokenList.wbtc).mint(address(callbackToken), 1);
    vm.prank(address(callbackToken));
    TestnetERC20(tokenList.wbtc).approve(address(pool), 1);
  }

  function test_l2EntryPointsBlockedWhileEntered() public {
    bytes[] memory calls = _getL2CallData();
    for (uint256 i; i < calls.length; ++i) {
      uint256 snapshot = vm.snapshotState();

      callbackToken.armCallback(calls[i], address(callbackToken));
      callbackToken.callPool(
        abi.encodeCall(IPool.supply, (tokenList.wbtc, 1, address(callbackToken), 0))
      );

      (bool callbackSucceeded, bytes memory callbackResult) = callbackToken.getCallbackResult();
      assertFalse(callbackSucceeded);
      assertEq(
        callbackResult,
        abi.encodeWithSelector(ReentrancyGuardTransient.ReentrancyGuardReentrantCall.selector)
      );
      vm.revertToState(snapshot);
    }
  }

  function _getL2CallData() internal view returns (bytes[] memory calls) {
    calls = new bytes[](9);
    uint256 deadline = vm.getBlockTimestamp() + 1 days;
    bytes32 args1;
    bytes32 args2;
    bytes32 args3;

    calls[0] = abi.encodeCall(IL2Pool.supply, (l2Encoder.encodeSupplyParams(tokenList.weth, 1, 0)));
    (args1, args2, args3) = l2Encoder.encodeSupplyWithPermitParams({
      asset: tokenList.weth,
      amount: 1,
      referralCode: 0,
      deadline: deadline,
      permitV: 0,
      permitR: bytes32(0),
      permitS: bytes32(0)
    });
    calls[1] = abi.encodeCall(IL2Pool.supplyWithPermit, (args1, args2, args3));
    calls[2] = abi.encodeCall(
      IL2Pool.withdraw,
      (l2Encoder.encodeWithdrawParams(tokenList.weth, 1))
    );
    calls[3] = abi.encodeCall(
      IL2Pool.borrow,
      (
        l2Encoder.encodeBorrowParams({
          asset: tokenList.weth,
          amount: 1,
          interestRateMode: 2,
          referralCode: 0
        })
      )
    );
    calls[4] = abi.encodeCall(
      IL2Pool.repay,
      (l2Encoder.encodeRepayParams({asset: tokenList.weth, amount: 1, interestRateMode: 2}))
    );
    (args1, args2, args3) = l2Encoder.encodeRepayWithPermitParams({
      asset: tokenList.weth,
      amount: 1,
      interestRateMode: 2,
      deadline: deadline,
      permitV: 0,
      permitR: bytes32(0),
      permitS: bytes32(0)
    });
    calls[5] = abi.encodeCall(IL2Pool.repayWithPermit, (args1, args2, args3));
    calls[6] = abi.encodeCall(
      IL2Pool.repayWithATokens,
      (
        l2Encoder.encodeRepayWithATokensParams({
          asset: tokenList.weth,
          amount: 1,
          interestRateMode: 2
        })
      )
    );
    calls[7] = abi.encodeCall(
      IL2Pool.setUserUseReserveAsCollateral,
      (l2Encoder.encodeSetUserUseReserveAsCollateral(tokenList.weth, false))
    );
    (args1, args2) = l2Encoder.encodeLiquidationCall({
      collateralAsset: tokenList.weth,
      debtAsset: tokenList.usdx,
      user: alice,
      debtToCover: 1,
      receiveAToken: false
    });
    calls[8] = abi.encodeCall(IL2Pool.liquidationCall, (args1, args2));
  }
}
