// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IATokenHandler {
  function transfer(uint256 amount, uint8 i, uint8 j) external;
  function transferFrom(uint256 amount, uint8 i, uint8 j, uint256 u) external;
}
