// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Pool} from '../protocol/pool/Pool.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IReserveInterestRateStrategy} from '../interfaces/IReserveInterestRateStrategy.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';

/**
 * @title Aave Pool Instance
 * @author BGD Labs
 * @notice Instance of the Pool for the Aave protocol
 */
contract PoolInstance is Pool {
  uint256 public constant POOL_REVISION = 9;

  constructor(
    IPoolAddressesProvider provider,
    IReserveInterestRateStrategy interestRateStrategy_
  ) Pool(provider, interestRateStrategy_) {}

  /**
   * @notice Initializes the Pool.
   * @dev Function is invoked by the proxy contract when the Pool contract is added to the
   * PoolAddressesProvider of the market.
   * @dev The passed PoolAddressesProvider is validated against the POOL.ADDRESSES_PROVIDER, to ensure the upgrade is done with correct intention.
   * @param provider The address of the PoolAddressesProvider
   */
  function initialize(IPoolAddressesProvider provider) external virtual override initializer {
    require(provider == ADDRESSES_PROVIDER, Errors.InvalidAddressesProvider());
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return POOL_REVISION;
  }
}
