// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @dev Mock aggregator with 18 decimals (instead of 8) for testing purposes
 * Used to test that PriceFeedEngine properly validates price feed decimals
 * @author BGD Labs
 */
contract MockAggregator18Decimals {
  int256 public _latestAnswer;

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  constructor(int256 initialAnswer) {
    _latestAnswer = initialAnswer;
    emit AnswerUpdated(initialAnswer, 0, block.timestamp);
  }

  function latestAnswer() external view returns (int256) {
    return _latestAnswer;
  }

  function getTokenType() external pure returns (uint256) {
    return 1;
  }

  function decimals() external pure returns (uint8) {
    return 18; // Returns 18 instead of 8 to trigger validation error
  }
}
