// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorInstance} from 'aave-v3-core/instances/PoolConfiguratorInstance.sol';
import {IPoolAddressesProvider} from 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {AaveOracle} from 'aave-v3-core/contracts/misc/AaveOracle.sol';

contract AaveV3PoolConfigProcedure {
  function _deployPoolConfigurator(address poolAddressesProvider) internal returns (address) {
    PoolConfiguratorInstance poolConfiguratorImplementation = new PoolConfiguratorInstance();
    poolConfiguratorImplementation.initialize(IPoolAddressesProvider(poolAddressesProvider));

    return address(poolConfiguratorImplementation);
  }
}
