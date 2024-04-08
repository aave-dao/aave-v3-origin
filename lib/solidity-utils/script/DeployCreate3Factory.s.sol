// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {TransparentProxyFactory} from '../src/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {Create3Factory} from "../src/contracts/create3/Create3Factory.sol";

contract DeployCreate3Factory is Script {
  bytes32 public constant CREATE3_FACTORY_SALT = keccak256(bytes('Create3 Factory'));
  function run() external {
    vm.startBroadcast();
    new Create3Factory{salt: CREATE3_FACTORY_SALT}();
    vm.stopBroadcast();
  }
}
