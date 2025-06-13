// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorInstance} from '../../../contracts/instances/PoolConfiguratorInstance.sol';
import {IPoolAddressesProvider} from '../../../contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../../contracts/interfaces/IPool.sol';
import {AaveOracle} from '../../../contracts/misc/AaveOracle.sol';

contract AaveV3PoolConfigProcedure {
  function _deployPoolConfigurator() internal returns (address) {
    PoolConfiguratorInstance poolConfiguratorImplementation = new PoolConfiguratorInstance();

    return address(poolConfiguratorImplementation);
  }
}
