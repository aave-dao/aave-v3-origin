// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBorrowingHandler {
  function borrow(uint256 amount, uint8 i, uint8 j) external;
  function repay(uint256 amount, uint8 i, uint8 j) external;
  function repayWithATokens(uint256 amount, uint8 i) external;
  function setUserUseReserveAsCollateral(bool useAsCollateral, uint8 i) external;
}
