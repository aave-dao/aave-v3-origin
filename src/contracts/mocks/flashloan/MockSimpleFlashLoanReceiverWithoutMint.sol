// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {FlashLoanSimpleReceiverBase} from '../../misc/flashloan/base/FlashLoanSimpleReceiverBase.sol';

contract MockSimpleFlashLoanReceiverWithoutMint is FlashLoanSimpleReceiverBase {
  constructor(IPoolAddressesProvider provider) FlashLoanSimpleReceiverBase(provider) {}

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address, // initiator
    bytes memory // params
  ) public override returns (bool) {
    IERC20(asset).approve(address(POOL), amount + premium);

    return true;
  }
}
