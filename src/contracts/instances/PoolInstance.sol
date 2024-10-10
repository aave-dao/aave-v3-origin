// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Pool} from '../protocol/pool/Pool.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';

contract PoolInstance is Pool {
  uint256 public constant POOL_REVISION = 6;

  constructor(IPoolAddressesProvider provider) Pool(provider) {}

  /**
   * @notice Initializes the Pool.
   * @dev Function is invoked by the proxy contract when the Pool contract is added to the
   * PoolAddressesProvider of the market.
   * @dev Caching the address of the PoolAddressesProvider in order to reduce gas consumption on subsequent operations
   * @param provider The address of the PoolAddressesProvider
   */
  function initialize(IPoolAddressesProvider provider) external virtual override initializer {
    require(provider == ADDRESSES_PROVIDER, Errors.INVALID_ADDRESSES_PROVIDER);
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return POOL_REVISION;
  }
}
