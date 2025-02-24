// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPoolHandler {
  function mintToTreasury(uint8 i) external;
  function eliminateReserveDeficit(uint256 amount, uint8 i) external;
  function setUserEMode(uint8 i) external;
  function setPoolPause(bool paused, uint40 gracePeriod) external;
  function setReserveActive(bool active, uint8 i) external;
  function configureReserveAsCollateral(
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    uint8 i
  ) external;
}
