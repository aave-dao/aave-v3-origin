// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {MintableERC20} from '../tokens/MintableERC20.sol';

contract MockParaSwapAugustus {
  bool _expectingSwap;
  address _expectedFromToken;
  address _expectedToToken;

  uint256 _expectedFromAmountMin;
  uint256 _expectedFromAmountMax;
  uint256 _receivedAmount;

  uint256 _fromAmount;
  uint256 _expectedToAmountMax;
  uint256 _expectedToAmountMin;

  function expectSwap(
    address fromToken,
    address toToken,
    uint256 fromAmountMin,
    uint256 fromAmountMax,
    uint256 receivedAmount
  ) external {
    _expectingSwap = true;
    _expectedFromToken = fromToken;
    _expectedToToken = toToken;
    _expectedFromAmountMin = fromAmountMin;
    _expectedFromAmountMax = fromAmountMax;
    _receivedAmount = receivedAmount;
  }

  function expectBuy(
    address fromToken,
    address toToken,
    uint256 fromAmount,
    uint256 toAmountMin,
    uint256 toAmountMax
  ) external {
    _expectingSwap = true;
    _expectedFromToken = fromToken;
    _expectedToToken = toToken;
    _fromAmount = fromAmount;
    _expectedToAmountMin = toAmountMin;
    _expectedToAmountMax = toAmountMax;
  }

  function swap(
    address fromToken,
    address toToken,
    uint256 fromAmount,
    uint256 toAmount
  ) external returns (uint256) {
    require(_expectingSwap, 'Not expecting swap');
    require(fromToken == _expectedFromToken, 'Unexpected from token');
    require(toToken == _expectedToToken, 'Unexpected to token');
    require(
      fromAmount >= _expectedFromAmountMin && fromAmount <= _expectedFromAmountMax,
      'From amount out of range'
    );
    require(_receivedAmount >= toAmount, 'Received amount of tokens are less than expected');
    _transferFrom(fromToken, msg.sender, address(this), fromAmount);
    MintableERC20(toToken).mint(_receivedAmount);
    IERC20(toToken).transfer(msg.sender, _receivedAmount);
    _expectingSwap = false;
    return _receivedAmount;
  }

  function buy(
    address fromToken,
    address toToken,
    uint256 fromAmount,
    uint256 toAmount
  ) external returns (uint256) {
    require(_expectingSwap, 'Not expecting swap');
    require(fromToken == _expectedFromToken, 'Unexpected from token');
    require(toToken == _expectedToToken, 'Unexpected to token');
    require(
      toAmount >= _expectedToAmountMin && toAmount <= _expectedToAmountMax,
      'To amount out of range'
    );
    require(_fromAmount <= fromAmount, 'From amount of tokens are higher than expected');
    _transferFrom(fromToken, msg.sender, address(this), _fromAmount);
    MintableERC20(toToken).mint(msg.sender, toAmount);
    _expectingSwap = false;
    return fromAmount;
  }

  function _transferFrom(address token, address from, address to, uint256 amount) internal {
    IERC20(token).transferFrom(from, to, amount);
  }
}
