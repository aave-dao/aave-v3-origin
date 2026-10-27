// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IPoolAddressesProvider} from '../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {FlashLoanSimpleReceiverBase} from '../../src/contracts/misc/flashloan/base/FlashLoanSimpleReceiverBase.sol';

/// @dev Receiver that moves aTokens and takes a further flashloan from inside the callback,
/// the shape integrators use to unwind a position while a flashloan is outstanding.
contract MockFlashLoanATokenTransferReceiver is FlashLoanSimpleReceiverBase {
  address public aTokenSource;
  address public nestedAsset;
  uint256 public nestedAmount;
  uint256 public pulledBalance;
  uint256 public withdrawnAmount;
  bool public tookNestedFlashLoan;
  uint256 internal depth;

  constructor(IPoolAddressesProvider provider) FlashLoanSimpleReceiverBase(provider) {}

  function setATokenSource(address source) external {
    aTokenSource = source;
  }

  function setNestedFlashLoan(address asset, uint256 amount) external {
    nestedAsset = asset;
    nestedAmount = amount;
  }

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address,
    bytes memory
  ) public override returns (bool) {
    _run(asset);
    IERC20(asset).approve(address(POOL), amount + premium);
    return true;
  }

  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address,
    bytes memory
  ) public returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      _run(assets[i]);
      IERC20(assets[i]).approve(address(POOL), amounts[i] + premiums[i]);
    }
    return true;
  }

  function _run(address asset) internal {
    depth++;

    if (depth == 1 && nestedAsset != address(0)) {
      POOL.flashLoanSimple(address(this), nestedAsset, nestedAmount, '', 0);
      tookNestedFlashLoan = true;
    }

    if (depth == 1 && aTokenSource != address(0)) {
      address aToken = POOL.getReserveAToken(asset);
      uint256 amount = IERC20(aToken).balanceOf(aTokenSource) / 2;

      IERC20(aToken).transferFrom(aTokenSource, address(this), amount);
      pulledBalance = IERC20(aToken).balanceOf(address(this));
      withdrawnAmount = POOL.withdraw(asset, amount / 2, address(this));
    }

    depth--;
  }
}
