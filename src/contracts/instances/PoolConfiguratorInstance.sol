// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfigurator, IPoolAddressesProvider, IPool, VersionedInitializable} from '../protocol/pool/PoolConfigurator.sol';

/**
 * @title Aave PoolConfigurator Instance
 * @author BGD Labs
 * @notice Instance of the PoolConfigurator of the Aave protocol
 */
contract PoolConfiguratorInstance is PoolConfigurator {
  uint256 public constant CONFIGURATOR_REVISION = 6;

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure virtual override returns (uint256) {
    return CONFIGURATOR_REVISION;
  }

  function initialize(IPoolAddressesProvider provider) public virtual override initializer {
    _addressesProvider = provider;
    _pool = IPool(_addressesProvider.getPool());
  }
}
