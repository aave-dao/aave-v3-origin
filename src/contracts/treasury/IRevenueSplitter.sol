// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';

interface IRevenueSplitterErrors {
  error InvalidPercentSplit();
}

/// @title IRevenueSplitter
/// @notice Interface for RevenueSplitter contract
/// @dev The `RevenueSplitter`  is a state-less non-upgradeable contract that supports 2 recipients (A and B), and defines the percentage split of the recipient A, with a value between 1 and 99_99.
/// The `RevenueSplitter` contract must be attached to the `AaveV3ConfigEngine` as `treasury`, making new listings to use `RevenueSplitter` as treasury (instead of `Collector` ) at the `AToken` initialization, making all revenue managed by ATokens redirected to the RevenueSplitter contract.
/// Once parties want to share their revenue, anyone can call `function splitRevenue(IERC20[] memory tokens)` to check the accrued ERC20 balance inside this contract, and split the amounts between the two recipients.
/// It also supports split of native currency via `function splitNativeRevenue() external`, in case the instance receives native currency.
///
/// Warning: For recipients, you can use any address, but preferable to use `Collector`, a Safe smart contract multisig or a smart contract that can handle both ERC20 and native transfers, to prevent balances to be locked.
interface IRevenueSplitter is IRevenueSplitterErrors {
  /// @notice Split token balances in RevenueSplitter and transfer between two recipients
  /// @param tokens List of tokens to check balance and split amounts
  /// @dev Specs:
  ///      - Does not revert if token balance is zero (no-op).
  ///      - Rounds in favor of RECIPIENT_B (1 wei round).
  ///      - Anyone can call this function anytime.
  ///      - This method will always send ERC20 tokens to recipients, even if the recipients does NOT support the ERC20 interface. At deployment time is recommended to ensure both recipients can handle ERC20 and native transfers via e2e tests.
  function splitRevenue(IERC20[] memory tokens) external;

  /// @notice Split native currency in RevenueSplitter and transfer between two recipients
  /// @dev Specs:
  ///      - Does not revert if native balance is zero (no-op)
  ///      - Rounds in favor of RECIPIENT_B (1 wei round).
  ///      - Anyone can call this function anytime.
  ///      - This method will always send native currency to recipients, and does NOT revert if one or both recipients doesn't support handling native currency. At deployment time is recommended to ensure both recipients can handle ERC20 and native transfers via e2e tests.
  ///      - If one recipient can not receive native currency, repeatedly calling the function will rescue/drain the funds of the second recipient (50% per call), allowing manual recovery of funds.
  function splitNativeRevenue() external;

  function RECIPIENT_A() external view returns (address payable);

  function RECIPIENT_B() external view returns (address payable);

  /// @dev Percentage of the split that goes to RECIPIENT_A, the diff goes to RECIPIENT_B, from 1 to 99_99
  function SPLIT_PERCENTAGE_RECIPIENT_A() external view returns (uint16);
}
