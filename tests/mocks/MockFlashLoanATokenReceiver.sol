// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPoolAddressesProvider} from '../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {FlashLoanSimpleReceiverBase} from '../../src/contracts/mocks/flashloan/MockSimpleFlashLoanReceiver.sol';

/// @dev Helper contract to test donation attacks not possible in the context of a flash loan
contract MockFlashLoanATokenReceiver is FlashLoanSimpleReceiverBase {
  address public immutable ATOKEN;

  constructor(
    IPoolAddressesProvider provider,
    address aToken
  ) FlashLoanSimpleReceiverBase(provider) {
    ATOKEN = aToken;
  }

  function executeOperation(
    address asset,
    uint256 amount,
    uint256, // premium
    address, // initiator
    bytes memory // params
  ) public override returns (bool) {
    //check the contract has the specified balance
    require(amount <= IERC20(asset).balanceOf(address(this)), 'Invalid balance for the contract');

    IERC20(asset).transfer(ATOKEN, amount);

    // This should revert with an arithmetic underflow
    IPool(POOL).withdraw(asset, amount, address(this));
    revert('MockFlashLoanTransferReceiver: FlashLoanSimple did not revert at withdraw');
  }

  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory, // premiums
    address, // initiator
    bytes memory // params
  ) public returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      require(
        amounts[i] <= IERC20(assets[i]).balanceOf(address(this)),
        'Invalid balance for the contract'
      );

      IERC20(assets[i]).transfer(ATOKEN, amounts[i]);

      // This should revert with an arithmetic underflow
      IPool(POOL).withdraw(assets[i], amounts[i], address(this));
    }
    revert('MockFlashLoanTransferReceiver: FlashLoanSimple did not revert at withdraw');
  }
}
