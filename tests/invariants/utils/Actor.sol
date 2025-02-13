// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

/// @notice Proxy contract for invariant suite actors to avoid aTester calling contracts
contract Actor {
  /// @notice list of tokens to approve
  address[] internal tokens;
  /// @notice list of contracts to approve tokens to
  address[] internal contracts;

  constructor(address[] memory _tokens, address[] memory _contracts) payable {
    tokens = _tokens;
    contracts = _contracts;
    for (uint256 i = 0; i < tokens.length; i++) {
      for (uint256 j = 0; j < contracts.length; j++) {
        IERC20(tokens[i]).approve(contracts[j], type(uint256).max);
      }
    }
  }

  /// @notice Helper function to proxy a call to a target contract, used to avoid Tester calling contracts
  function proxy(
    address _target,
    bytes memory _calldata
  ) public returns (bool success, bytes memory returnData) {
    (success, returnData) = address(_target).call(_calldata);

    handleAssertionError(success, returnData);
  }

  /// @notice Helper function to proxy a call and value to a target contract, used to avoid Tester calling contracts
  function proxy(
    address _target,
    bytes memory _calldata,
    uint256 value
  ) public returns (bool success, bytes memory returnData) {
    (success, returnData) = address(_target).call{value: value}(_calldata);

    handleAssertionError(success, returnData);
  }

  /// @notice Checks if a call failed due to an assertion error and propagates the error if found.
  /// @param success Indicates whether the call was successful.
  /// @param returnData The data returned from the call.
  function handleAssertionError(bool success, bytes memory returnData) internal pure {
    if (!success && returnData.length == 36) {
      bytes4 selector;
      uint256 code;
      assembly {
        selector := mload(add(returnData, 0x20))
        code := mload(add(returnData, 0x24))
      }

      if (selector == bytes4(0x4e487b71) && code == 1) {
        assert(false);
      }
    }
  }

  receive() external payable {}
}
