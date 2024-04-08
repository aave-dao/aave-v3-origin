// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/StdJson.sol';
import 'forge-std/Vm.sol';
import {IMetadataReporter} from '../../interfaces/IMetadataReporter.sol';
import '../../interfaces/IMarketReportTypes.sol';
import 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';

contract DeployUtils {
  using stdJson for string;

  Vm private constant vm = Vm(address(bytes20(uint160(uint256(keccak256('hevm cheat code'))))));

  function _deployFromArtifacts(string memory contractPath) internal returns (address deployment) {
    bytes memory bytecode = abi.encodePacked(vm.getCode(contractPath));
    assembly {
      deployment := create(0, add(bytecode, 0x20), mload(bytecode))
    }

    return deployment;
  }

  function _deployFromArtifactsWithBroadcast(
    string memory contractPath
  ) internal returns (address deployment) {
    bytes memory bytecode = abi.encodePacked(vm.getCode(contractPath));
    vm.broadcast();
    assembly {
      deployment := create(0, add(bytecode, 0x20), mload(bytecode))
    }

    return deployment;
  }

  function _deployFromArtifactsWithBroadcast(
    string memory contractPath,
    bytes memory args
  ) internal returns (address deployment) {
    bytes memory bytecode = abi.encodePacked(vm.getCode(contractPath), args);

    vm.broadcast();
    assembly {
      deployment := create(0, add(bytecode, 0x20), mload(bytecode))
    }

    return deployment;
  }

  function _deployFromArtifacts(
    string memory contractPath,
    bytes memory args
  ) internal returns (address deployment) {
    bytes memory bytecode = abi.encodePacked(vm.getCode(contractPath), args);
    assembly {
      deployment := create(0, add(bytecode, 0x20), mload(bytecode))
    }

    return deployment;
  }

  function getCreate2Address(
    string memory contractPath,
    bytes memory args,
    bytes32 _salt
  ) public view returns (address) {
    bytes memory bytecode = abi.encodePacked(vm.getCode(contractPath), args);

    bytes32 hash = keccak256(
      abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
    );

    return address(uint160(uint(hash)));
  }
}
