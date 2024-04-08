// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

contract AugustusRegistryMock {
  function isValidAugustus(address input) external pure returns (bool) {
    if (input == address(0)) {
      return false;
    }
    return true;
  }
}
