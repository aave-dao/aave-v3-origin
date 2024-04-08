// SPDX-License-Identifier: AGPL-3.0
// Modified from https://github.com/lifinance/create3-factory/blob/main/src/ICREATE3Factory.sol
pragma solidity >=0.6.0;

/**
 * @title Factory for deploying contracts to deterministic addresses via Create3
 * @author BGD Labs
 * @notice Defines the methods implemented on Create3Factory contract
 */
interface ICreate3Factory {
  /**
   * @notice Deploys a contract using Create3
   * @dev The provided salt is hashed together with msg.sender to generate the final salt
   * @param salt The deployer-specific salt for determining the deployed contract's address
   * @param creationCode The creation code of the contract to deploy
   * @return The address of the deployed contract
   */
  function create(
    bytes32 salt,
    bytes memory creationCode
  ) external payable returns (address);

  /**
   * @notice Predicts the address of a deployed contract
   * @dev The provided salt is hashed together with the deployer address to generate the final salt
   * @param deployer The deployer account that will call deploy()
   * @param salt The deployer-specific salt for determining the deployed contract's address
   * @return The address of the contract that will be deployed
   */
  function predictAddress(
    address deployer,
    bytes32 salt
  ) external view returns (address);
}
