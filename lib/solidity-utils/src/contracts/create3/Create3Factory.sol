// SPDX-License-Identifier: MIT
// Modified from https://github.com/lifinance/create3-factory/blob/main/src/CREATE3Factory.sol
pragma solidity ^0.8.0;

import {Create3} from './Create3.sol';
import {Ownable} from '../oz-common/Ownable.sol';
import {ICreate3Factory} from './interfaces/ICreate3Factory.sol';

/**
  * @title Factory for deploying contracts to deterministic addresses via Create3
  * @author BGD Labs
  * @notice Enables deploying contracts using CREATE3. Each deployer (msg.sender) has its own namespace for deployed addresses.
  */
contract Create3Factory is ICreate3Factory {
  /// @inheritdoc	ICreate3Factory
  function create(
    bytes32 salt,
    bytes memory creationCode
  ) external payable returns (address) {
    // hash salt with the deployer address to give each deployer its own namespace
    salt = keccak256(abi.encodePacked(msg.sender, salt));
    return Create3.create3(salt, creationCode, msg.value);
  }

  /// @inheritdoc	ICreate3Factory
  function predictAddress(
    address deployer,
    bytes32 salt
  ) external view returns (address) {
    // hash salt with the deployer address to give each deployer its own namespace
    salt = keccak256(abi.encodePacked(deployer, salt));
    return Create3.addressOf(salt);
  }
}
