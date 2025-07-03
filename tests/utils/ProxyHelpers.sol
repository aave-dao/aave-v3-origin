// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/Vm.sol';

library ProxyHelpers {
  function getInitializableAdminUpgradeabilityProxyAdmin(
    Vm vm,
    address proxy
  ) internal view returns (address) {
    address slot = address(
      uint160(
        uint256(vm.load(proxy, 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103))
      )
    );
    return slot;
  }

  function getInitializableAdminUpgradeabilityProxyImplementation(
    Vm vm,
    address proxy
  ) internal view returns (address) {
    address slot = address(
      uint160(
        uint256(vm.load(proxy, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc))
      )
    );
    return slot;
  }

  /**
   * @dev the prediction only depends on the address of the proxy.
   * The admin is always the first and only contract deployed by the proxy.
   */
  function getOzV5ProxyAdminAddress(address proxy) internal pure returns (address) {
    return
      address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                bytes1(0xd6), // RLP prefix for a list with total length 22
                bytes1(0x94), // RLP prefix for an address (20 bytes)
                proxy, // 20-byte address
                uint8(1) // 1-byte nonce
              )
            )
          )
        )
      );
  }
}
