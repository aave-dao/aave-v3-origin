// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Contracts
import {MockAggregator} from 'src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';

contract MockAggregatorSetPrice is MockAggregator {
  constructor(int256 initialAnswer) MockAggregator(initialAnswer) {}
  function setLatestAnswer(int256 answer) external {
    _latestAnswer = answer;
    emit AnswerUpdated(answer, 0, block.timestamp);
  }
}
