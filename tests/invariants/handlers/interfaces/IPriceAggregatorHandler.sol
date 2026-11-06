// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPriceAggregatorHandler {
  function setLatestAnswer(int72 _price, uint8 i) external;
}
