// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILiquidationHandler {
  function liquidationCall(
    uint256 debtToCover,
    bool receiveAToken,
    uint8 i,
    uint8 j,
    uint8 k,
    uint8 l
  ) external;
}
