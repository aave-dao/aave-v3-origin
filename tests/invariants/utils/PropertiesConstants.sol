// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract PropertiesConstants {
  // Constant echidna addresses
  address constant USER1 = address(0x10000);
  address constant USER2 = address(0x20000);
  address constant USER3 = address(0x30000);
  address constant UMBRELLA = address(0x400000);

  uint256 constant INITIAL_BALANCE = 10e38;
  uint256 internal constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 0.5e4;
  uint256 constant CLOSE_FACTOR_HF_THRESHOLD = 0.95e18;
  uint256 public constant MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD = 2000e8;
  uint256 public constant MIN_LEFTOVER_BASE = MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD / 2;
}
