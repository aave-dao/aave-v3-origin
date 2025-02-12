// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Create2Factory {
  // Fallback function to handle the creation of a new contract
  fallback() external payable {
    // Copy calldata into memory, excluding the first 32 bytes
    assembly {
      calldatacopy(0, 32, sub(calldatasize(), 32))

      // Create the new contract with CREATE2
      let result := create2(callvalue(), 0, sub(calldatasize(), 32), calldataload(0))

      // Check if contract creation was successful
      if iszero(result) {
        revert(0, 0)
      }

      // Return the address of the newly created contract
      mstore(0, result)
      return(12, 20)
    }
  }
}

contract FactoryDeployer {
  function deployFactory() public returns (address child) {
    bytes
      memory bytecode = hex'604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3';
    assembly {
      child := create(0, add(bytecode, 0x20), mload(bytecode))
    }
  }
}
