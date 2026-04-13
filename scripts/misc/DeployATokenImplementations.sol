// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ATokenInstance} from '../../src/contracts/instances/ATokenInstance.sol';
import {RwaATokenInstance} from '../../src/contracts/instances/RwaATokenInstance.sol';
import {AaveV3HorizonEthereum} from '../../tests/horizon/utils/AaveV3HorizonEthereum.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {Script} from 'forge-std/Script.sol';

contract DeployATokenInstance is Script {
  IPool public constant POOL = IPool(AaveV3HorizonEthereum.POOL);

  function run() public returns (address) {
    vm.startBroadcast();
    ATokenInstance aToken = new ATokenInstance(POOL);
    vm.stopBroadcast();
    return address(aToken);
  }
}

contract DeployRwaATokenInstance is Script {
  IPool public constant POOL = IPool(AaveV3HorizonEthereum.POOL);

  function run() public returns (address) {
    vm.startBroadcast();
    RwaATokenInstance rwaAToken = new RwaATokenInstance(POOL);
    vm.stopBroadcast();
    return address(rwaAToken);
  }
}
