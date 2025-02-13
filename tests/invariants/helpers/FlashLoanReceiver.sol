// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Test Contracts
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {TestnetERC20} from 'src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {PropertiesAsserts} from '../utils/PropertiesAsserts.sol';

contract MockFlashLoanReceiver is PropertiesAsserts {
  constructor() {}

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
  ) external returns (bool) {
    (uint256 amountToRepay, address sender) = abi.decode(params, (uint256, address));

    assertEq(initiator, sender, 'onFlashLoan: wrong initiator');
    _setAmountBack(asset, amountToRepay, amount + premium);

    return true;
  }

  function _setAmountBack(address _token, uint256 _amountToRepay, uint256 _amountWithFee) internal {
    IERC20(_token).approve(address(msg.sender), _amountWithFee);
    if (_amountToRepay > _amountWithFee) {
      TestnetERC20(_token).mint(address(this), _amountToRepay - _amountWithFee);
    } else if (_amountToRepay < _amountWithFee) {
      TestnetERC20(_token).transfer(address(0), _amountWithFee - _amountToRepay);
    }
  }
}
