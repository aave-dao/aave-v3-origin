// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoolConfiguratorInstance} from '../../../contracts/instances/PoolConfiguratorInstance.sol';

contract AaveV3PoolConfigProcedure {
  function _deployPoolConfigurator() internal returns (address) {
    PoolConfiguratorInstance poolConfiguratorImplementation = new PoolConfiguratorInstance();

    return address(poolConfiguratorImplementation);
  }
}
