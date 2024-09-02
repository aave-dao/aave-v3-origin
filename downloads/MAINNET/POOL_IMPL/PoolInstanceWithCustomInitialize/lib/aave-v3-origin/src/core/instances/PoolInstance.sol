// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Pool} from '../contracts/protocol/pool/Pool.sol';
import {IPoolAddressesProvider} from '../contracts/interfaces/IPoolAddressesProvider.sol';
import {Errors} from '../contracts/protocol/libraries/helpers/Errors.sol';

contract PoolInstance is Pool {
  uint256 public constant POOL_REVISION = 4;

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
    _maxStableRateBorrowSizePercent = 0.25e4;
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return POOL_REVISION;
  }
}
