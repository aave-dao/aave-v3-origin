// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPriceChecker {
  function checkPrice(uint256 amountIn, address fromToken, address toToken, uint256 feeAmount, uint256 minOut, bytes calldata data) external view returns (bool);
}
