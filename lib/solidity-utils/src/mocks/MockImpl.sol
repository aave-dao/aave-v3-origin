// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from '../contracts/transparent-proxy/Initializable.sol';

contract MockImpl is Initializable {
  uint256 public _foo;

  function initialize(uint256 foo) external initializer {
    _foo = foo;
  }

  function getFoo() external view returns (uint256) {
    return _foo;
  }
}
