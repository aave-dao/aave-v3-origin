// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {FlashLoanReceiverBase} from '../../misc/flashloan/base/FlashLoanReceiverBase.sol';

contract MockFlashLoanReceiverWithoutMint is FlashLoanReceiverBase {
  constructor(IPoolAddressesProvider provider) FlashLoanReceiverBase(provider) {}

  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address, // initiator
    bytes memory // params
  ) public override returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      IERC20(assets[i]).approve(address(POOL), amounts[i] + premiums[i]);
    }
    return true;
  }
}
