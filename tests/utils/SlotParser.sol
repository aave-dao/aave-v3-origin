// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import 'forge-std/Vm.sol';

library SlotParser {
  Vm private constant vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

  function loadAddressFromSlot(address target, bytes32 slot) external view returns (address) {
    return address(uint160(uint256(vm.load(target, slot))));
  }
}
