// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IReserveInterestRateStrategy} from '../../interfaces/IReserveInterestRateStrategy.sol';
import {L2PoolInstance, PoolInstance} from '../../instances/L2PoolInstance.sol';
import {VersionedInitializable} from '../../misc/aave-upgradeability/VersionedInitializable.sol';

contract MockL2Pool is L2PoolInstance {
  function getRevision()
    internal
    pure
    override(PoolInstance, VersionedInitializable)
    returns (uint256)
  {
    return super.getRevision() + 1;
  }

  constructor(
    IPoolAddressesProvider provider,
    IReserveInterestRateStrategy interestRateStrategy
  ) L2PoolInstance(provider, interestRateStrategy) {}
}
