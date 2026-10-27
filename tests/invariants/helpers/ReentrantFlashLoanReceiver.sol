// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {ReentrancyGuardTransient} from 'openzeppelin-contracts/contracts/utils/ReentrancyGuardTransient.sol';
import {IPool} from 'src/contracts/interfaces/IPool.sol';

/// @notice Flash-loan receiver that drives Pool actions from inside a callback.
/// @dev Steps run low level so the outer flashloan can still settle, and only a revert carrying
/// the reentrancy guard selector counts as a failure. Anything else is a legitimate state outcome.
/// The receiver must hold no aTokens once a callback returns, the suite sums aToken balances over
/// actors and the treasury only.
contract ReentrantFlashLoanReceiver {
  uint256 internal constant PROBE_AMOUNT = 1e3;

  IPool internal immutable pool;
  uint8 internal reentryAction;
  address public aTokenSource;
  bool public callbackEntered;
  bool public guardBlockedCall;
  bool public stateChanged;
  uint256 public callbackCount;

  constructor(IPool pool_) {
    pool = pool_;
  }

  function configure(uint8 action) external {
    reentryAction = action;
    callbackEntered = false;
    guardBlockedCall = false;
    stateChanged = false;
  }

  function setATokenSource(address source) external {
    aTokenSource = source;
  }

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address,
    bytes calldata
  ) external returns (bool) {
    _attemptReentry(asset);
    callbackEntered = true;
    ++callbackCount;
    IERC20(asset).approve(msg.sender, amount + premium);
    return true;
  }

  function _attemptReentry(address asset) internal {
    if (reentryAction == 0) {
      _supplyThenWithdraw(asset);
    } else {
      _moveATokens(asset);
    }
  }

  function _supplyThenWithdraw(address asset) internal {
    IERC20(asset).approve(address(pool), PROBE_AMOUNT);

    if (
      !_call(address(pool), abi.encodeCall(IPool.supply, (asset, PROBE_AMOUNT, address(this), 0)))
    ) {
      return;
    }
    stateChanged = true;

    _call(address(pool), abi.encodeCall(IPool.withdraw, (asset, type(uint256).max, address(this))));
    _returnResidual(pool.getReserveAToken(asset));
  }

  function _moveATokens(address asset) internal {
    address aToken = pool.getReserveAToken(asset);
    uint256 available = IERC20(aToken).balanceOf(aTokenSource);
    uint256 amount = available < PROBE_AMOUNT ? available : PROBE_AMOUNT;
    if (amount == 0) return _supplyThenWithdraw(asset);

    if (
      !_call(aToken, abi.encodeCall(IERC20.transferFrom, (aTokenSource, address(this), amount)))
    ) {
      return;
    }
    stateChanged = true;

    _returnResidual(aToken);
  }

  function _returnResidual(address aToken) internal {
    uint256 residual = IERC20(aToken).balanceOf(address(this));
    if (residual != 0) _call(aToken, abi.encodeCall(IERC20.transfer, (aTokenSource, residual)));
    require(IERC20(aToken).balanceOf(address(this)) == 0, 'receiver stranded aTokens');
  }

  function _call(address target, bytes memory data) internal returns (bool) {
    (bool success, bytes memory result) = target.call(data);

    if (
      !success &&
      result.length == 4 &&
      bytes4(result) == ReentrancyGuardTransient.ReentrancyGuardReentrantCall.selector
    ) {
      guardBlockedCall = true;
    }

    return success;
  }
}
