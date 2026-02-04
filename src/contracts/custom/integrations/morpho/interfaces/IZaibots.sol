// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IZaibots {
  function supply(address asset, uint256 amount, address onBehalfOf) external returns (uint256 shares);
  function withdraw(address asset, uint256 amount, address to) external returns (uint256 withdrawn);
  function borrow(address asset, uint256 amount, address onBehalfOf) external;
  function repay(address asset, uint256 amount, address onBehalfOf) external returns (uint256 repaid);
  function getCollateralBalance(address user, address asset) external view returns (uint256 balance);
  function getDebtBalance(address user, address asset) external view returns (uint256 balance);
  function getLTV(address collateral, address debt) external view returns (uint256 ltv);
  function getBorrowRate(address asset) external view returns (uint256 rate);
  function getSupplyRate(address asset) external view returns (uint256 rate);
  function isLiquidatable(address user) external view returns (bool);
  function getHealthFactor(address user) external view returns (uint256 healthFactor);
  function getMaxBorrow(address user, address asset) external view returns (uint256 maxBorrow);
}
