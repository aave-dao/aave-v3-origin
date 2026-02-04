// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IVerifierFeeManager} from './IVerifierFeeManager.sol';

/**
 * @title IVerifierProxy
 * @notice Interface for Chainlink Data Streams verifier proxy
 */
interface IVerifierProxy {
  function verify(
    bytes calldata payload,
    bytes calldata parameterPayload
  ) external payable returns (bytes memory verifierResponse);

  function s_feeManager() external view returns (IVerifierFeeManager);
}
