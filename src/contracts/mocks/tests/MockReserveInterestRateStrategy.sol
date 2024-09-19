// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DefaultReserveInterestRateStrategyV2} from '../../misc/DefaultReserveInterestRateStrategyV2.sol';
import {DataTypes} from '../../protocol/libraries/types/DataTypes.sol';

contract MockReserveInterestRateStrategy is DefaultReserveInterestRateStrategyV2 {
  uint256 internal _liquidityRate;
  uint256 internal _variableBorrowRate;

  constructor(address provider) DefaultReserveInterestRateStrategyV2(provider) {}

  function setLiquidityRate(uint256 liquidityRate) public {
    _liquidityRate = liquidityRate;
  }

  function setVariableBorrowRate(uint256 variableBorrowRate) public {
    _variableBorrowRate = variableBorrowRate;
  }

  function calculateInterestRates(
    DataTypes.CalculateInterestRatesParams memory
  ) public view override returns (uint256 liquidityRate, uint256 variableBorrowRate) {
    return (_liquidityRate, _variableBorrowRate);
  }
}
