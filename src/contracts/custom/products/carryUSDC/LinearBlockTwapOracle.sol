// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IChainlinkAggregatorV3} from '../../integrations/morpho/interfaces/IChainlinkAutomation.sol';

interface ILinearBlockTwapOracle {
  function getCurrentTwapPrice() external view returns (uint256);
  function getSpotPrice() external view returns (uint256);
  function twapPrice() external view returns (uint256);
  function accrualRatePerBlock() external view returns (uint256);
  function lastUpdateBlock() external view returns (uint256);
  function circuitBreakerThreshold() external view returns (uint256);
  function isCircuitBreakerTriggered() external view returns (bool);
}

/**
 * @title LinearBlockTwapOracle
 * @notice Linear per-block TWAP oracle for JPY/USD pricing
 */
contract LinearBlockTwapOracle is ILinearBlockTwapOracle, Ownable {
  IChainlinkAggregatorV3 public immutable chainlinkFeed;
  uint256 public twapPrice;
  uint256 public lastUpdateBlock;
  uint256 public accrualRatePerBlock;
  uint256 public maxAccrualRate;
  uint256 public circuitBreakerThreshold;
  uint256 public maxStaleness;

  uint256 public constant PRECISE_UNIT = 1e18;
  uint256 public constant DEFAULT_ACCRUAL_RATE = 5e14;
  uint256 public constant DEFAULT_MAX_RATE = 1e16;
  uint256 public constant DEFAULT_CIRCUIT_BREAKER = 1e16;
  uint256 public constant DEFAULT_STALENESS = 7200;

  event TwapUpdated(uint256 oldTwap, uint256 newTwap, uint256 spotPrice, uint256 blocksElapsed);
  event CircuitBreakerTriggered(uint256 twap, uint256 spot, uint256 divergence);

  error InvalidAddress();
  error InvalidAccrualRate();
  error InvalidThreshold();
  error StaleChainlinkPrice();
  error InvalidChainlinkPrice();
  error CircuitBreakerActive();

  constructor(address _chainlinkFeed) Ownable(msg.sender) {
    if (_chainlinkFeed == address(0)) revert InvalidAddress();
    chainlinkFeed = IChainlinkAggregatorV3(_chainlinkFeed);
    accrualRatePerBlock = DEFAULT_ACCRUAL_RATE;
    maxAccrualRate = DEFAULT_MAX_RATE;
    circuitBreakerThreshold = DEFAULT_CIRCUIT_BREAKER;
    maxStaleness = DEFAULT_STALENESS;
    (, int256 price, , , ) = chainlinkFeed.latestRoundData();
    if (price <= 0) revert InvalidChainlinkPrice();
    twapPrice = uint256(price);
    lastUpdateBlock = block.number;
  }

  function getCurrentTwapPrice() external view override returns (uint256) {
    uint256 spot = getSpotPrice();
    uint256 blocksElapsed = block.number - lastUpdateBlock;
    if (blocksElapsed == 0) return twapPrice;
    uint256 maxDelta = (twapPrice * accrualRatePerBlock * blocksElapsed) / PRECISE_UNIT;
    if (twapPrice > spot) {
      uint256 delta = twapPrice - spot;
      uint256 adjustment = delta < maxDelta ? delta : maxDelta;
      return twapPrice - adjustment;
    } else {
      uint256 delta = spot - twapPrice;
      uint256 adjustment = delta < maxDelta ? delta : maxDelta;
      return twapPrice + adjustment;
    }
  }

  function getSpotPrice() public view override returns (uint256) {
    (, int256 price, , uint256 updatedAt, ) = chainlinkFeed.latestRoundData();
    if (block.timestamp - updatedAt > maxStaleness) revert StaleChainlinkPrice();
    if (price <= 0) revert InvalidChainlinkPrice();
    return uint256(price);
  }

  function isCircuitBreakerTriggered() external view override returns (bool) {
    uint256 spot = getSpotPrice();
    uint256 currentTwap = this.getCurrentTwapPrice();
    uint256 divergence = _calculateDivergence(currentTwap, spot);
    return divergence > circuitBreakerThreshold;
  }

  function updateTwap() external {
    uint256 spot = getSpotPrice();
    uint256 currentTwap = this.getCurrentTwapPrice();
    uint256 divergence = _calculateDivergence(currentTwap, spot);
    if (divergence > circuitBreakerThreshold) {
      emit CircuitBreakerTriggered(currentTwap, spot, divergence);
      revert CircuitBreakerActive();
    }
    uint256 blocksElapsed = block.number - lastUpdateBlock;
    uint256 oldTwap = twapPrice;
    twapPrice = currentTwap;
    lastUpdateBlock = block.number;
    emit TwapUpdated(oldTwap, currentTwap, spot, blocksElapsed);
  }

  function resetToSpot() external onlyOwner {
    uint256 spot = getSpotPrice();
    uint256 oldTwap = twapPrice;
    twapPrice = spot;
    lastUpdateBlock = block.number;
    emit TwapUpdated(oldTwap, spot, spot, 0);
  }

  function setAccrualRatePerBlock(uint256 _newRate) external onlyOwner {
    if (_newRate == 0 || _newRate > maxAccrualRate) revert InvalidAccrualRate();
    accrualRatePerBlock = _newRate;
  }

  function setCircuitBreakerThreshold(uint256 _newThreshold) external onlyOwner {
    if (_newThreshold == 0) revert InvalidThreshold();
    circuitBreakerThreshold = _newThreshold;
  }

  function _calculateDivergence(uint256 _price1, uint256 _price2) internal pure returns (uint256) {
    if (_price1 == _price2) return 0;
    uint256 diff = _price1 > _price2 ? _price1 - _price2 : _price2 - _price1;
    uint256 avg = (_price1 + _price2) / 2;
    return (diff * PRECISE_UNIT) / avg;
  }
}
