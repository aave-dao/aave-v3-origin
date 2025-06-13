// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IReserveInterestRateStrategy} from '../../interfaces/IReserveInterestRateStrategy.sol';

import {PoolInstance} from '../../instances/PoolInstance.sol';

contract MockPoolInherited is PoolInstance {
  uint16 internal _maxNumberOfReserves = 128;

  function getRevision() internal pure override returns (uint256) {
    return super.getRevision() + 1;
  }

  constructor(
    IPoolAddressesProvider provider,
    IReserveInterestRateStrategy interestRateStrategy
  ) PoolInstance(provider, interestRateStrategy) {}

  function setMaxNumberOfReserves(uint16 newMaxNumberOfReserves) public {
    _maxNumberOfReserves = newMaxNumberOfReserves;
  }

  function MAX_NUMBER_RESERVES() public view override returns (uint16) {
    return _maxNumberOfReserves;
  }

  function dropReserve(address asset) external override {
    _reservesList[_reserves[asset].id] = address(0);
    delete _reserves[asset];
  }
}
