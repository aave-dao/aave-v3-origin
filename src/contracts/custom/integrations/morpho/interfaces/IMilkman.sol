// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

interface IMilkman {
  event SwapRequested(address indexed orderContract, address indexed orderCreator, uint256 amountIn, address fromToken, address toToken, address to, address priceChecker, bytes priceCheckerData);
  event SwapCancelled(address indexed orderContract, address indexed orderCreator);

  function requestSwapExactTokensForTokens(uint256 amountIn, IERC20 fromToken, IERC20 toToken, address to, address priceChecker, bytes calldata priceCheckerData) external;
  function cancelSwap(address orderContract, uint256 amountIn, IERC20 fromToken, IERC20 toToken, address to, address priceChecker, bytes calldata priceCheckerData) external;
  function domainSeparator() external view returns (bytes32);
  function computeOrderContract(address orderCreator, uint256 amountIn, IERC20 fromToken, IERC20 toToken, address to, address priceChecker, bytes calldata priceCheckerData) external view returns (address);
}
