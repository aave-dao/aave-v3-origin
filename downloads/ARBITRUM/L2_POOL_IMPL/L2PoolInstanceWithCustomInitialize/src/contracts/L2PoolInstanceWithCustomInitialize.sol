// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {L2Pool, IPoolAddressesProvider} from '../../lib/aave-v3-origin/src/core/contracts/protocol/pool/L2Pool.sol';
import {PoolInstanceWithCustomInitialize} from './PoolInstanceWithCustomInitialize.sol';

/**
 * @notice L2Pool instance with custom initialize for existing pools
 */
contract L2PoolInstanceWithCustomInitialize is L2Pool, PoolInstanceWithCustomInitialize {
  constructor(IPoolAddressesProvider provider) PoolInstanceWithCustomInitialize(provider) {}
}
