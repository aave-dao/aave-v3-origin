// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Libraries
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';

interface IFlashLoanHandler {
  function flashLoan(
    uint256[3] memory amounts,
    DataTypes.InterestRateMode[3] memory interestRateModes,
    uint256 amountToRepay,
    uint8 j
  ) external;
  function flashLoanSimple(uint256 amount, uint256 amountToRepay, uint8 i) external;
}
