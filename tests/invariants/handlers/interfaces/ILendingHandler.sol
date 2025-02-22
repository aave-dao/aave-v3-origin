// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILendingHandler {
  function supply(uint256 amount, uint8 i, uint8 j) external;
  function withdraw(uint256 amount, uint8 i, uint8 j) external;
}
