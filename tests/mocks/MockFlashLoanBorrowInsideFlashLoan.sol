// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPoolAddressesProvider} from '../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {FlashLoanSimpleReceiverBase} from '../../src/contracts/misc/flashloan/base/FlashLoanSimpleReceiverBase.sol';
import {MintableERC20} from '../../src/contracts/mocks/tokens/MintableERC20.sol';

contract MockFlashLoanBorrowInsideFlashLoan is FlashLoanSimpleReceiverBase {
  constructor(IPoolAddressesProvider provider) FlashLoanSimpleReceiverBase(provider) {}

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address /* initiator */,
    bytes calldata /* params */
  ) external returns (bool) {
    IERC20(asset).approve(msg.sender, amount * 2 + premium);

    uint256 underlyingBalance = IPool(msg.sender).getVirtualUnderlyingBalance(asset);

    IPool(msg.sender).borrow({
      asset: asset,
      amount: (underlyingBalance * 9) / 10,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: address(this)
    });

    return true;
  }

  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address /* initiator */,
    bytes calldata /* params */
  ) public returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      IERC20(assets[i]).approve(msg.sender, amounts[i] * 2 + premiums[i]);

      uint256 underlyingBalance = IPool(msg.sender).getVirtualUnderlyingBalance(assets[i]);

      IPool(msg.sender).borrow({
        asset: assets[i],
        amount: (underlyingBalance * 9) / 10,
        interestRateMode: 2,
        referralCode: 0,
        onBehalfOf: address(this)
      });
    }

    return true;
  }
}
