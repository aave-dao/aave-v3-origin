// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IStaticATokenLM} from '../../src/periphery/contracts/static-a-token/interfaces/IStaticATokenLM.sol';

library SigUtils {
  struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
  }

  struct MetaWithdrawParams {
    address owner;
    address spender;
    uint256 staticAmount;
    uint256 dynamicAmount;
    bool toUnderlying;
    uint256 nonce;
    uint256 deadline;
  }

  struct MetaDepositParams {
    address depositor;
    address receiver;
    uint256 assets;
    uint16 referralCode;
    bool fromUnderlying;
    uint256 nonce;
    uint256 deadline;
    IStaticATokenLM.PermitParams permit;
  }

  // computes the hash of a permit
  function getStructHash(Permit memory _permit, bytes32 typehash) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          typehash,
          _permit.owner,
          _permit.spender,
          _permit.value,
          _permit.nonce,
          _permit.deadline
        )
      );
  }

  function getWithdrawHash(
    MetaWithdrawParams memory permit,
    bytes32 typehash
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          typehash,
          permit.owner,
          permit.spender,
          permit.staticAmount,
          permit.dynamicAmount,
          permit.toUnderlying,
          permit.nonce,
          permit.deadline
        )
      );
  }

  function getDepositHash(
    MetaDepositParams memory params,
    bytes32 typehash
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          typehash,
          params.depositor,
          params.receiver,
          params.assets,
          params.referralCode,
          params.fromUnderlying,
          params.nonce,
          params.deadline
        )
      );
  }

  // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
  function getTypedDataHash(
    Permit memory permit,
    bytes32 typehash,
    bytes32 domainSeparator
  ) public pure returns (bytes32) {
    return
      keccak256(abi.encodePacked('\x19\x01', domainSeparator, getStructHash(permit, typehash)));
  }

  function getTypedWithdrawHash(
    MetaWithdrawParams memory params,
    bytes32 typehash,
    bytes32 domainSeparator
  ) public pure returns (bytes32) {
    return
      keccak256(abi.encodePacked('\x19\x01', domainSeparator, getWithdrawHash(params, typehash)));
  }

  function getTypedDepositHash(
    MetaDepositParams memory params,
    bytes32 typehash,
    bytes32 domainSeparator
  ) public pure returns (bytes32) {
    return
      keccak256(abi.encodePacked('\x19\x01', domainSeparator, getDepositHash(params, typehash)));
  }
}
