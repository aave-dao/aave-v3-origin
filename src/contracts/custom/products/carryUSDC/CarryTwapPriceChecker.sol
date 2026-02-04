// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IPriceChecker} from '../../integrations/morpho/interfaces/IPriceChecker.sol';
import {IChainlinkAggregatorV3} from '../../integrations/morpho/interfaces/IChainlinkAutomation.sol';
import {ILinearBlockTwapOracle} from './LinearBlockTwapOracle.sol';

/**
 * @title CarryTwapPriceChecker
 * @notice Price checker for Milkman/CoW Protocol swaps using TWAP validation
 */
contract CarryTwapPriceChecker is IPriceChecker, Ownable {
  ILinearBlockTwapOracle public immutable twapOracle;
  IChainlinkAggregatorV3 public immutable chainlinkJpyUsd;
  address public immutable usdc;
  address public immutable jpyToken;
  uint256 public maxDivergence;
  bool public isPaused;

  uint256 public constant PRECISE_UNIT = 1e18;
  uint256 public constant MAX_BPS = 10000;
  uint256 public constant USDC_DECIMALS = 6;
  uint256 public constant JPY_DECIMALS = 18;
  uint256 public constant PRICE_DECIMALS = 8;

  error InvalidAddress();
  error InvalidDivergence();

  constructor(address _twapOracle, address _chainlinkJpyUsd, address _usdc, address _jpyToken) Ownable(msg.sender) {
    if (_twapOracle == address(0) || _chainlinkJpyUsd == address(0) || _usdc == address(0) || _jpyToken == address(0)) revert InvalidAddress();
    twapOracle = ILinearBlockTwapOracle(_twapOracle);
    chainlinkJpyUsd = IChainlinkAggregatorV3(_chainlinkJpyUsd);
    usdc = _usdc;
    jpyToken = _jpyToken;
    maxDivergence = 1e16;
    isPaused = false;
  }

  function checkPrice(uint256 amountIn, address fromToken, address toToken, uint256 feeAmount, uint256 minOut, bytes calldata data) external view override returns (bool) {
    if (isPaused) return false;
    (uint256 slippageBps, ) = abi.decode(data, (uint256, address));
    bool isJpyToUsdc = (fromToken == jpyToken && toToken == usdc);
    bool isUsdcToJpy = (fromToken == usdc && toToken == jpyToken);
    if (!isJpyToUsdc && !isUsdcToJpy) return false;
    if (_isCircuitBreakerTriggered()) return false;
    uint256 twapPrice = twapOracle.getCurrentTwapPrice();
    uint256 expectedOut = _computeExpectedOutput(amountIn - feeAmount, fromToken, toToken, twapPrice);
    uint256 minAcceptable = (expectedOut * (MAX_BPS - slippageBps)) / MAX_BPS;
    return minOut >= minAcceptable;
  }

  function _computeExpectedOutput(uint256 amountIn, address fromToken, address toToken, uint256 twapPrice) internal view returns (uint256) {
    if (fromToken == jpyToken && toToken == usdc) {
      return (amountIn * 10**USDC_DECIMALS) / (twapPrice * 10**(JPY_DECIMALS - PRICE_DECIMALS));
    } else if (fromToken == usdc && toToken == jpyToken) {
      return amountIn * twapPrice * 10**(JPY_DECIMALS - USDC_DECIMALS - PRICE_DECIMALS);
    }
    return 0;
  }

  function _isCircuitBreakerTriggered() internal view returns (bool) {
    try twapOracle.isCircuitBreakerTriggered() returns (bool triggered) {
      if (triggered) return true;
    } catch {
      return true;
    }
    uint256 twap = twapOracle.getCurrentTwapPrice();
    uint256 spot = twapOracle.getSpotPrice();
    uint256 divergence = _calculateDivergence(twap, spot);
    return divergence > maxDivergence;
  }

  function _calculateDivergence(uint256 price1, uint256 price2) internal pure returns (uint256) {
    if (price1 == price2) return 0;
    uint256 diff = price1 > price2 ? price1 - price2 : price2 - price1;
    uint256 avg = (price1 + price2) / 2;
    return (diff * PRECISE_UNIT) / avg;
  }

  function setMaxDivergence(uint256 _newDivergence) external onlyOwner {
    if (_newDivergence == 0 || _newDivergence > PRECISE_UNIT) revert InvalidDivergence();
    maxDivergence = _newDivergence;
  }

  function setPaused(bool _isPaused) external onlyOwner {
    isPaused = _isPaused;
  }
}
