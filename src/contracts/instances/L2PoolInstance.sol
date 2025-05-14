// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {L2Pool} from '../protocol/pool/L2Pool.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IReserveInterestRateStrategy} from '../interfaces/IReserveInterestRateStrategy.sol';
import {PoolInstance} from './PoolInstance.sol';

/**
 * @title Aave L2Pool Instance
 * @author BGD Labs
 * @notice Instance of the L2Pool for the Aave protocol, intended to be used on rollups
 */
contract L2PoolInstance is L2Pool, PoolInstance {
  constructor(
    IPoolAddressesProvider provider,
    IReserveInterestRateStrategy interestRateStrategy
  ) PoolInstance(provider, interestRateStrategy) {}
}
