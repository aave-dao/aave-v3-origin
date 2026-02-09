// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Test Contracts
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {TestnetERC20} from 'src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {PropertiesAsserts} from '../utils/PropertiesAsserts.sol';

contract MockFlashLoanReceiver is PropertiesAsserts {
  constructor() {}

  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address /* initiator */,
    bytes calldata /* params */
  ) external returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      if (premiums[i] > 0) {
        TestnetERC20(assets[i]).mint(address(this), premiums[i]);
      }

      IERC20(assets[i]).approve(msg.sender, amounts[i]);
    }

    return true;
  }

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address /* initiator */,
    bytes calldata /* params */
  ) external returns (bool) {
    if (premium > 0) {
      TestnetERC20(asset).mint(address(this), premium);
    }

    IERC20(asset).approve(msg.sender, amount);

    return true;
  }
}
