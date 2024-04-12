// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Vm.sol';

abstract contract FfiUtils {
  Vm private constant vm = Vm(address(bytes20(uint160(uint256(keccak256('hevm cheat code'))))));

  function _getLatestLibraryAddress() internal returns (address) {
    string memory getLibraryAddress = "sed -nr 's/FOUNDRY_LIBRARIES.*:(.*)/\\1/p' .env";
    string[] memory getAddressCommand = new string[](3);

    getAddressCommand[0] = 'bash';
    getAddressCommand[1] = '-c';
    getAddressCommand[2] = string(
      abi.encodePacked(
        'response="$(',
        getLibraryAddress,
        ')";[ -z "$response" ] && cast abi-encode "response(address)" 0x0000000000000000000000000000000000000000 || cast abi-encode "response(address)" $response'
      )
    );

    bytes memory res2 = vm.ffi(getAddressCommand);
    address lastLib = abi.decode(res2, (address));
    return lastLib;
  }

  function _getSupplyLibraryAddress() internal returns (address) {
    string memory getLibraryAddress = "sed -nr 's/.*SupplyLogic:(.*)/\\1/p' .env";
    string[] memory getAddressCommand = new string[](3);

    getAddressCommand[0] = 'bash';
    getAddressCommand[1] = '-c';
    getAddressCommand[2] = string(
      abi.encodePacked(
        'response="$(',
        getLibraryAddress,
        ')"; [ -z "$response" ] && cast abi-encode "response(address)" 0x0000000000000000000000000000000000000000 || cast abi-encode "response(address)" $response'
      )
    );

    bytes memory res2 = vm.ffi(getAddressCommand);
    address lastLib = abi.decode(res2, (address));
    return lastLib;
  }

  function _deleteLibrariesPath() internal {
    // Keep sed OSX vs gnu sed compatibility
    string memory deleteCommand = "sed -i.bak -r '/FOUNDRY_LIBRARIES/d' .env && rm .env.bak";
    string[] memory delCommand = new string[](3);

    delCommand[0] = 'bash';
    delCommand[1] = '-c';
    delCommand[2] = string(abi.encodePacked('response="$(', deleteCommand, ')"; $response;'));
    vm.ffi(delCommand);
  }

  function _librariesPathExists() internal returns (bool) {
    string
      memory checkCommand = '[ -e .env ] && grep -q "FOUNDRY_LIBRARIES" .env && echo true || echo false';
    string[] memory command = new string[](3);

    command[0] = 'bash';
    command[1] = '-c';
    command[2] = string(
      abi.encodePacked(
        'response="$(',
        checkCommand,
        ')"; cast abi-encode "response(bool)" $response;'
      )
    );
    bytes memory res = vm.ffi(command);

    bool found = abi.decode(res, (bool));

    return found;
  }
}
